import Foundation
import CoreLocation
import SwiftUI

/// 設施類型
enum FacilityType: String, CaseIterable, Codable, Identifiable {
    case toilet = "廁所"
    case waterDispenser = "飲水機"
    case both = "廁所與飲水機"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .toilet:
            return "toilet.fill"
        case .waterDispenser:
            return "drop.fill"
        case .both:
            return "toilet.fill"
        }
    }

    var themeColor: Color {
        switch self {
        case .toilet:
            return Color.teal
        case .waterDispenser:
            return Color.blue
        case .both:
            return Color.indigo
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        switch str {
        case "toilet", "廁所":
            self = .toilet
        case "waterDispenser", "飲水機":
            self = .waterDispenser
        case "both", "廁所與飲水機":
            self = .both
        default:
            self = .both
        }
    }
}

/// 統一設施類型圖標視圖：確保地圖標註、列表、卡片、詳情頁各處圖標完全一致
struct FacilityTypeIcon: View {
    let type: FacilityType
    var size: CGFloat = 16
    var foregroundColor: Color? = nil

    var body: some View {
        Group {
            switch type {
            case .toilet:
                Image(systemName: "toilet.fill")
                    .font(.system(size: size, weight: .bold))
            case .waterDispenser:
                Image(systemName: "drop.fill")
                    .font(.system(size: size, weight: .bold))
            case .both:
                HStack(spacing: size > 14 ? 3 : 1.5) {
                    Image(systemName: "toilet.fill")
                        .font(.system(size: size * 0.88, weight: .bold))
                    Image(systemName: "drop.fill")
                        .font(.system(size: size * 0.82, weight: .bold))
                }
            }
        }
        .foregroundColor(foregroundColor ?? type.themeColor)
    }
}

/// 場所類別
enum LocationCategory: String, CaseIterable, Codable, Identifiable {
    case mrtStation = "捷運站"
    case trainStation = "台鐵/高鐵"
    case park = "公園/景點"
    case libraryOrGov = "政府/圖書館"
    case convenienceStore = "便利超商"
    case gasStation = "加油站"
    case departmentStore = "百貨商場"
    case school = "大專院校"
    case other = "其他"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .mrtStation: return "tram.fill"
        case .trainStation: return "train.side.front.car"
        case .park: return "leaf.fill"
        case .libraryOrGov: return "building.columns.fill"
        case .convenienceStore: return "cart.fill"
        case .gasStation: return "fuelpump.fill"
        case .departmentStore: return "bag.fill"
        case .school: return "graduationcap.fill"
        case .other: return "mappin.and.ellipse"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        switch str {
        case "mrtStation", "捷運站", "捷運/車站":
            self = .mrtStation
        case "trainStation", "台鐵/高鐵":
            self = .trainStation
        case "park", "公園/景點":
            self = .park
        case "libraryOrGov", "政府/圖書館":
            self = .libraryOrGov
        case "convenienceStore", "便利超商":
            self = .convenienceStore
        case "gasStation", "加油站":
            self = .gasStation
        case "departmentStore", "百貨商場":
            self = .departmentStore
        case "school", "大專院校":
            self = .school
        case "other", "其他":
            self = .other
        default:
            self = .other
        }
    }
}

/// 便民設施模型
struct Facility: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var type: FacilityType
    var category: LocationCategory
    var latitude: Double
    var longitude: Double
    var address: String
    var floorDescription: String
    var openingHours: String
    var isOpenNow: Bool
    var rating: Double
    var reviewCount: Int
    var isFavorite: Bool = false

    // 廁所專屬特徵
    var hasAccessibleToilet: Bool = false    // 無障礙設施
    var hasNurseryOrDiaper: Bool = false      // 親子/尿布台
    var isGenderFriendly: Bool = false        // 性別友善
    var hasBidet: Bool = false                // 免治馬桶
    var hasToiletPaper: Bool = true           // 提供衛生紙
    var isFree: Bool = true                   // 免費使用

    // 飲水機專屬特徵
    var hasHotWater: Bool = true              // 提供熱水 (85°C-100°C)
    var hasWarmWater: Bool = true             // 提供溫水
    var hasColdWater: Bool = true             // 提供冰水
    var isCupFriendly: Bool = true            // 自備環保杯友善
    var isFilterCertified: Bool = true        // 濾芯檢驗合格認證

    // 備註與最新維護狀態
    var maintenanceStatusNote: String? = nil
    var activeIssueAlert: String? = nil
    var lastUpdatedDate: String = "2026/10/01"

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// 根據傳入的用戶座標計算距離（公尺）
    func distance(from userLocation: CLLocationCoordinate2D?) -> CLLocationDistance? {
        guard let userLocation = userLocation else { return nil }
        let current = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let destination = CLLocation(latitude: latitude, longitude: longitude)
        return current.distance(from: destination)
    }

    /// 格式化距離字串（如 "150 公尺" 或 "2.4 公里"）
    func formattedDistance(from userLocation: CLLocationCoordinate2D?) -> String {
        guard let dist = distance(from: userLocation) else { return "-- 公尺" }
        if dist < 1000 {
            return "\(Int(dist)) 公尺"
        } else {
            return String(format: "%.1f 公里", dist / 1000.0)
        }
    }

    /// 預估步行時間 (以平均每分鐘 70 公尺計算)
    func estimatedWalkingMinutes(from userLocation: CLLocationCoordinate2D?) -> Int? {
        guard let dist = distance(from: userLocation) else { return nil }
        let minutes = Int(ceil(dist / 70.0))
        return max(1, minutes)
    }
}
