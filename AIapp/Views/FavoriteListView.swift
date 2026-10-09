import SwiftUI

struct FavoriteListView: View {
    @ObservedObject var viewModel: FacilityViewModel
    @State private var selectedFacilityForDetail: Facility? = nil

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.favoriteFacilities.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.4))

                        Text("目前尚無收藏的設施")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("在探索地圖或列表時，點擊愛心圖示即可將常去的優質洗手間或飲水點加入收藏。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer()
                    }
                } else {
                    List {
                        Section(header: Text("已收藏 \(viewModel.favoriteFacilities.count) 個常去據點")) {
                            ForEach(viewModel.favoriteFacilities) { facility in
                                FacilityListRow(
                                    facility: facility,
                                    userLocation: viewModel.locationManager.userLocation,
                                    onTap: {
                                        selectedFacilityForDetail = facility
                                    },
                                    onNavigate: {
                                        viewModel.openInAppleMaps(facility: facility)
                                    },
                                    onToggleFavorite: {
                                        viewModel.toggleFavorite(facility: facility)
                                    }
                                )
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("我的收藏")
            .sheet(item: $selectedFacilityForDetail) { facility in
                NavigationStack {
                    FacilityDetailView(viewModel: viewModel, facility: facility)
                }
            }
        }
    }
}
