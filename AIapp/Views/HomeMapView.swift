import SwiftUI
import MapKit

struct HomeMapView: View {
    @ObservedObject var viewModel: FacilityViewModel
    @State private var detailFacility: Facility? = nil
    @State private var isShowingSearchSuggestions: Bool = false
    @FocusState private var isSearchFieldFocused: Bool

    /// 當前底部展示之設施：若使用者有選取特定 Pin 則展示該設施；若尚未選取特定 Pin 則預設依照使用者定位展示最近之篩選設施
    private var currentDisplayFacility: Facility? {
        viewModel.selectedFacility ?? viewModel.filteredFacilities.first
    }

    var body: some View {
        ZStack(alignment: .top) {
            // 1. 底層 Apple MapKit 地圖視圖 (支援動態地標聚類 Clustering)
            Map(position: $viewModel.mapCameraPosition) {
                // 用戶目前位置標註
                UserAnnotation()

                // 各設施地圖標記：支援聚類機制 (點擊聚類平滑放大，單一據點則呈現獨立圖標)
                ForEach(viewModel.clusters) { cluster in
                    Annotation("", coordinate: cluster.coordinate) {
                        if cluster.isSingle {
                            FacilityMapPin(
                                facility: cluster.firstFacility,
                                isSelected: viewModel.selectedFacility?.id == cluster.firstFacility.id,
                                isZoomedOut: viewModel.isZoomedOut,
                                activeFilter: viewModel.filterOptions.typeFilter
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    viewModel.selectedFacility = cluster.firstFacility
                                }
                            }
                        } else {
                            ClusterMapPin(
                                cluster: cluster,
                                activeFilter: viewModel.filterOptions.typeFilter
                            ) {
                                viewModel.zoomIntoCluster(cluster)
                            }
                        }
                    }
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                viewModel.updateCameraRegion(context.region)
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .edgesIgnoringSafeArea(.top)
            .onTapGesture {
                // 點擊地圖空白處收合鍵盤與建議面板及預覽卡片
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                withAnimation {
                    isShowingSearchSuggestions = false
                    viewModel.selectedFacility = nil
                }
            }

            // 2. 頂部浮動主搜尋列、分類膠囊與縣市快速切換列
            VStack(spacing: 8) {
                // 2.1 頂部地圖主搜尋列 (可直接打字搜尋或點擊使用篩選器)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 15, weight: .semibold))

                    TextField("搜尋地點、站名、路名、縣市...", text: $viewModel.searchText)
                        .font(.system(size: 14))
                        .autocorrectionDisabled()
                        .focused($isSearchFieldFocused)
                        .onChange(of: viewModel.searchText) { _, newText in
                            if !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    isShowingSearchSuggestions = true
                                }
                            } else {
                                withAnimation {
                                    isShowingSearchSuggestions = false
                                }
                            }
                        }
                        .onChange(of: isSearchFieldFocused) { _, isFocused in
                            if isFocused && !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    isShowingSearchSuggestions = true
                                }
                            }
                        }

                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                            withAnimation {
                                isShowingSearchSuggestions = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 15))
                        }
                    }

                    Divider()
                        .frame(height: 18)
                        .padding(.horizontal, 2)

                    // 篩選器按鈕 (可直接點選展開進階篩選條件)
                    Button(action: {
                        viewModel.isFilterSheetPresented = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(viewModel.filterOptions.activeFilterCount > 0 ? .teal : .primary)
                                .frame(width: 32, height: 32)

                            if viewModel.filterOptions.activeFilterCount > 0 {
                                Text("\(viewModel.filterOptions.activeFilterCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(3)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.12), radius: 8, y: 3)
                .padding(.horizontal, 16)

                // 2.15 搜尋關鍵字相似搜尋結果卡片面板 (當輸入關鍵字時即時挑出相似據點)
                if isShowingSearchSuggestions && !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    searchSuggestionsDropdown
                }

                // 2.2 頂部最核心「廁所 / 飲水機」開關 (純核心開關，縣市已收納至進階篩選)
                HStack(spacing: 3) {
                    MapFilterTabButton(
                        title: "全部",
                        icon: "square.grid.2x2.fill",
                        isSelected: viewModel.filterOptions.typeFilter == .all,
                        color: .indigo
                    ) {
                        viewModel.filterOptions.typeFilter = .all
                    }

                    MapFilterTabButton(
                        title: "廁所",
                        icon: "toilet.fill",
                        isSelected: viewModel.filterOptions.typeFilter == .toiletOnly,
                        color: .teal
                    ) {
                        viewModel.filterOptions.typeFilter = .toiletOnly
                    }

                    MapFilterTabButton(
                        title: "飲水機",
                        icon: "drop.fill",
                        isSelected: viewModel.filterOptions.typeFilter == .waterOnly,
                        color: .blue
                    ) {
                        viewModel.filterOptions.typeFilter = .waterOnly
                    }
                }
                .padding(3)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
            }
            .padding(.top, 8)

            // 2.5 右側浮動地圖控制器 (放大、縮小、我的定位)
            VStack {
                Spacer()

                VStack(spacing: 0) {
                    Button(action: { viewModel.zoomIn() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                    }

                    Divider()
                        .frame(width: 30)

                    Button(action: { viewModel.zoomOut() }) {
                        Image(systemName: "minus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                    }

                    Divider()
                        .frame(width: 30)

                    Button(action: { viewModel.centerOnUserLocation() }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.15), radius: 8, y: 3)
                .padding(.trailing, 16)
                .padding(.bottom, currentDisplayFacility != nil ? 225 : 80)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentDisplayFacility != nil)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            // 3. 底部浮動設施資訊卡片 (依使用者定位優先顯示最近設施；若有選取特定地標則切換至該地標)
            VStack {
                Spacer()

                if let facility = currentDisplayFacility {
                    VStack(spacing: 6) {
                        // 頂部狀態列
                        HStack(spacing: 6) {
                            if viewModel.selectedFacility == nil {
                                HStack(spacing: 5) {
                                    Image(systemName: "location.fill")
                                        .font(.caption2.bold())
                                        .foregroundColor(.teal)
                                    Text("離你最近的便民設施 (符合 \(viewModel.filteredFacilities.count) 處)")
                                        .font(.caption2.bold())
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button(action: {
                                    viewModel.focusOn(facility: facility)
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "scope")
                                            .font(.caption2)
                                        Text("地圖聚焦")
                                            .font(.caption2.bold())
                                    }
                                    .foregroundColor(.teal)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.teal.opacity(0.12))
                                    .cornerRadius(8)
                                }
                            } else {
                                HStack(spacing: 5) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption2.bold())
                                        .foregroundColor(.teal)
                                    Text("已選取地標設施")
                                        .font(.caption2.bold())
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        viewModel.selectedFacility = nil
                                    }
                                }) {
                                    HStack(spacing: 3) {
                                        Text("切換回最近設施")
                                            .font(.caption2.bold())
                                        Image(systemName: "arrow.uturn.backward")
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.teal)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.teal.opacity(0.12))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 6)

                        FacilityCardView(
                            facility: facility,
                            userLocation: viewModel.locationManager.userLocation,
                            activeFilter: viewModel.filterOptions.typeFilter,
                            onNavigate: {
                                viewModel.openInAppleMaps(facility: facility)
                            },
                            onShowDetail: {
                                detailFacility = facility
                            },
                            onToggleFavorite: {
                                viewModel.toggleFavorite(facility: facility)
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // 若無任何符合篩選之設施
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.magnifyingglass")
                            .foregroundColor(.secondary)
                        Text("無符合篩選條件的設施，請嘗試放寬篩選")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $viewModel.isFilterSheetPresented, onDismiss: {
            viewModel.applyFilterAndFocus()
        }) {
            FilterSheetView(viewModel: viewModel)
        }
        .sheet(item: $detailFacility) { facility in
            NavigationStack {
                FacilityDetailView(viewModel: viewModel, facility: facility)
            }
        }
    }

    // MARK: - 相似搜尋結果下拉面板
    private var searchSuggestionsDropdown: some View {
        VStack(spacing: 0) {
            // 面板頂部資訊列
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .foregroundColor(.teal)
                        .font(.caption.bold())
                    Text("相似搜尋結果 (\(viewModel.filteredFacilities.count))")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingSearchSuggestions = false
                    }
                }) {
                    HStack(spacing: 3) {
                        Text("收合")
                            .font(.caption2.bold())
                        Image(systemName: "chevron.up")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground).opacity(0.6))

            Divider()

            if viewModel.filteredFacilities.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.secondary)
                    Text("找不到與「\(viewModel.searchText)」相符的設施據點")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.filteredFacilities.prefix(12))) { facility in
                            Button(action: {
                                selectSuggestion(facility: facility)
                            }) {
                                HStack(spacing: 12) {
                                    // 類型圓圈
                                    ZStack {
                                        Circle()
                                            .fill(facility.type.themeColor.opacity(0.15))
                                            .frame(width: 34, height: 34)

                                        FacilityTypeIcon(type: facility.type, size: 14)
                                    }

                                    // 設施名稱與地址說明
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(facility.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)

                                        HStack(spacing: 4) {
                                            Text(facility.category.rawValue)
                                                .font(.caption2.bold())
                                                .foregroundColor(facility.type.themeColor)

                                            Text("·")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)

                                            Text(facility.address)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()

                                    // 距離標籤與導航箭頭
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(facility.formattedDistance(from: viewModel.locationManager.userLocation))
                                            .font(.caption2.bold())
                                            .foregroundColor(.teal)

                                        Image(systemName: "arrow.up.left")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.secondary.opacity(0.8))
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .frame(maxHeight: 250)
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 12, y: 6)
        .padding(.horizontal, 16)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
            removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
        ))
    }

    private func selectSuggestion(facility: Facility) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isShowingSearchSuggestions = false
            viewModel.focusOn(facility: facility)
        }
    }
}

