import SwiftUI

struct ReportIssueView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FacilityViewModel
    let facility: Facility

    @State private var selectedIssueType: IssueType = .noToiletPaper
    @State private var selectedSeverity: IssueSeverity = .moderate
    @State private var commentText: String = ""
    @State private var hasPhotoAttached: Bool = false
    @State private var showSuccessAlert: Bool = false

    var isSubmitDisabled: Bool {
        if selectedIssueType == .other {
            return commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                // 1. 設施基本資訊
                Section(header: Text("回報設施")) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(facility.type.themeColor.opacity(0.15))
                                .frame(width: 44, height: 44)

                            FacilityTypeIcon(type: facility.type, size: 20)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(facility.name)
                                .font(.headline)
                            Text(facility.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    if let activeAlert = facility.activeIssueAlert {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("目前有未解除警示：\(activeAlert)")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 2)
                    }
                }

                // 2. 狀況類型與嚴重程度
                Section(header: Text("問題類型")) {
                    Picker("狀況類型", selection: $selectedIssueType) {
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

                // 3. 具體狀況說明 (點選其他狀況時必填)
                Section(header: Text(selectedIssueType == .other ? "請具體說明發生的問題狀況 (必填)" : "補充資訊說明 (選填)")) {
                    TextField(
                        selectedIssueType == .other ? "請詳細描述您遇到的問題（例如：門鎖卡住、異味嚴重、地磚濕滑）..." : "描述現場具體狀況（例如：2 號隔間門鎖損壞、熱水無法出水）...",
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
                            Text(hasPhotoAttached ? "已附加現場照片 (1張)" : "拍照或選取現場照片證明 (選填)")
                                .foregroundColor(hasPhotoAttached ? .green : .primary)
                            Spacer()
                            if hasPhotoAttached {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // 4. 送出按鈕
                Section {
                    Button(action: submitReport) {
                        HStack {
                            Spacer()
                            Text("確認送出回報")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .background(isSubmitDisabled ? Color.gray : Color.orange)
                        .cornerRadius(10)
                    }
                    .disabled(isSubmitDisabled)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("回報設施問題")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("回報成功！", isPresented: $showSuccessAlert) {
                Button("確定") { dismiss() }
            } message: {
                Text("感謝您的即時回報！該設施的狀態已即時在「水便搜」地圖與清單中更新，提醒其他使用者。")
            }
        }
    }

    private func submitReport() {
        viewModel.submitReport(
            facility: facility,
            issueType: selectedIssueType,
            severity: selectedSeverity,
            rating: 5,
            comment: commentText,
            hasPhoto: hasPhotoAttached
        )
        showSuccessAlert = true
    }
}
