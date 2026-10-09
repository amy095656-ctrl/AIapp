import SwiftUI

struct ReportCenterView: View {
    @ObservedObject var viewModel: FacilityViewModel

    @State private var selectedTab: ReportCenterTab = .reportIssue

    // 問題回報表單狀態
    @State private var targetFacilitySearchText: String = ""
    @State private var selectedTargetFacilityId: UUID? = nil
    @State private var selectedIssueType: IssueType = .noToiletPaper
    @State private var selectedSeverity: IssueSeverity = .moderate
    @State private var commentText: String = ""
    @State private var hasPhotoAttached: Bool = false
    @State private var showIssueSuccessAlert: Bool = false

    // 提報新設施表單狀態
    @State private var newName: String = ""
    @State private var newAddress: String = ""
    @State private var newType: FacilityType = .both
    @State private var newCategory: LocationCategory = .park
    @State private var newFloorNote: String = ""

    // 飲水機功能配備（對應列表搜尋頁面篩選）
    @State private var newHasHotWater: Bool = true
    @State private var newHasWarmWater: Bool = true
    @State private var newHasColdWater: Bool = true
    @State private var newIsCupFriendly: Bool = true
    @State private var newIsFilterCertified: Bool = true

    // 廁所設施與衛生配備（對應列表搜尋頁面篩選）
    @State private var newHasAccessible: Bool = true
    @State private var newHasNursery: Bool = false
    @State private var newIsGenderFriendly: Bool = false
    @State private var newHasBidet: Bool = false
    @State private var newHasToiletPaper: Bool = true

    @State private var showNewFacilitySuccessAlert: Bool = false

    enum ReportCenterTab: String, CaseIterable, Identifiable {
        case reportIssue = "回報問題"
        case addNew = "提報新地點"
        case history = "回報紀錄"

        var id: String { rawValue }
    }

    var isIssueSubmitDisabled: Bool {
        if selectedIssueType == .other {
            return commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }

    // 依搜尋字串過濾的設施候選清單
    var candidateFacilities: [Facility] {
        if targetFacilitySearchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return Array(viewModel.facilities.prefix(8))
        } else {
            return viewModel.facilities.filter {
                $0.name.localizedCaseInsensitiveContains(targetFacilitySearchText) ||
                $0.address.localizedCaseInsensitiveContains(targetFacilitySearchText)
            }
        }
    }

