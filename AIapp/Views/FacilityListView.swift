import SwiftUI
import CoreLocation

struct FacilityListView: View {
    @ObservedObject var viewModel: FacilityViewModel
    @State private var selectedFacilityForDetail: Facility? = nil
    @State private var isAdvancedFilterExpanded: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - 多層次篩選系統 (Hierarchical Filter System)
                VStack(spacing: 6) {
                    // 第一層：設施主類別切換 (Tier 1: Facility Primary Type)
                    tier1TypeSegmentBar

                    // 第二層：情境特定需求快捷篩選 (Tier 2: Contextual Requirements)
                    tier2ContextualChipsBar

                    // 第三層：空間維度二選一快捷選取 (Tier 3: Region vs Category Dimension Bar)
                    tier3DimensionBar

                    // 第四層：已生效篩選條件麵包屑條 (Tier 4: Active Filter Breadcrumbs)
                    if viewModel.filterOptions.activeFilterCount > 0 {
                        tier4ActiveFilterStrip
                    }

                    // MARK: - 進階篩選含欄位表 (合併自原獨立篩選頁面)
                    if isAdvancedFilterExpanded {
                        advancedFieldTableView
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))

                Divider()

                // MARK: - 搜尋結果列表
                if viewModel.filteredFacilities.isEmpty {
                    emptyResultView
                } else {
                    facilityListContent
                }
            }
            .navigationTitle("搜尋便民設施")
            .searchable(text: $viewModel.searchText, prompt: "搜尋地點、站名、路名...")
            .sheet(item: $selectedFacilityForDetail) { facility in
                NavigationStack {
                    FacilityDetailView(viewModel: viewModel, facility: facility)
                }
            }
        }
    }

    // MARK: - Tier 1: 核心設施主類型膠囊切換列
    private var tier1TypeSegmentBar: some View {
        HStack(spacing: 8) {
            TypeSegmentButton(
                title: "全部設施",
                icon: "square.grid.2x2.fill",
                isSelected: viewModel.filterOptions.typeFilter == .all,
                activeColor: .indigo
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.filterOptions.typeFilter = .all
                }
            }

            TypeSegmentButton(
                title: "僅看廁所",
                icon: "toilet.fill",
                isSelected: viewModel.filterOptions.typeFilter == .toiletOnly,
                activeColor: .teal
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.filterOptions.typeFilter = .toiletOnly
                }
            }

            TypeSegmentButton(
                title: "僅看飲水機",
                icon: "drop.fill",
                isSelected: viewModel.filterOptions.typeFilter == .waterOnly,
                activeColor: .blue
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.filterOptions.typeFilter = .waterOnly
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Tier 2: 情境特定需求標籤列 (隨主類型動態切換)
    private var tier2ContextualChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                switch viewModel.filterOptions.typeFilter {
                case .toiletOnly:
                    // 廁所專屬需求
                    FilterTagChip(
                        title: "無障礙設施",
                        systemIcon: "accessibility",
                        isSelected: viewModel.filterOptions.requireAccessible,
                        color: .purple
                    ) {
                        viewModel.filterOptions.requireAccessible.toggle()
                    }

                    FilterTagChip(
                        title: "親子尿布台",
                        systemIcon: "figure.and.child.holdinghands",
                        isSelected: viewModel.filterOptions.requireNursery,
                        color: .pink
                    ) {
                        viewModel.filterOptions.requireNursery.toggle()
                    }

                    FilterTagChip(
                        title: "性別友善",
                        systemIcon: "person.2.circle",
                        isSelected: viewModel.filterOptions.requireGenderFriendly,
                        color: .teal
                    ) {
                        viewModel.filterOptions.requireGenderFriendly.toggle()
                    }

                    FilterTagChip(
                        title: "免治馬桶",
                        systemIcon: "sparkle",
                        isSelected: viewModel.filterOptions.requireBidet,
                        color: .indigo
                    ) {
                        viewModel.filterOptions.requireBidet.toggle()
                    }

                    FilterTagChip(
                        title: "提供衛生紙",
                        systemIcon: "newspaper.fill",
                        isSelected: viewModel.filterOptions.requireToiletPaper,
                        color: .brown
                    ) {
                        viewModel.filterOptions.requireToiletPaper.toggle()
                    }

                case .waterOnly:
                    // 飲水機專屬需求
                    FilterTagChip(
                        title: "提供熱水",
                        systemIcon: "flame.fill",
                        isSelected: viewModel.filterOptions.requireHotWater,
                        color: .orange
                    ) {
                        viewModel.filterOptions.requireHotWater.toggle()
                    }

                    FilterTagChip(
                        title: "提供溫水",
                        systemIcon: "cup.and.saucer.fill",
                        isSelected: viewModel.filterOptions.requireWarmWater,
                        color: .green
                    ) {
                        viewModel.filterOptions.requireWarmWater.toggle()
                    }

                    FilterTagChip(
                        title: "提供冰水",
                        systemIcon: "snowflake",
                        isSelected: viewModel.filterOptions.requireColdWater,
                        color: .cyan
                    ) {
                        viewModel.filterOptions.requireColdWater.toggle()
                    }

                    FilterTagChip(
                        title: "自備杯友善",
                        systemIcon: "mug.fill",
                        isSelected: viewModel.filterOptions.requireCupFriendly,
                        color: .blue
                    ) {
                        viewModel.filterOptions.requireCupFriendly.toggle()
                    }

                case .all:
                    // 全部設施時顯示通用重點條件
                    FilterTagChip(
                        title: "無障礙",
                        systemIcon: "accessibility",
                        isSelected: viewModel.filterOptions.requireAccessible,
                        color: .purple
                    ) {
                        viewModel.filterOptions.requireAccessible.toggle()
                    }

                    FilterTagChip(
                        title: "尿布台",
                        systemIcon: "figure.and.child.holdinghands",
                        isSelected: viewModel.filterOptions.requireNursery,
                        color: .pink
                    ) {
                        viewModel.filterOptions.requireNursery.toggle()
                    }

                    FilterTagChip(
                        title: "有熱水",
                        systemIcon: "flame.fill",
                        isSelected: viewModel.filterOptions.requireHotWater,
                        color: .orange
                    ) {
                        viewModel.filterOptions.requireHotWater.toggle()
                    }

                    FilterTagChip(
                        title: "性別友善",
                        systemIcon: "person.2.circle",
                        isSelected: viewModel.filterOptions.requireGenderFriendly,
                        color: .teal
                    ) {
                        viewModel.filterOptions.requireGenderFriendly.toggle()
                    }

                    FilterTagChip(
                        title: "溫水",
                        systemIcon: "cup.and.saucer.fill",
                        isSelected: viewModel.filterOptions.requireWarmWater,
                        color: .green
                    ) {
                        viewModel.filterOptions.requireWarmWater.toggle()
                    }

                    FilterTagChip(
                        title: "免治馬桶",
                        systemIcon: "sparkle",
                        isSelected: viewModel.filterOptions.requireBidet,
                        color: .indigo
                    ) {
                        viewModel.filterOptions.requireBidet.toggle()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 3)
        }
    }

    // MARK: - Tier 3: 空間維度二選一快捷選取列 (依縣市 vs 依場所類型)
    private var tier3DimensionBar: some View {
        HStack(spacing: 8) {
            // 維度二選一切換按鈕
            Menu {
                Button(action: {
                    withAnimation {
                        viewModel.filterOptions.locationFilterMode = .byCity
                        viewModel.filterOptions.selectedCategory = nil
                    }
                }) {
                    Label("切換為：依所屬城市", systemImage: "map.fill")
                }

                Button(action: {
                    withAnimation {
                        viewModel.filterOptions.locationFilterMode = .byCategory
                        viewModel.filterOptions.selectedCity = nil
                    }
                }) {
                    Label("切換為：依場所類型", systemImage: "building.2.fill")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.filterOptions.locationFilterMode == .byCity ? "mappin.and.ellipse" : "building.2.fill")
                        .font(.caption2.bold())
                    Text(viewModel.filterOptions.locationFilterMode == .byCity ? "城市" : "類型")
                        .font(.caption2.bold())
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.teal.opacity(0.12))
                .foregroundColor(.teal)
                .cornerRadius(12)
            }

            // 橫向滑動藥丸標籤：依當前模式顯示相應項目
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if viewModel.filterOptions.locationFilterMode == .byCity {
                        // 縣市模式快捷按鈕
                        QuickPill(
                            title: "全台",
                            isSelected: viewModel.filterOptions.selectedCity == nil,
                            action: { viewModel.filterOptions.selectedCity = nil }
                        )

                        ForEach(TaiwanCity.allCases) { city in
                            QuickPill(
                                title: city.rawValue,
                                isSelected: viewModel.filterOptions.selectedCity == city,
                                action: {
                                    if viewModel.filterOptions.selectedCity == city {
                                        viewModel.filterOptions.selectedCity = nil
                                    } else {
                                        viewModel.filterOptions.selectedCity = city
                                    }
                                }
                            )
                        }
                    } else {
                        // 場所類型快捷按鈕
                        QuickPill(
                            title: "全部場所",
                            isSelected: viewModel.filterOptions.selectedCategory == nil,
                            action: { viewModel.filterOptions.selectedCategory = nil }
                        )

                        ForEach(LocationCategory.allCases) { category in
                            QuickPill(
                                title: category.rawValue,
                                icon: category.systemIcon,
                                isSelected: viewModel.filterOptions.selectedCategory == category,
                                action: {
                                    if viewModel.filterOptions.selectedCategory == category {
                                        viewModel.filterOptions.selectedCategory = nil
                                    } else {
                                        viewModel.filterOptions.selectedCategory = category
                                    }
                                }
                            )
                        }
                    }
                }
            }

            // 進階篩選按鈕 (列表搜尋唯一保留的進階按鈕)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isAdvancedFilterExpanded.toggle()
                }
            }) {
                HStack(spacing: 3) {
                    Image(systemName: isAdvancedFilterExpanded ? "chevron.up" : "slider.horizontal.3")
                        .font(.caption)
                    Text("進階")
                        .font(.caption2.bold())
                    if viewModel.filterOptions.activeFilterCount > 0 && !isAdvancedFilterExpanded {
                        Text("\(viewModel.filterOptions.activeFilterCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.teal)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(isAdvancedFilterExpanded ? Color.teal : Color(.secondarySystemBackground))
                .foregroundColor(isAdvancedFilterExpanded ? .white : .primary)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }

    // MARK: - Tier 4: 已生效篩選條件麵包屑條 (可即時移除個別條件或重設)
    private var tier4ActiveFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Text("已套用條件：")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                ForEach(activeFilterItems) { item in
                    HStack(spacing: 3) {
                        Text(item.label)
                            .font(.caption2.bold())
                        Button(action: item.removeAction) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.teal.opacity(0.12))
                    .foregroundColor(.teal)
                    .cornerRadius(10)
                }

                Button(action: {
                    withAnimation {
                        viewModel.filterOptions.reset()
                    }
                }) {
                    Text("重設全部")
                        .font(.caption2.bold())
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 2)
        }
    }

    // MARK: - 進階篩選含欄位表 (合併自原獨立篩選頁面)
    private var advancedFieldTableView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題與操作
            HStack {
                Label("進階篩選欄位表", systemImage: "slider.horizontal.3")
                    .font(.subheadline.bold())
                    .foregroundColor(.teal)

                Spacer()

                if viewModel.filterOptions.activeFilterCount > 0 {
                    Button(action: {
                        withAnimation {
                            viewModel.filterOptions.reset()
                        }
                    }) {
                        Text("重設條件")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    }
                    .padding(.trailing, 8)
                }

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isAdvancedFilterExpanded = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    // 1. 距離範圍欄位
                    VStack(alignment: .leading, spacing: 6) {
                        Text("距離範圍")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        Picker("距離範圍", selection: $viewModel.filterOptions.distanceLimit) {
                            ForEach(DistanceFilter.allCases) { dist in
                                Text(dist.label).tag(dist)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // 2. 空間維度模式與選單欄位
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("地點篩選維度")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)

                            Spacer()

                            Picker("維度", selection: $viewModel.filterOptions.locationFilterMode) {
                                ForEach(LocationFilterMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 170)
                        }

                        if viewModel.filterOptions.locationFilterMode == .byCategory {
                            Picker("依場所類型篩選", selection: $viewModel.filterOptions.selectedCategory) {
                                Text("全部場所類型").tag(LocationCategory?.none)
                                ForEach(LocationCategory.allCases) { cat in
                                    Label(cat.rawValue, systemImage: cat.systemIcon)
                                        .tag(Optional(cat))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(10)
                        } else {
                            Picker("依所在縣市篩選", selection: $viewModel.filterOptions.selectedCity) {
                                Text("全台灣所有縣市").tag(TaiwanCity?.none)
                                ForEach(TaiwanCity.allCases) { city in
                                    Text(city.rawValue).tag(Optional(city))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(10)
                        }
                    }

                    // 3. 飲水機專屬特定需求欄位 (若選僅看廁所則隱藏)
                    if viewModel.filterOptions.typeFilter != .toiletOnly {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("💧 飲水機特定需求欄位")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                FilterToggleChip(
                                    title: "需提供熱水 🔥",
                                    isOn: $viewModel.filterOptions.requireHotWater,
                                    activeColor: .orange
                                )
                                FilterToggleChip(
                                    title: "需提供溫水 ☕️",
                                    isOn: $viewModel.filterOptions.requireWarmWater,
                                    activeColor: .green
                                )
                                FilterToggleChip(
                                    title: "需提供冰水 ❄️",
                                    isOn: $viewModel.filterOptions.requireColdWater,
                                    activeColor: .cyan
                                )
                                FilterToggleChip(
                                    title: "自備環保杯 🥤",
                                    isOn: $viewModel.filterOptions.requireCupFriendly,
                                    activeColor: .blue
                                )
                            }
                        }
                    }

                    // 4. 廁所專屬特定需求欄位 (若選僅看飲水機則隱藏)
                    if viewModel.filterOptions.typeFilter != .waterOnly {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("🚻 廁所特定需求欄位")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                FilterToggleChip(
                                    title: "無障礙設施 ♿️",
                                    isOn: $viewModel.filterOptions.requireAccessible,
                                    activeColor: .purple
                                )
                                FilterToggleChip(
                                    title: "親子尿布台 👶",
                                    isOn: $viewModel.filterOptions.requireNursery,
                                    activeColor: .pink
                                )
                                FilterToggleChip(
                                    title: "性別友善廁 🚻",
                                    isOn: $viewModel.filterOptions.requireGenderFriendly,
                                    activeColor: .teal
                                )
                                FilterToggleChip(
                                    title: "配備免治馬桶 🚽",
                                    isOn: $viewModel.filterOptions.requireBidet,
                                    activeColor: .indigo
                                )
                                FilterToggleChip(
                                    title: "提供衛生紙 🧻",
                                    isOn: $viewModel.filterOptions.requireToiletPaper,
                                    activeColor: .brown
                                )
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 280)

            Divider()

            // 底部統計與收合按鈕
            HStack {
                Text("即時符合：\(viewModel.filteredFacilities.count) 個據點")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isAdvancedFilterExpanded = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("收合欄位表")
                        Image(systemName: "chevron.up")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.teal)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    // MARK: - 計算已生效的個別篩選項目
    private var activeFilterItems: [ActiveFilterItem] {
        var items: [ActiveFilterItem] = []

        if viewModel.filterOptions.typeFilter != .all {
            items.append(ActiveFilterItem(
                id: "type",
                label: viewModel.filterOptions.typeFilter.rawValue,
                removeAction: { viewModel.filterOptions.typeFilter = .all }
            ))
        }

        if viewModel.filterOptions.locationFilterMode == .byCity, let city = viewModel.filterOptions.selectedCity {
            items.append(ActiveFilterItem(
                id: "city",
                label: "📍 \(city.rawValue)",
                removeAction: { viewModel.filterOptions.selectedCity = nil }
            ))
        } else if viewModel.filterOptions.locationFilterMode == .byCategory, let cat = viewModel.filterOptions.selectedCategory {
            items.append(ActiveFilterItem(
                id: "cat",
                label: "🏢 \(cat.rawValue)",
                removeAction: { viewModel.filterOptions.selectedCategory = nil }
            ))
        }

        if viewModel.filterOptions.distanceLimit != .unlimited {
            items.append(ActiveFilterItem(
                id: "dist",
                label: viewModel.filterOptions.distanceLimit.label,
                removeAction: { viewModel.filterOptions.distanceLimit = .unlimited }
            ))
        }

        if viewModel.filterOptions.requireAccessible {
            items.append(ActiveFilterItem(
                id: "accessible",
                label: "♿️ 無障礙",
                removeAction: { viewModel.filterOptions.requireAccessible = false }
            ))
        }
        if viewModel.filterOptions.requireNursery {
            items.append(ActiveFilterItem(
                id: "nursery",
                label: "👶 尿布台",
                removeAction: { viewModel.filterOptions.requireNursery = false }
            ))
        }
        if viewModel.filterOptions.requireGenderFriendly {
            items.append(ActiveFilterItem(
                id: "gender",
                label: "🚻 性別友善",
                removeAction: { viewModel.filterOptions.requireGenderFriendly = false }
            ))
        }
        if viewModel.filterOptions.requireBidet {
            items.append(ActiveFilterItem(
                id: "bidet",
                label: "🚽 免治馬桶",
                removeAction: { viewModel.filterOptions.requireBidet = false }
            ))
        }
        if viewModel.filterOptions.requireToiletPaper {
            items.append(ActiveFilterItem(
                id: "paper",
                label: "🧻 衛生紙",
                removeAction: { viewModel.filterOptions.requireToiletPaper = false }
            ))
        }
        if viewModel.filterOptions.requireHotWater {
            items.append(ActiveFilterItem(
                id: "hot",
                label: "🔥 熱水",
                removeAction: { viewModel.filterOptions.requireHotWater = false }
            ))
        }
        if viewModel.filterOptions.requireWarmWater {
            items.append(ActiveFilterItem(
                id: "warm",
                label: "☕️ 溫水",
                removeAction: { viewModel.filterOptions.requireWarmWater = false }
            ))
        }
        if viewModel.filterOptions.requireColdWater {
            items.append(ActiveFilterItem(
                id: "cold",
                label: "❄️ 冰水",
                removeAction: { viewModel.filterOptions.requireColdWater = false }
            ))
        }
        if viewModel.filterOptions.requireCupFriendly {
            items.append(ActiveFilterItem(
                id: "cup",
                label: "🥤 自備杯",
                removeAction: { viewModel.filterOptions.requireCupFriendly = false }
            ))
        }

        return items
    }

    // MARK: - 設施清單內容
    private var facilityListContent: some View {
        List {
            Section(header: Text("符合條件共 \(viewModel.filteredFacilities.count) 個據點 (依距離排序)")) {
                ForEach(viewModel.filteredFacilities) { facility in
                    FacilityListRow(
                        facility: facility,
                        userLocation: viewModel.locationManager.userLocation,
                        activeFilter: viewModel.filterOptions.typeFilter,
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

    // MARK: - 無結果提示畫面
    private var emptyResultView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 54))
                .foregroundColor(.secondary.opacity(0.5))
            Text("找不到符合條件的設施")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("請嘗試清除搜尋文字或放寬多層篩選條件")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("清除所有篩選條件") {
                withAnimation {
                    viewModel.searchText = ""
                    viewModel.filterOptions.reset()
                }
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.teal.opacity(0.15))
            .foregroundColor(.teal)
            .cornerRadius(20)
            Spacer()
        }
    }
}

// MARK: - 輔助模型與子元件

struct ActiveFilterItem: Identifiable {
    let id: String
    let label: String
    let removeAction: () -> Void
}

/// Tier 1: 主類別按鈕
struct TypeSegmentButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption.bold())
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? activeColor : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
            .shadow(color: isSelected ? activeColor.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
    }
}

/// Tier 2: 情境需求標籤
struct FilterTagChip: View {
    let title: String
    let systemIcon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isSelected ? "checkmark" : systemIcon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
    }
}

/// Tier 3: 快速滑動藥丸
struct QuickPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 9))
                }
                Text(title)
                    .font(.caption2.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.primary : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? Color(.systemBackground) : .secondary)
            .cornerRadius(12)
        }
    }
}

