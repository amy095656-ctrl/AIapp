import SwiftUI

struct AboutSettingsView: View {
    @ObservedObject var viewModel: FacilityViewModel
    @State private var showFeedbackAlert: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // 1. App 簡介與品牌 Logo
                Section {
                    HStack(spacing: 16) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("水便搜")
                                    .font(.title3.bold())
                                Text("v1.1")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.teal.opacity(0.15))
                                    .foregroundColor(.teal)
                                    .cornerRadius(6)
                            }

                            Text("水機 & 便所隨時搜 · 全台便民指南")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("「水」補水 ·「便」解急 · 隨便搜！")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.teal)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // 3. 意見反映與回饋
                Section(header: Text("意見反饋")) {
                    Button(action: { showFeedbackAlert = true }) {
                        Label("意見反映與功能許願", systemImage: "envelope.fill")
                            .foregroundColor(.teal)
                    }
                }

                // 4. 開放資料與技術資訊
                Section(header: Text("資料來源與透明度")) {
                    InfoRow(title: "環境部公共廁所開放資料", subtitle: "列管特優級、優等級公廁名冊與設備屬性", icon: "building.columns.fill")
                    InfoRow(title: "各大軌道車站開放資料", subtitle: "北捷、高捷、中捷、台鐵、高鐵車站飲水台與洗手間", icon: "tram.fill")
                    InfoRow(title: "地方自來水直飲水台", subtitle: "台北自來水事業處與各縣市水質檢測數據", icon: "drop.fill")
                    InfoRow(title: "OpenStreetMap (OSM)", subtitle: "全球與台灣社群地理開放標記資料庫", icon: "globe")
                }

                // 5. 離線快取
                Section(header: Text("離線支援與設定")) {
                    HStack {
                        Label("離線重要節點資料庫", systemImage: "internaldrive.fill")
                        Spacer()
                        Text("全台即時載入")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("水質檢驗認證自動更新", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        Text("每日自動檢查")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // 6. 使用注意事項
                Section(header: Text("使用注意事項")) {
                    Text("本應用程式彙整之資訊僅供便民應急參考，實際開放時段、清潔狀況或維護保養工程，均以現場管理單位（捷運公司、超商、加油站、管理處）公告及現場狀況為準。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("設定與來源")
            .alert("感謝您的回饋！", isPresented: $showFeedbackAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text("您的寶貴意見將是我們持續改進「水便搜」全台便民地圖的最大動力。")
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.teal)
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