    var selectedTargetFacility: Facility? {
        if let id = selectedTargetFacilityId {
            return viewModel.facilities.first(where: { $0.id == id })
        }
        return viewModel.selectedFacility ?? viewModel.facilities.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 頂部切換膠囊
                Picker("回報模式", selection: $selectedTab) {
                    ForEach(ReportCenterTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))

                Divider()

                // 主內容區域
                switch selectedTab {
                case .reportIssue:
                    issueReportingForm
                case .addNew:
                    newFacilityForm
                case .history:
                    reportsHistoryList
                }
            }
            .navigationTitle("回報中心")
            .navigationBarTitleDisplayMode(.inline)
            .alert("問題回報成功！", isPresented: $showIssueSuccessAlert) {
                Button("確定", role: .cancel) {
                    commentText = ""
                    selectedTab = .history
                }
            } message: {
                Text("感謝您的即時回報！「水便搜」已立即在該設施的地圖標註與詳情頁標上異常警示，並記錄於社群維護紀錄。")
            }
            .alert("新地點已送出！", isPresented: $showNewFacilitySuccessAlert) {
                Button("查看地圖", role: .cancel) {
                    newName = ""
                    newAddress = ""
                    newFloorNote = ""
                }
            } message: {
                Text("已成功將新設施加入您的「水便搜」本地圖資與審核佇列！")
            }
        }
    }

    // MARK: - 1. 設施問題回報表單
    private var issueReportingForm: some View {
        Form {
            Section(header: Text("選擇要回報的設施")) {
                if let target = selectedTargetFacility {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(target.type.themeColor.opacity(0.15))
                                .frame(width: 44, height: 44)

                            FacilityTypeIcon(type: target.type, size: 20)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(target.name)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text(target.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }

                // 搜尋選擇全台其他設施
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜尋全台其他設施更換目標...", text: $targetFacilitySearchText)
                }

                if !targetFacilitySearchText.isEmpty {
                    ForEach(candidateFacilities.prefix(5)) { f in
                        Button(action: {
                            selectedTargetFacilityId = f.id
                            targetFacilitySearchText = ""
                        }) {
                            HStack {
                                Text(f.name)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(f.category.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Section(header: Text("狀況與影響程度")) {
                Picker("問題類型", selection: $selectedIssueType) {
                    ForEach(IssueType.allCases) { issue in
                        Label(issue.rawValue, systemImage: issue.icon).tag(issue)
                    }
                }

                Picker("影響程度", selection: $selectedSeverity) {
                    ForEach(IssueSeverity.allCases) { sev in
                        Text(sev.rawValue).tag(sev)
                    }
                }
            }

            // 具體狀況說明 (點選「其他狀況反映」時為必填輸入)
            Section(header: Text(selectedIssueType == .other ? "請具體描述遇到的狀況 (必填)" : "補充狀況說明 (選填)")) {
                TextField(
                    selectedIssueType == .other ? "請在此詳細輸入您遇到的其他問題..." : "描述現場具體狀況（例如：2號隔間門鎖卡死、水龍頭漏水）...",
                    text: $commentText,
                    axis: .vertical
                )
                .lineLimit(3...5)

                if selectedIssueType == .other && commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("⚠️ 選擇「其他狀況反映」時，請務必填寫具體內容。")
                        .font(.caption2)
                        .foregroundColor(.red)
                }

                Button(action: {
                    hasPhotoAttached.toggle()
                }) {
                    HStack {
                        Image(systemName: hasPhotoAttached ? "checkmark.circle.fill" : "camera.fill")
                            .foregroundColor(hasPhotoAttached ? .green : .teal)
                        Text(hasPhotoAttached ? "已附加現場照片證明 (1張)" : "拍照或選取現場照片證明 (選填)")
                            .foregroundColor(hasPhotoAttached ? .green : .primary)
                        Spacer()
                        if hasPhotoAttached {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section {
                Button(action: submitIssue) {
                    HStack {
                        Spacer()
                        Text("確認送出問題回報")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .background(isIssueSubmitDisabled ? Color.gray : Color.orange)
                    .cornerRadius(12)
                }
                .disabled(isIssueSubmitDisabled)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }

    // MARK: - 2. 提報新增設施表單
    private var newFacilityForm: some View {
        Form {
            Section(header: Text("新設施基本資訊")) {
                TextField("設施名稱 (例如：中油XX站友善廁所)", text: $newName)
                TextField("所在地址或地標描述", text: $newAddress)

                Picker("設施類型", selection: $newType) {
                    ForEach(FacilityType.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }

                Picker("場所類別", selection: $newCategory) {
                    ForEach(LocationCategory.allCases) { c in
                        Label(c.rawValue, systemImage: c.systemIcon).tag(c)
                    }
                }
            }

            // 飲水機功能配備
            if newType == .waterDispenser || newType == .both {
                Section(header: Text("💧 飲水機功能配備")) {
                    Toggle("提供熱水 🔥", isOn: $newHasHotWater)
                    Toggle("提供溫水 ☕️", isOn: $newHasWarmWater)
                    Toggle("提供冰水 ❄️", isOn: $newHasColdWater)
                    Toggle("自備環保杯友善 🥤", isOn: $newIsCupFriendly)
                    Toggle("水質檢驗合格認證 🛡️", isOn: $newIsFilterCertified)
                }
            }

            // 廁所設施與衛生配備
            if newType == .toilet || newType == .both {
                Section(header: Text("🚻 廁所設施與衛生配備")) {
                    Toggle("具備無障礙設施 ♿️", isOn: $newHasAccessible)
                    Toggle("具備親子尿布台 👶", isOn: $newHasNursery)
                    Toggle("性別友善廁所 🚻", isOn: $newIsGenderFriendly)
                    Toggle("配備免治馬桶 🚽", isOn: $newHasBidet)
                    Toggle("提供衛生紙 🧻", isOn: $newHasToiletPaper)
                }
            }

            Section(header: Text("詳細指引與備註")) {
                TextField("詳細位置指引 (例如：位於後側停車場旁、需向店員借鑰匙)...", text: $newFloorNote, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                Button(action: submitNewFacility) {
                    HStack {
                        Spacer()
                        Text("送出新增提報並加入地圖")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .background(Color.teal)
                    .cornerRadius(12)
                }
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }

    // MARK: - 3. 我的回報紀錄清單 (已移除「解除異常」文字與按鈕)
    private var reportsHistoryList: some View {
        Group {
            if viewModel.reportedIssues.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 54))
                        .foregroundColor(.green.opacity(0.6))
                    Text("目前尚無問題回報紀錄")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("外出如遇衛生紙耗盡、飲水機故障或設施維修，可在此快速回報，協助全台民眾共同維護最新資訊。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                List {
                    Section(header: Text("已提交 \(viewModel.reportedIssues.count) 筆社群回報紀錄")) {
                        ForEach(viewModel.reportedIssues) { report in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Label(report.issueType.rawValue, systemImage: report.issueType.icon)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.orange)

                                    Spacer()

                                    Text(report.status.rawValue)
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.green.opacity(0.12))
                                        .foregroundColor(.green)
                                        .cornerRadius(6)
                                }

                                Text(report.facilityName)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                if !report.comment.isEmpty {
                                    Text("回報內容：\(report.comment)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text(report.formattedDate)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    if report.hasPhotoAttached {
                                        Text("• 附現場照片")
                                            .font(.caption2)
                                            .foregroundColor(.teal)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private func submitIssue() {
        guard let target = selectedTargetFacility else { return }
        viewModel.submitReport(
            facility: target,
            issueType: selectedIssueType,
            severity: selectedSeverity,
            rating: 5,
            comment: commentText,
            hasPhoto: hasPhotoAttached
        )
        showIssueSuccessAlert = true
    }

    private func submitNewFacility() {
        viewModel.reportNewFacility(
            name: newName,
            address: newAddress.isEmpty ? "台灣指定地點" : newAddress,
            type: newType,
            category: newCategory,
            note: newFloorNote,
            hasAccessibleToilet: newType != .waterDispenser && newHasAccessible,
            hasNurseryOrDiaper: newType != .waterDispenser && newHasNursery,
            isGenderFriendly: newType != .waterDispenser && newIsGenderFriendly,
            hasBidet: newType != .waterDispenser && newHasBidet,
            hasToiletPaper: newType != .waterDispenser && newHasToiletPaper,
            hasHotWater: newType != .toilet && newHasHotWater,
            hasWarmWater: newType != .toilet && newHasWarmWater,
            hasColdWater: newType != .toilet && newHasColdWater,
            isCupFriendly: newType != .toilet && newIsCupFriendly,
            isFilterCertified: newType != .toilet && newIsFilterCertified
        )
        showNewFacilitySuccessAlert = true
    }
}
