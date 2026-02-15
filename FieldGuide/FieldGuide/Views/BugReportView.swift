//
//  BugReportView.swift
//  FieldGuide
//

import SwiftUI
import UIKit

struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var descriptionText = ""
    @State private var hasSubmitted = false

    private static let discordURL = "https://discord.gg/PqubUxWW62"

    private var deviceInfo: DeviceInfo {
        DeviceInfo()
    }

    private var reportBody: String {
        """
        **Bug Report**

        **Description:**
        \(descriptionText.isEmpty ? "(No description provided)" : descriptionText)

        **Device Info:**
        - App Version: \(deviceInfo.appVersion)
        - iOS Version: \(deviceInfo.iosVersion)
        - Device: \(deviceInfo.deviceModel)
        """
    }

    var body: some View {
        NavigationStack {
            Form {
                if !hasSubmitted {
                    descriptionSection
                    infoSection
                } else {
                    resultSection
                }
            }
            .navigationTitle("Report a Bug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(hasSubmitted ? "Done" : "Cancel") { dismiss() }
                }
                if !hasSubmitted {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") { submitReport() }
                    }
                }
            }
        }
    }

    private var descriptionSection: some View {
        SwiftUI.Section {
            TextField("Describe what happened...", text: $descriptionText, axis: .vertical)
                .lineLimit(5 ... 10)
        } header: {
            Text("Description")
        }
    }

    private var infoSection: some View {
        SwiftUI.Section {
            DisclosureGroup("Report includes...") {
                LabeledContent("Version", value: deviceInfo.appVersion)
                LabeledContent("iOS", value: deviceInfo.iosVersion)
                LabeledContent("Device", value: deviceInfo.deviceModel)
            }
        }
    }

    private var resultSection: some View {
        SwiftUI.Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Report Copied", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)

                Text(
                    "Your bug report has been copied to the clipboard. "
                        + "Please paste it in the **#bug-reports** channel on Discord."
                )
                .font(.subheadline)

                Text("Please include screenshots detailing the issue.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Open Discord") {
                    if let url = URL(string: Self.discordURL) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding(.vertical, 8)
        }
    }

    private func submitReport() {
        UIPasteboard.general.string = reportBody
        hasSubmitted = true
    }
}

// MARK: - DeviceInfo

private struct DeviceInfo {
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var iosVersion: String {
        UIDevice.current.systemVersion
    }

    var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}

#Preview {
    BugReportView()
}
