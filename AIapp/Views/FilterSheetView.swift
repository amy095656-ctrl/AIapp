import SwiftUI

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FacilityViewModel

    var body: some View {
        NavigationStack {
            Form {
                // 1. 所在縣市選取 (收納全台 22 縣市)
                Section(header: Text("📍 所在縣市 (全台 22 縣市選取)")) {
                    Picker("選擇縣市", selection: $viewModel.filterOptions.selectedCity) {
                        Text("全台灣所有縣市").tag(TaiwanCity?.none)
                        ForEach(TaiwanCity.allCases) { city in
                            Text(city.rawValue).tag(Optional(city))
                        }
                    }
                    .onChange(of: viewModel.filterOptions.selectedCity) { _, newCity in
                        if newCity != nil {
                            viewModel.filterOptions.locationFilterMode = .byCity
                        }
                    }

                    // 快速熱門縣市標籤列
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            FilterCityPill(
                                title: "全台",
                                isSelected: viewModel.filterOptions.selectedCity == nil
                            ) {
                                viewModel.filterOptions.selectedCity = nil
                            }

                            ForEach([TaiwanCity.taipei, .newTaipei, .taichung, .tainan, .kaohsiung, .taoyuan, .hsinchu]) { city in
                                FilterCityPill(
                                    title: city.rawValue,
                                    isSelected: viewModel.filterOptions.selectedCity == city
                                ) {
                                    if viewModel.filterOptions.selectedCity == city {
                                        viewModel.filterOptions.selectedCity = nil
                                    } else {
                                        viewModel.filterOptions.locationFilterMode = .byCity
                                        viewModel.filterOptions.selectedCity = city
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                // 2. 設施主要類型
                Section(header: Text("設施主要類型")) {
                    Picker("類型", selection: $viewModel.filterOptions.typeFilter) {
                        ForEach(FacilityTypeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 3. 場所類型
                Section(header: Text("🏢 場所類型")) {
                    Picker("依場所類型篩選", selection: $viewModel.filterOptions.selectedCategory) {
                        Text("全部場所類型").tag(LocationCategory?.none)
                        ForEach(LocationCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.systemIcon)
                                .tag(Optional(cat))
                        }
                    }
                    .onChange(of: viewModel.filterOptions.selectedCategory) { _, newCat in
                        if newCat != nil {
                            viewModel.filterOptions.locationFilterMode = .byCategory
                        }
                    }
                }

                // 4. 距離範圍細部屬性
                Section(header: Text("📏 距離範圍")) {
                    Picker("最大距離", selection: $viewModel.filterOptions.distanceLimit) {
                        ForEach(DistanceFilter.allCases) { dist in
                            Text(dist.label).tag(dist)
                        }
                    }
                }

                // 5. 飲水機專屬細部配備屬性 (若選僅看廁所則隱藏)
                if viewModel.filterOptions.typeFilter == .waterOnly || viewModel.filterOptions.typeFilter == .all {
                    Section(header: Text("💧 飲水機細部配備屬性")) {
                        Toggle("需提供熱水 🔥", isOn: $viewModel.filterOptions.requireHotWater)
                        Toggle("需提供溫水 ☕️", isOn: $viewModel.filterOptions.requireWarmWater)
                        Toggle("需提供冰水 ❄️", isOn: $viewModel.filterOptions.requireColdWater)
                        Toggle("自備環保杯友善 🥤", isOn: $viewModel.filterOptions.requireCupFriendly)
                    }
                }

                // 6. 廁所專屬設施與衛生細部屬性 (若選僅看飲水機則隱藏)
                if viewModel.filterOptions.typeFilter == .toiletOnly || viewModel.filterOptions.typeFilter == .all {
                    Section(header: Text("🚻 廁所設施與衛生配備屬性")) {
                        Toggle("需具備無障礙設施 ♿️", isOn: $viewModel.filterOptions.requireAccessible)
                        Toggle("需有親子尿布台 👶", isOn: $viewModel.filterOptions.requireNursery)
                        Toggle("需為性別友善廁所 🚻", isOn: $viewModel.filterOptions.requireGenderFriendly)
                        Toggle("需配備免治馬桶 🚽", isOn: $viewModel.filterOptions.requireBidet)
                        Toggle("需提供衛生紙 🧻", isOn: $viewModel.filterOptions.requireToiletPaper)
                    }
                }
            }
            .navigationTitle("進階篩選")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("重設") {
                        viewModel.filterOptions.reset()
                    }
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        applyAndDismiss()
                    }
                    .font(.headline)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: { applyAndDismiss() }) {
                    HStack {
                        Text("套用進階篩選 (符合 \(viewModel.filteredFacilities.count) 個據點)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient(colors: [Color.teal, Color.blue], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(.ultraThinMaterial)
            }
        }
    }

    private func applyAndDismiss() {
        viewModel.applyFilterAndFocus()
        dismiss()
    }
}

/// 篩選視窗專用縣市快捷膠囊
struct FilterCityPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.teal : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
