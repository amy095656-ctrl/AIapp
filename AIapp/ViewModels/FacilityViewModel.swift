import Foundation
import CoreLocation
import SwiftUI
import MapKit
import Combine

/// 地圖聚類資料結構
struct FacilityCluster: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let facilities: [Facility]

    var count: Int { facilities.count }
    var isSingle: Bool { facilities.count == 1 }
    var firstFacility: Facility { facilities[0] }

    var formattedCount: String {
        if count >= 1000 {
            return "\(count / 1000)k+"
        }
        return "\(count)"
    }

    var dominantType: FacilityType {
        var toilets = 0
        var waters = 0
        var boths = 0
        for f in facilities {
            switch f.type {
            case .toilet: toilets += 1
            case .waterDispenser: waters += 1
            case .both: boths += 1
            }
        }
        if boths >= toilets && boths >= waters { return .both }
        if toilets >= waters { return .toilet }
        return .waterDispenser
    }
}

@MainActor
final class FacilityViewModel: ObservableObject {
    @Published var facilities: [Facility] = [] {
        didSet {
            updateCityCounts()
            updateFilteredFacilities()
        }
    }
    @Published var filteredFacilities: [Facility] = []
    @Published var cityCounts: [TaiwanCity: Int] = [:]
    @Published var selectedFacility: Facility? = nil
    @Published var searchText: String = "" {
        didSet {
            updateFilteredFacilities()
        }
    }
    @Published var filterOptions: FilterOptions = FilterOptions() {
        didSet {
            updateFilteredFacilities()
        }
    }
    @Published var isFilterSheetPresented: Bool = false

    // 地圖區域中心控制與聚類 (Clustering)
    var currentCenterCoordinate: CLLocationCoordinate2D = LocationManager.defaultCoordinate
    @Published var currentSpanDelta: Double = 0.02
    @Published var clusters: [FacilityCluster] = []

    /// 當地圖拉遠時 (跨度大於 0.035 度)，判斷為拉遠狀態，用以隱藏懸浮文字卡片
    var isZoomedOut: Bool {
        currentSpanDelta > 0.035
    }

