import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = FacilityViewModel()

    var body: some View {
        TabView {
            HomeMapView(viewModel: viewModel)
                .tabItem {
                    Label("地圖搜尋", systemImage: "map.fill")
                }

            ReportCenterView(viewModel: viewModel)
                .tabItem {
                    Label("回報中心", systemImage: "exclamationmark.bubble.fill")
                }

            FavoriteListView(viewModel: viewModel)
                .tabItem {
                    Label("我的收藏", systemImage: "heart.fill")
                }

            AboutSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("設定與來源", systemImage: "info.circle.fill")
                }
        }
        .tint(.teal)
    }
}
