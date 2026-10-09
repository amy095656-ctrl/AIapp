import SwiftUI

struct FacilityCardView: View {
    let facility: Facility
    let userLocation: CLLocationCoordinate2D?
    var activeFilter: FacilityTypeFilter = .all
    let onNavigate: () -> Void
    let onShowDetail: () -> Void
    let onToggleFavorite: () -> Void

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
        VStack(alignment: .leading, spacing: 12) {
            // 頂部標題與收藏按鈕
            HStack(alignment: .top, spacing: 10) {
                // 類型圖標徽章
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(displayType.themeColor.opacity(0.15))
                        .frame(width: 46, height: 46)

                    FacilityTypeIcon(type: displayType, size: 20)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(facility.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if facility.rating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text(String(format: "%.1f", facility.rating))
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // 距離與步行時間
                    HStack(spacing: 8) {
                        if let walkingMin = facility.estimatedWalkingMinutes(from: userLocation) {
                            Label("步行約 \(walkingMin) 分鐘", systemImage: "figure.walk")
                                .font(.caption)
                                .foregroundColor(.teal)
                        }

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(facility.formattedDistance(from: userLocation))
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(facility.isOpenNow ? "開放中" : "暫停開放")
                            .font(.caption.bold())
                            .foregroundColor(facility.isOpenNow ? .green : .red)
                    }
                }

                Spacer()

                // 收藏按鈕
                Button(action: onToggleFavorite) {
                    Image(systemName: facility.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(facility.isFavorite ? .red : .gray)
                        .padding(6)
                }
            }

            // 特色標籤 Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // 場所類型標籤
                    HStack(spacing: 4) {
                        Image(systemName: facility.category.systemIcon)
                        Text(facility.category.rawValue)
                    }
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                    if let issue = facility.activeIssueAlert {
                        ChipBadge(title: issue, systemImage: "exclamationmark.triangle.fill", color: .orange)
                    }

                    if facility.hasAccessibleToilet {
                        ChipBadge(title: "無障礙", systemImage: "figure.roll", color: .purple)
                    }
                    if facility.hasNurseryOrDiaper {
                        ChipBadge(title: "尿布台", systemImage: "stroller", color: .pink)
                    }
                    if facility.hasHotWater {
                        ChipBadge(title: "熱水", systemImage: "flame.fill", color: .orange)
                    }
                    if facility.hasColdWater {
                        ChipBadge(title: "冰水", systemImage: "snowflake", color: .cyan)
                    }
                    if facility.hasBidet {
                        ChipBadge(title: "免治", systemImage: "sparkles", color: .teal)
                    }
                    if facility.isFree {
                        ChipBadge(title: "免費", systemImage: "checkmark.circle.fill", color: .green)
                    }
                }
            }

            // 底部操作按鈕組
            HStack(spacing: 12) {
                Button(action: onShowDetail) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("詳細資訊與指引")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }

                Button(action: onNavigate) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("立即前往")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(LinearGradient(colors: [Color.teal, Color.blue], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: Color.blue.opacity(0.3), radius: 5, y: 2)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
        )
    }
}

struct ChipBadge: View {
    let title: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.caption2.weight(.medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}