// MARK: - 地標聚類圓形圖標 ClusterMapPin
struct ClusterMapPin: View {
    let cluster: FacilityCluster
    var activeFilter: FacilityTypeFilter = .all
    let onTap: () -> Void

    var clusterColor: Color {
        switch activeFilter {
        case .toiletOnly:
            return .teal
        case .waterOnly:
            return .blue
        case .all:
            switch cluster.dominantType {
            case .toilet: return .teal
            case .waterDispenser: return .blue
            case .both: return .indigo
            }
        }
    }

    private var pinSize: CGFloat {
        if cluster.count >= 100 {
            return 44
        } else if cluster.count >= 20 {
            return 38
        } else {
            return 32
        }
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 外圈半透明光暈
                Circle()
                    .fill(clusterColor.opacity(0.22))
                    .frame(width: pinSize + 10, height: pinSize + 10)

                // 核心圓形
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [clusterColor.opacity(0.88), clusterColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: pinSize, height: pinSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2.2)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 1.5)

                // 數量文字
                Text(cluster.formattedCount)
                    .font(.system(size: cluster.count >= 100 ? 12 : 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 自訂地圖圖標 Pin
struct FacilityMapPin: View {
    let facility: Facility
    let isSelected: Bool
    var isZoomedOut: Bool = false
    var activeFilter: FacilityTypeFilter = .all
    let onTap: () -> Void

    /// 根據目前使用者選取的分類，決定標示點呈現類型：
    /// - 選擇「廁所」分類時：一律只顯示為純「廁所標示點」（Teal 藍綠色、toilet.fill 🚽 專屬馬桶符號）
    /// - 選擇「飲水機」分類時：一律只顯示為純「飲水機標示點」（Blue 科技藍、drop.fill 💧 專屬水滴符號）
    /// - 選擇「全部」分類時：顯示各自類型（廁所、飲水機、雙合一）
    var displayType: FacilityType {
        switch activeFilter {
        case .toiletOnly:
            return .toilet
        case .waterOnly:
            return .waterDispenser
        case .all:
            return facility.type
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                // 選取地標且非拉遠視角時，才彈出名稱標籤卡片，避免地圖拉遠時遮蓋道路與全島
                if isSelected && !isZoomedOut {
                    HStack(spacing: 5) {
                        FacilityTypeIcon(type: displayType, size: 12)
                        Text(facility.name)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.18), radius: 4, y: 2)
                    .fixedSize()
                    .transition(.scale.combined(with: .opacity))
                }

                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(displayType.themeColor)
                            .frame(width: isSelected ? 40 : 28, height: isSelected ? 40 : 28)
                            .overlay(Circle().stroke(Color.white, lineWidth: isSelected ? 2.5 : 1.6))
                            .shadow(color: Color.black.opacity(isSelected ? 0.35 : 0.2), radius: isSelected ? 4 : 2, y: 1)

                        // 標示點上的核心圖標（清晰放大且加粗）
                        FacilityTypePinIcon(type: displayType, isSelected: isSelected)
                    }

                    // 指標三角形
                    Image(systemName: "triangle.fill")
                        .font(.system(size: isSelected ? 8 : 6))
                        .foregroundColor(displayType.themeColor)
                        .rotationEffect(.degrees(180))
                        .offset(y: -2)
                }
            }
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .zIndex(isSelected ? 10 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

/// 地圖標示點專用高對比加粗圖標視圖
struct FacilityTypePinIcon: View {
    let type: FacilityType
    let isSelected: Bool

    var body: some View {
        switch type {
        case .toilet:
            Image(systemName: "toilet.fill")
                .font(.system(size: isSelected ? 18 : 14.5, weight: .bold))
                .foregroundColor(.white)
        case .waterDispenser:
            Image(systemName: "drop.fill")
                .font(.system(size: isSelected ? 18 : 14.5, weight: .bold))
                .foregroundColor(.white)
        case .both:
            HStack(spacing: 2) {
                Image(systemName: "toilet.fill")
                    .font(.system(size: isSelected ? 13 : 10.5, weight: .bold))
                Image(systemName: "drop.fill")
                    .font(.system(size: isSelected ? 12 : 9.5, weight: .bold))
            }
            .foregroundColor(.white)
        }
    }
}

// MARK: - 頂部膠囊按鈕
struct MapFilterTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(18)
        }
    }
}
