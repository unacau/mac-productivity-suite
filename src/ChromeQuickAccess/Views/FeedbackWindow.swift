import SwiftUI
import AppKit

public struct FeedbackWindowView: View {
    @State private var zipURL: URL? = nil
    @State private var isPreparingArchive: Bool = true
    @State private var errorMessage: String? = nil
    @State private var copiedNotice: Bool = false

    private let telegramSupportURL = URL(string: "https://t.me/xomsky_app")!

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "ladybug.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Report an Issue")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Zero-telemetry diagnostics. Inspect or share on your terms.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Divider()

            // Diagnostic File Card with Drag and Drop
            VStack(spacing: 12) {
                if isPreparingArchive {
                    ProgressView("Packaging diagnostics...")
                        .frame(height: 90)
                } else if let zipURL = zipURL {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.zipper")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.orange)

                        Text("xomsky-diagnostic.zip")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))

                        Text("Drag & drop this file directly into Telegram, WhatsApp, or Finder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .onDrag {
                        NSItemProvider(contentsOf: zipURL) ?? NSItemProvider()
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 90)
                }
            }

            // Action Buttons
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Button(action: openTelegram) {
                        Label("Telegram Chat", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(action: openGitHub) {
                        Label("GitHub Issue", systemImage: "arrow.up.forward.app")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                HStack(spacing: 12) {
                    Button(action: revealInFinder) {
                        Label("Show in Finder", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                    .disabled(zipURL == nil)

                    Button(action: copyDiagnosticsToClipboard) {
                        Label(copiedNotice ? "Copied! ✅" : "Copy Raw Log", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(22)
        .frame(width: 460)
        .onAppear {
            generateArchive()
        }
    }

    private func generateArchive() {
        Task { @MainActor in
            do {
                let url = try DiagnosticBundleService.createDiagnosticArchive()
                self.zipURL = url
                self.isPreparingArchive = false
            } catch {
                self.errorMessage = "Failed to bundle diagnostics: \(error.localizedDescription)"
                self.isPreparingArchive = false
            }
        }
    }

    private func openTelegram() {
        NSWorkspace.shared.open(telegramSupportURL)
    }

    private func openGitHub() {
        if let ghURL = DiagnosticBundleService.makeGitHubIssueURL() {
            NSWorkspace.shared.open(ghURL)
        }
    }

    private func revealInFinder() {
        guard let zipURL = zipURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([zipURL])
    }

    private func copyDiagnosticsToClipboard() {
        let text = TelemetryBuffer.shared.exportTimelineText()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        withAnimation {
            copiedNotice = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                copiedNotice = false
            }
        }
    }
}
