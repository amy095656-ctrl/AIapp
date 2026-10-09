import Foundation
import CoreLocation

enum FacilityTypeFilter: String, CaseIterable, Identifiable {
    case all = "全部設施"
    case toiletOnly = "僅看廁所"
    case waterOnly = "僅看飲水機"

    var id: String { rawValue }
}

enum DistanceFilter: Double, CaseIterable, Identifiable {
    case m300 = 300
    case m500 = 500
    case km1 = 1000
    case km3 = 3000
    case unlimited = 999999

    var id: Double { rawValue }

    var label: String {
        switch self {
        case .m300: return "300 公尺內"
        case .m500: return "500 公尺內"
        case .km1: return "1 公里內"
        case .km3: return "3 公里內"
        case .unlimited: return "不限距離"
        }
    }
}

/// 篩選方式二選一：場所類型 vs 所在城市
enum LocationFilterMode: String, CaseIterable, Identifiable {
    case byCategory = "依場所類型"
    case byCity = "依所屬城市"

    var id: String { rawValue }
}

/// 台灣各縣市
enum TaiwanCity: String, CaseIterable, Identifiable, Codable {
    case taipei = "台北市"
    case newTaipei = "新北市"
    case keelung = "基隆市"
    case taoyuan = "桃園市"
    case hsinchu = "新竹"
    case miaoli = "苗栗縣"
    case taichung = "台中市"
    case changhua = "彰化縣"
    case nantou = "南投縣"
    case yunlin = "雲林縣"
    case chiayi = "嘉義"
    case tainan = "台南市"
    case kaohsiung = "高雄市"
    case pingtung = "屏東縣"
    case yilan = "宜蘭縣"
    case hualien = "花蓮縣"
    case taitung = "台東縣"
    case penghu = "澎湖縣"
    case kinmen = "金門縣"
    case matsu = "連江縣"

    var id: String { rawValue }

    var keyword: String {
        switch self {
        case .hsinchu: return "新竹"
        case .chiayi: return "嘉義"
        default: return rawValue
        }
    }

    var centerCoordinate: CLLocationCoordinate2D {
        switch self {
        case .taipei: return CLLocationCoordinate2D(latitude: 25.0375, longitude: 121.5637)
        case .newTaipei: return CLLocationCoordinate2D(latitude: 25.0123, longitude: 121.4657)
        case .keelung: return CLLocationCoordinate2D(latitude: 25.1276, longitude: 121.7392)
        case .taoyuan: return CLLocationCoordinate2D(latitude: 24.9936, longitude: 121.3010)
        case .hsinchu: return CLLocationCoordinate2D(latitude: 24.8138, longitude: 120.9675)
        case .miaoli: return CLLocationCoordinate2D(latitude: 24.5602, longitude: 120.8214)
        case .taichung: return CLLocationCoordinate2D(latitude: 24.1477, longitude: 120.6736)
        case .changhua: return CLLocationCoordinate2D(latitude: 24.0815, longitude: 120.5385)
        case .nantou: return CLLocationCoordinate2D(latitude: 23.9610, longitude: 120.9719)
        case .yunlin: return CLLocationCoordinate2D(latitude: 23.7092, longitude: 120.4313)
        case .chiayi: return CLLocationCoordinate2D(latitude: 23.4800, longitude: 120.4491)
        case .tainan: return CLLocationCoordinate2D(latitude: 22.9997, longitude: 120.2270)
        case .kaohsiung: return CLLocationCoordinate2D(latitude: 22.6273, longitude: 120.3014)
        case .pingtung: return CLLocationCoordinate2D(latitude: 22.5500, longitude: 120.5400)
        case .yilan: return CLLocationCoordinate2D(latitude: 24.7570, longitude: 121.7530)
        case .hualien: return CLLocationCoordinate2D(latitude: 23.9872, longitude: 121.6016)
        case .taitung: return CLLocationCoordinate2D(latitude: 22.7583, longitude: 121.1444)
        case .penghu: return CLLocationCoordinate2D(latitude: 23.5711, longitude: 119.5793)
        case .kinmen: return CLLocationCoordinate2D(latitude: 24.4493, longitude: 118.3766)
        case .matsu: return CLLocationCoordinate2D(latitude: 26.1550, longitude: 119.9500)
        }
    }

    var spanDelta: Double {
        switch self {
        case .keelung, .penghu, .kinmen, .matsu: return 0.12
        case .taipei, .newTaipei, .taoyuan, .hsinchu, .taichung, .changhua, .chiayi, .tainan, .kaohsiung: return 0.18
        case .miaoli, .yunlin, .yilan: return 0.28
        case .nantou, .pingtung, .hualien, .taitung: return 0.45
        }
    }
}

struct FilterOptions: Equatable {
    var typeFilter: FacilityTypeFilter = .all
    var distanceLimit: DistanceFilter = .unlimited

    // 篩選模式二選一
    var locationFilterMode: LocationFilterMode = .byCategory
    var selectedCategory: LocationCategory? = nil
    var selectedCity: TaiwanCity? = nil

    // 廁所專屬特定需求
    var requireAccessible: Bool = false      // 無障礙設施 ♿️
    var requireNursery: Bool = false         // 親子尿布台 👶
    var requireGenderFriendly: Bool = false   // 性別友善廁所 🚻
    var requireBidet: Bool = false           // 免治馬桶 🚽
    var requireToiletPaper: Bool = false     // 提供衛生紙 🧻

    // 飲水機專屬特定需求
    var requireHotWater: Bool = false        // 提供熱水 🔥
    var requireWarmWater: Bool = false       // 提供溫水 ☕️
    var requireColdWater: Bool = false       // 提供冰水 ❄️
    var requireCupFriendly: Bool = false     // 自備環保杯友善 🥤

    // 計算是否有生效的過濾條件
    var activeFilterCount: Int {
        var count = 0
        if typeFilter != .all { count += 1 }
        if distanceLimit != .unlimited { count += 1 }
        if locationFilterMode == .byCategory && selectedCategory != nil { count += 1 }
        if locationFilterMode == .byCity && selectedCity != nil { count += 1 }
        if requireAccessible { count += 1 }
        if requireNursery { count += 1 }
        if requireGenderFriendly { count += 1 }
        if requireBidet { count += 1 }
        if requireToiletPaper { count += 1 }
        if requireHotWater { count += 1 }
        if requireWarmWater { count += 1 }
        if requireColdWater { count += 1 }
        if requireCupFriendly { count += 1 }
        return count
    }

    mutating func reset() {
        self = FilterOptions()
    }
}
