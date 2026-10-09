import Foundation

enum IssueType: String, CaseIterable, Codable, Identifiable {
    case noToiletPaper = "衛生紙耗盡 / 需補充"
    case waterIssue = "飲水機異常 (無水/水溫不符)"
    case outOfService = "設備故障 / 暫停開放"
    case cleanliness = "環境清潔需加強"
    case facilityDamaged = "設施損壞 (門鎖/水喉/沖水把手)"
    case locationIncorrect = "位置標記或開放時間有誤"
    case other = "其他狀況反映"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .noToiletPaper: return "newspaper.fill"
        case .waterIssue: return "drop.triangle.fill"
        case .outOfService: return "exclamationmark.octagon.fill"
        case .cleanliness: return "trash.fill"
        case .facilityDamaged: return "wrench.and.screwdriver.fill"
        case .locationIncorrect: return "mappin.slash"
        case .other: return "bubble.left.and.exclamationmark.bubble.right.fill"
        }
    }
}

enum IssueSeverity: String, CaseIterable, Codable, Identifiable {
    case notice = "一般提醒 (仍可使用)"
    case moderate = "部分受限 (影響體驗)"
    case urgent = "重大故障 (完全無法使用)"

    var id: String { rawValue }

    var colorName: String {
        switch self {
        case .notice: return "orange"
        case .moderate: return "red"
        case .urgent: return "purple"
        }
    }
}

enum ReportStatus: String, Codable {
    case pending = "處理中 / 審核中"
    case verified = "社群已驗證"
    case resolved = "已修復 / 已更新"
}

struct FacilityReport: Identifiable, Codable {
    var id: UUID = UUID()
    var facilityId: UUID
    var facilityName: String
    var issueType: IssueType
    var severity: IssueSeverity
    var rating: Int
    var comment: String
    var reportedDate: Date = Date()
    var status: ReportStatus = .pending
    var hasPhotoAttached: Bool = false

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: reportedDate)
    }
}