    @Published var mapCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: LocationManager.defaultCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )

    // 社群問題回報紀錄
    @Published var reportedIssues: [FacilityReport] = []

    let locationManager: LocationManager
    private let dataService: FacilityDataService
    private var cancellables = Set<AnyCancellable>()

    init(locationManager: LocationManager? = nil, dataService: FacilityDataService = FacilityDataService.shared) {
        let lm = locationManager ?? LocationManager()
        self.locationManager = lm
        self.dataService = dataService

        // 監聽定位更新（加入 300ms 節流防抖，避免連續觸發主執行緒計算）
        lm.$userLocation
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFilteredFacilities()
            }
            .store(in: &cancellables)

        loadData()
    }

    func loadData() {
        // 1. 先載入種子資料，讓視圖在數毫秒內完成初次渲染，防止預覽超時
        let seed = dataService.curatedSeedFacilities()
        self.facilities = seed
        self.reportedIssues = dataService.getSavedReports()
        self.applyReportedIssues()
        self.updateFilteredFacilities()

        // 2. 背景非同步載入全台完整 3,949 處圖資，載入完成後平滑更新
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let fullList = self.dataService.loadInitialFacilities()
            DispatchQueue.main.async {
                if !fullList.isEmpty {
                    self.facilities = fullList
                    self.applyReportedIssues()
                    self.updateFilteredFacilities()
                }
            }
        }
    }

    private func applyReportedIssues() {
        for report in reportedIssues {
            if let index = facilities.firstIndex(where: { $0.id == report.facilityId }) {
                facilities[index].activeIssueAlert = "⚠️ 社群回報：\(report.issueType.rawValue)"
                if report.issueType == .outOfService {
                    facilities[index].isOpenNow = false
                } else if report.issueType == .noToiletPaper {
                    facilities[index].hasToiletPaper = false
                } else if report.issueType == .waterIssue {
                    facilities[index].hasHotWater = false
                }
            }
        }
    }

    /// 高效快取計算過濾與排序（毫秒級完成，無多重三角函數與堆疊物件開銷）
    func updateFilteredFacilities() {
        let userCoord = locationManager.userLocation ?? LocationManager.defaultCoordinate
        let userLat = userCoord.latitude
        let userLon = userCoord.longitude
        let cosLat = cos(userLat * .pi / 180.0)

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let qAlt1 = q.replacingOccurrences(of: "台", with: "臺")
        let qAlt2 = q.replacingOccurrences(of: "臺", with: "台")
        let hasQuery = !q.isEmpty

        let filtered = facilities.filter { item in
            // 1. 搜尋文字過濾
            if hasQuery {
                let nameLower = item.name.lowercased()
                let addrLower = item.address.lowercased()
                let matchName = nameLower.contains(q) || nameLower.contains(qAlt1) || nameLower.contains(qAlt2)
                let matchAddr = addrLower.contains(q) || addrLower.contains(qAlt1) || addrLower.contains(qAlt2)
                let matchFloor = item.floorDescription.lowercased().contains(q)
                let matchCategory = item.category.rawValue.lowercased().contains(q)
                if !(matchName || matchAddr || matchFloor || matchCategory) {
                    return false
                }
            }

            // 2. 主類型過濾
            switch filterOptions.typeFilter {
            case .all:
                break
            case .toiletOnly:
                if item.type != .toilet && item.type != .both {
                    return false
                }
            case .waterOnly:
                if item.type != .waterDispenser && item.type != .both {
                    return false
                }
            }

            // 3. 篩選方式二選一：場所類型 vs 所在城市
            switch filterOptions.locationFilterMode {
            case .byCategory:
                if let cat = filterOptions.selectedCategory, item.category != cat {
                    return false
                }
            case .byCity:
                if let city = filterOptions.selectedCity {
                    let kw = city.keyword
                    let kwAlt = kw.replacingOccurrences(of: "台", with: "臺")
                    if !(item.address.contains(kw) || item.address.contains(kwAlt)) {
                        return false
                    }
                }
            }

            // 4. 距離限制過濾（快速平面近似，防止堆疊大量 CLLocation 物件）
            if filterOptions.distanceLimit != .unlimited {
                let dLat = (item.latitude - userLat) * 111000.0
                let dLon = (item.longitude - userLon) * (111000.0 * cosLat)
                let distMeters = sqrt(dLat * dLat + dLon * dLon)
                if distMeters > filterOptions.distanceLimit.rawValue {
                    return false
                }
            }

            // 5. 廁所特徵需求過濾
            if filterOptions.requireAccessible && !item.hasAccessibleToilet {
                return false
            }
            if filterOptions.requireNursery && !item.hasNurseryOrDiaper {
                return false
            }
            if filterOptions.requireGenderFriendly && !item.isGenderFriendly {
                return false
            }
            if filterOptions.requireBidet && !item.hasBidet {
                return false
            }
            if filterOptions.requireToiletPaper && !item.hasToiletPaper {
                return false
            }

            // 6. 飲水機特徵需求過濾
            if filterOptions.requireHotWater && !item.hasHotWater {
                return false
            }
            if filterOptions.requireWarmWater && !item.hasWarmWater {
                return false
            }
            if filterOptions.requireColdWater && !item.hasColdWater {
                return false
            }
            if filterOptions.requireCupFriendly && !item.isCupFriendly {
                return false
            }

            return true
        }

        // 高效極速距離平方排序（O(N log N) 僅執行數次加法與乘法，0.2 毫秒完成）
        self.filteredFacilities = filtered.sorted { (f1, f2) -> Bool in
            let dLat1 = f1.latitude - userLat
            let dLon1 = (f1.longitude - userLon) * cosLat
            let distSq1 = dLat1 * dLat1 + dLon1 * dLon1

            let dLat2 = f2.latitude - userLat
            let dLon2 = (f2.longitude - userLon) * cosLat
            let distSq2 = dLat2 * dLat2 + dLon2 * dLon2

            return distSq1 < distSq2
        }

        // 若當前選取的設施已不符合新篩選條件，重設為 nil
        if let current = selectedFacility, !filtered.contains(where: { $0.id == current.id }) {
            self.selectedFacility = nil
        }

        // 即時計算聚類群組
        self.computeClusters()
    }

    /// 套用進階篩選並自動將地圖視野移至符合條件的區域，且底部卡片自動呈現最近的設施
    func applyFilterAndFocus() {
        updateFilteredFacilities()

        // 重設選取狀態，使底層卡片依照使用者定位呈現最近之篩選設施
        selectedFacility = nil

        if let city = filterOptions.selectedCity {
            // 若有選取特定縣市，飛往該縣市
            moveToCity(city)
        } else if let nearest = filteredFacilities.first {
            // 若未指定特定縣市，平滑移動地圖中心至使用者定位（若無則至最近設施），縮放至街道尺度
            let targetCoord = locationManager.userLocation ?? nearest.coordinate
            currentCenterCoordinate = targetCoord
            currentSpanDelta = 0.02
            computeClusters()
            withAnimation(.easeInOut(duration: 0.5)) {
                mapCameraPosition = .region(
                    MKCoordinateRegion(
                        center: targetCoord,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                )
            }
        } else {
            // 若完全無符合條件結果，展示全台灣全貌
            showAllTaiwan()
        }
    }

    /// 依據當前地圖縮放級別動態計算聚類 (Dynamic Grid Clustering)
    func computeClusters() {
        let items = filteredFacilities
        if items.isEmpty {
            self.clusters = []
            return
        }

        // 縮放極近時 (小於 0.008 度，約 800 公尺街道等級)，不進行聚類，全量呈現獨立圖標
        if currentSpanDelta <= 0.008 {
            self.clusters = items.map {
                FacilityCluster(id: $0.id.uuidString, coordinate: $0.coordinate, facilities: [$0])
            }
            return
        }

        // 根據縮放級別決定網格跨度 (Grid Cell Size)
        let gridSize: Double
        if currentSpanDelta > 2.0 {
            gridSize = 0.45          // 全台灣鳥瞰視角：以區域/大縣市為單位
        } else if currentSpanDelta > 0.8 {
            gridSize = 0.22          // 北中南生活圈視角
        } else if currentSpanDelta > 0.3 {
            gridSize = 0.08          // 縣市/大都會層級視角
        } else if currentSpanDelta > 0.1 {
            gridSize = 0.035         // 行政區/市鎮層級視角
        } else if currentSpanDelta > 0.035 {
            gridSize = 0.015         // 街道/商圈視角
        } else {
            gridSize = 0.005         // 街區視角，僅聚合同建築/車站內據點
        }

        // 網格聚合計算 (O(N))
        var gridBuckets: [String: [Facility]] = [:]
        gridBuckets.reserveCapacity(items.count / 2)

        for item in items {
            let latIndex = Int(floor(item.latitude / gridSize))
            let lonIndex = Int(floor(item.longitude / gridSize))
            let key = "\(latIndex)_\(lonIndex)"
            gridBuckets[key, default: []].append(item)
        }

        var result: [FacilityCluster] = []
        result.reserveCapacity(gridBuckets.count)

        for (key, group) in gridBuckets {
            if group.count == 1 {
                let single = group[0]
                result.append(FacilityCluster(id: single.id.uuidString, coordinate: single.coordinate, facilities: group))
            } else {
                // 計算群組中心座標
                var sumLat: Double = 0
                var sumLon: Double = 0
                for f in group {
                    sumLat += f.latitude
                    sumLon += f.longitude
                }
                let countDouble = Double(group.count)
                let center = CLLocationCoordinate2D(latitude: sumLat / countDouble, longitude: sumLon / countDouble)
                result.append(FacilityCluster(id: "cluster_\(key)_\(group.count)", coordinate: center, facilities: group))
            }
        }

        self.clusters = result
    }

    /// 監聽地圖鏡頭縮放變化，動態更新聚類群組
    func updateCameraRegion(_ region: MKCoordinateRegion) {
        currentCenterCoordinate = region.center
        let oldSpan = currentSpanDelta
        currentSpanDelta = region.span.latitudeDelta

        // 當縮放跨度變化超過 20% 時重新計算聚類，確保地圖平移時效能極速
        if abs(currentSpanDelta - oldSpan) / max(0.001, oldSpan) > 0.20 {
            computeClusters()
        }
    }

    /// 點擊聚類標記時平滑放大並聚焦該聚類區域
    func zoomIntoCluster(_ cluster: FacilityCluster) {
        selectedFacility = nil
        let newSpan = max(0.006, currentSpanDelta * 0.4)
        currentCenterCoordinate = cluster.coordinate
        currentSpanDelta = newSpan
        computeClusters()
        withAnimation(.easeInOut(duration: 0.35)) {
            mapCameraPosition = .region(
                MKCoordinateRegion(
                    center: cluster.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: newSpan, longitudeDelta: newSpan)
                )
            )
        }
    }

    /// 收藏的清單
    var favoriteFacilities: [Facility] {
        return facilities.filter { $0.isFavorite }
    }

    /// 切換收藏狀態
    func toggleFavorite(facility: Facility) {
        if let index = facilities.firstIndex(where: { $0.id == facility.id }) {
            facilities[index].isFavorite.toggle()
            dataService.saveFavorite(id: facility.id, isFavorite: facilities[index].isFavorite)

            if selectedFacility?.id == facility.id {
                selectedFacility?.isFavorite = facilities[index].isFavorite
            }
        }
    }

    /// 放大地圖視角
    func zoomIn() {
        currentSpanDelta = max(0.002, currentSpanDelta * 0.5)
        computeClusters()
        withAnimation(.easeInOut(duration: 0.25)) {
            mapCameraPosition = .region(
                MKCoordinateRegion(
                    center: currentCenterCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: currentSpanDelta, longitudeDelta: currentSpanDelta)
                )
            )
        }
    }

    /// 縮小地圖視角
    func zoomOut() {
        currentSpanDelta = min(4.5, currentSpanDelta * 2.0)
        computeClusters()
        withAnimation(.easeInOut(duration: 0.25)) {
            mapCameraPosition = .region(
                MKCoordinateRegion(
                    center: currentCenterCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: currentSpanDelta, longitudeDelta: currentSpanDelta)
                )
            )
        }
    }

    /// 將地圖鏡頭移動到指定設施
    func focusOn(facility: Facility) {
        selectedFacility = facility
        currentCenterCoordinate = facility.coordinate
        currentSpanDelta = 0.008
        computeClusters()
        withAnimation(.easeInOut) {
            mapCameraPosition = .region(
                MKCoordinateRegion(
                    center: facility.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                )
            )
        }
    }

    /// 將地圖鏡頭定位回使用者所在位置
    func centerOnUserLocation() {
        if let userCoord = locationManager.userLocation {
            currentCenterCoordinate = userCoord
            currentSpanDelta = 0.012
            computeClusters()
            withAnimation(.easeInOut) {
                mapCameraPosition = .region(
                    MKCoordinateRegion(
                        center: userCoord,
                        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                    )
                )
            }
        } else {
            locationManager.startUpdatingLocation()
        }
    }

    /// 將地圖鏡頭平滑移動到指定縣市中心
    func moveToCity(_ city: TaiwanCity) {
        currentCenterCoordinate = city.centerCoordinate
        currentSpanDelta = city.spanDelta
        computeClusters()
        withAnimation(.easeInOut(duration: 0.5)) {
            mapCameraPosition = .region(
                MKCoordinateRegion(
                    center: city.centerCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: city.spanDelta, longitudeDelta: city.spanDelta)
                )
            )
        }
    }

    /// 縮放至全台灣完整鳥瞰視野
    func showAllTaiwan() {
        let center = CLLocationCoordinate2D(latitude: 23.8, longitude: 121.0)
        currentCenterCoordinate = center
        currentSpanDelta = 4.2
        computeClusters()
        withAnimation(.easeInOut(duration: 0.5)) {
            mapCameraPosition = .region(
                MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 4.2, longitudeDelta: 4.2)
                )
            )
        }
    }

    /// 快速計算各縣市據點總數快取
    private func updateCityCounts() {
        var counts: [TaiwanCity: Int] = [:]
        for city in TaiwanCity.allCases {
            let kw = city.keyword
            let kwAlt = kw.replacingOccurrences(of: "台", with: "臺")
            let count = facilities.filter { $0.address.contains(kw) || $0.address.contains(kwAlt) }.count
            counts[city] = count
        }
        self.cityCounts = counts
    }

    // MARK: - 社群回報功能整合 (Reporting Issue)

    /// 提交設施問題回報，並即時更新該設施的狀態
    func submitReport(
        facility: Facility,
        issueType: IssueType,
        severity: IssueSeverity,
        rating: Int,
        comment: String,
        hasPhoto: Bool
    ) {
        let newReport = FacilityReport(
            facilityId: facility.id,
            facilityName: facility.name,
            issueType: issueType,
            severity: severity,
            rating: rating,
            comment: comment,
            hasPhotoAttached: hasPhoto
        )

        // 儲存至本機持久化
        dataService.saveReport(newReport)
        reportedIssues.insert(newReport, at: 0)

        // 即時反映至該設施屬性
        if let idx = facilities.firstIndex(where: { $0.id == facility.id }) {
            facilities[idx].activeIssueAlert = "⚠️ 社群回報：\(issueType.rawValue)"
            facilities[idx].maintenanceStatusNote = "⚠️ 使用者回報：\(issueType.rawValue)（\(comment.isEmpty ? "處理中" : comment)）"

            if issueType == .outOfService {
                facilities[idx].isOpenNow = false
            } else if issueType == .noToiletPaper {
                facilities[idx].hasToiletPaper = false
            } else if issueType == .waterIssue {
                facilities[idx].hasHotWater = false
            }

            if selectedFacility?.id == facility.id {
                selectedFacility = facilities[idx]
            }
        }
    }

    /// 解除問題回報（例如衛生紙已補充、已修復恢復使用）
    func resolveReport(facilityId: UUID) {
        if let idx = facilities.firstIndex(where: { $0.id == facilityId }) {
            facilities[idx].activeIssueAlert = nil
            facilities[idx].maintenanceStatusNote = "清潔維護巡檢完成，各項功能正常開放。"
            facilities[idx].isOpenNow = true
            facilities[idx].hasToiletPaper = true
            facilities[idx].hasHotWater = true

            if selectedFacility?.id == facilityId {
                selectedFacility = facilities[idx]
            }
        }
    }

    /// 回報並新增新設施（社群提報，包含各項飲水機與廁所配備特徵）
    func reportNewFacility(
        name: String,
        address: String,
        type: FacilityType,
        category: LocationCategory,
        note: String,
        hasAccessibleToilet: Bool = false,
        hasNurseryOrDiaper: Bool = false,
        isGenderFriendly: Bool = false,
        hasBidet: Bool = false,
        hasToiletPaper: Bool = true,
        hasHotWater: Bool = true,
        hasWarmWater: Bool = true,
        hasColdWater: Bool = true,
        isCupFriendly: Bool = true,
        isFilterCertified: Bool = true
    ) {
        let center = locationManager.userLocation ?? LocationManager.defaultCoordinate
        let newFacility = Facility(
            name: name,
            type: type,
            category: category,
            latitude: center.latitude + Double.random(in: -0.001...0.001),
            longitude: center.longitude + Double.random(in: -0.001...0.001),
            address: address,
            floorDescription: note,
            openingHours: "依現場公告",
            isOpenNow: true,
            rating: 5.0,
            reviewCount: 1,
            isFavorite: false,
            hasAccessibleToilet: hasAccessibleToilet,
            hasNurseryOrDiaper: hasNurseryOrDiaper,
            isGenderFriendly: isGenderFriendly,
            hasBidet: hasBidet,
            hasToiletPaper: hasToiletPaper,
            isFree: true,
            hasHotWater: hasHotWater,
            hasWarmWater: hasWarmWater,
            hasColdWater: hasColdWater,
            isCupFriendly: isCupFriendly,
            isFilterCertified: isFilterCertified,
            maintenanceStatusNote: "使用者新增提報據點，已同步上架"
        )
        facilities.insert(newFacility, at: 0)
        focusOn(facility: newFacility)
    }

    // MARK: - 導航跳轉 (Apple Maps & Google Maps)

    func openInAppleMaps(facility: Facility) {
        let placemark = MKPlacemark(coordinate: facility.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = facility.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }

    func openInGoogleMaps(facility: Facility) {
        let urlString = "comgooglemaps://?daddr=\(facility.latitude),\(facility.longitude)&directionsmode=walking"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback 到瀏覽器 Google Maps
            let webString = "https://www.google.com/maps/dir/?api=1&destination=\(facility.latitude),\(facility.longitude)&travelmode=walking"
            if let webURL = URL(string: webString) {
                UIApplication.shared.open(webURL)
            }
        }
    }
}
