import SwiftUI
import CoreLocation

struct FacilityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FacilityViewModel
    let facility: Facility

    @State private var showReportSheet: Bool = false
    @State private var showCopiedAlert: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 0. 社群即時問題警示橫幅
                if let alert = facility.activeIssueAlert {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("社群最新回報狀況")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                            Text(alert)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Button(action: { showReportSheet = true }) {
                            Text("更新現況")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                        }
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }

                // 1. 頂部主視覺卡片
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(facility.type.themeColor.opacity(0.15))
                                .frame(width: 56, height: 56)

                            FacilityTypeIcon(type: facility.type, size: 24)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(facility.name)
                                .font(.title3.bold())
                                .foregroundColor(.primary)

                            HStack(spacing: 8) {
                                Label(facility.category.rawValue, systemImage: facility.category.systemIcon)
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)

                                Text("•")
                                    .foregroundColor(.secondary)

                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text(String(format: "%.1f", facility.rating))
                                        .font(.caption.bold())
                                    Text("(\(facility.reviewCount) 則評論)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()
                    }

                    Divider()

                    // 距離、預估步行時間與開放狀態
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("距離")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(facility.formattedDistance(from: viewModel.locationManager.userLocation))
                                .font(.headline.bold())
                        }

                        if let walkMin = facility.estimatedWalkingMinutes(from: viewModel.locationManager.userLocation) {
                            Divider().frame(height: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("步行預估")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(walkMin) 分鐘")
                                    .font(.headline.bold())
                                    .foregroundColor(.teal)
                            }
                        }

                        Divider().frame(height: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("開放狀況")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(facility.isOpenNow ? "營業開放中" : "非開放時段")
                                .font(.headline.bold())
                                .foregroundColor(facility.isOpenNow ? .green : .red)
                        }
                    }
                }
                .padding(18)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(18)

                // 2. 雙導航按鈕 (Apple Maps & Google Maps)
                HStack(spacing: 12) {
                    Button(action: { viewModel.openInAppleMaps(facility: facility) }) {
                        Label("Apple 地圖導航", systemImage: "map.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: { viewModel.openInGoogleMaps(facility: facility) }) {
                        Label("Google Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }

                // 3. 詳細位置與樓層指引
                VStack(alignment: .leading, spacing: 12) {
                    Text("位置與指引")
                        .font(.headline)

                    VStack(spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("地址")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(facility.address)
                                    .font(.subheadline)
                            }

                            Spacer()

                            Button(action: {
                                UIPasteboard.general.string = facility.address
                                showCopiedAlert = true
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }

                        Divider()

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "signpost.right.and.left.fill")
                                .foregroundColor(.teal)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("詳細樓層 / 所在位置備註")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(facility.floorDescription)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }

                        Divider()

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("開放時間")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(facility.openingHours)
                                    .font(.subheadline)
                            }
                            Spacer()
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                }

                // 4. 設施配備檢視 (Checklist)
                VStack(alignment: .leading, spacing: 12) {
                    Text("設施規格清單")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        if facility.type == .toilet || facility.type == .both {
                            FeatureRow(title: "無障礙廁所", isAvailable: facility.hasAccessibleToilet, icon: "figure.roll")
                            FeatureRow(title: "親子 / 尿布台", isAvailable: facility.hasNurseryOrDiaper, icon: "stroller")
                            FeatureRow(title: "性別友善廁所", isAvailable: facility.isGenderFriendly, icon: "person.2.fill")
                            FeatureRow(title: "免治馬桶", isAvailable: facility.hasBidet, icon: "sparkles")
                            FeatureRow(title: "提供衛生紙", isAvailable: facility.hasToiletPaper, icon: "newspaper")
                            FeatureRow(title: "免費使用", isAvailable: facility.isFree, icon: "dollarsign.circle")
                        }

                        if facility.type == .waterDispenser || facility.type == .both {
                            FeatureRow(title: "提供熱水", isAvailable: facility.hasHotWater, icon: "flame.fill")
                            FeatureRow(title: "提供溫水", isAvailable: facility.hasWarmWater, icon: "cup.and.saucer.fill")
                            FeatureRow(title: "提供冰水", isAvailable: facility.hasColdWater, icon: "snowflake")
                            FeatureRow(title: "自備環保杯友善", isAvailable: facility.isCupFriendly, icon: "waterbottle.fill")
                            FeatureRow(title: "濾芯水質合格", isAvailable: facility.isFilterCertified, icon: "checkmark.seal.fill")
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                }

                // 5. 最新維護與巡檢狀態
                if let note = facility.maintenanceStatusNote {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("巡檢維護備註")
                            .font(.headline)

                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title2)
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(note)
                                    .font(.subheadline)
                                Text("資料核對日期：\(facility.lastUpdatedDate)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(14)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("設施詳情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .symbolRenderingMode(.hierarchical)
                        Text("關閉")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { showReportSheet = true }) {
                        Image(systemName: "exclamationmark.bubble")
                            .foregroundColor(.orange)
                    }

                    Button(action: { viewModel.toggleFavorite(facility: facility) }) {
                        Image(systemName: facility.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(facility.isFavorite ? .red : .primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportIssueView(viewModel: viewModel, facility: facility)
        }
        .alert("已複製地址", isPresented: $showCopiedAlert) {
            Button("確定", role: .cancel) {}
        }
    }
}

struct FeatureRow: View {
    let title: String
    let isAvailable: Bool
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isAvailable ? .teal : .gray)
                .frame(width: 20)

            Text(title)
                .font(.caption)
                .foregroundColor(isAvailable ? .primary : .secondary)

            Spacer()

            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle")
                .font(.caption)
                .foregroundColor(isAvailable ? .green : .gray.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}