struct FacilityListRow: View {
    let facility: Facility
    let userLocation: CLLocationCoordinate2D?
    var activeFilter: FacilityTypeFilter = .all
    let onTap: () -> Void
    let onNavigate: () -> Void
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
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // 圖標
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(displayType.themeColor.opacity(0.12))
                        .frame(width: 44, height: 44)

                    FacilityTypeIcon(type: displayType, size: 18)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(facility.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(facility.formattedDistance(from: userLocation))
                            .font(.caption.bold())
                            .foregroundColor(.teal)
                    }

                    Text(facility.floorDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(facility.category.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(4)

                        if facility.hasAccessibleToilet {
                            Text("無障礙")
                                .font(.caption2)
                                .foregroundColor(.purple)
                        }
                        if facility.hasHotWater {
                            Text("熱水")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        if facility.hasNurseryOrDiaper {
                            Text("尿布台")
                                .font(.caption2)
                                .foregroundColor(.pink)
                        }

                        if facility.activeIssueAlert != nil {
                            Text("⚠️ 異常警示")
                                .font(.caption2.bold())
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        Button(action: onNavigate) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.borderless)

                        Button(action: onToggleFavorite) {
                            Image(systemName: facility.isFavorite ? "heart.fill" : "heart")
                                .font(.caption)
                                .foregroundColor(facility.isFavorite ? .red : .gray)
                                .padding(6)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

/// 進階欄位表 Toggle 標籤元件
struct FilterToggleChip: View {
    let title: String
    @Binding var isOn: Bool
    var activeColor: Color = .teal

    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundColor(isOn ? activeColor : .secondary)
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(isOn ? .primary : .secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isOn ? activeColor.opacity(0.12) : Color(.tertiarySystemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isOn ? activeColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

