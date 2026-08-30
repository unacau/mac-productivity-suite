import SwiftUI
import Cocoa

public struct AppPickerSheet: View {
    @ObservedObject var discovery = AppDiscoveryService.shared
    @Binding var isPresented: Bool
    var onSelect: (String) -> Void
    
    @State private var searchText: String = ""
    @State private var selectedApp: DiscoveredApp?
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(.blue)
                Text("Select Application")
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            Divider()
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search installed applications...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            // App List
            let filteredApps = discovery.search(query: searchText)
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredApps) { app in
                        AppRowView(
                            app: app,
                            isSelected: selectedApp?.id == app.id,
                            onSelect: {
                                selectedApp = app
                            },
                            onDoubleSelect: {
                                onSelect(app.name)
                                isPresented = false
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .frame(maxHeight: 320)
            
            Divider()
            
            // Footer & Actions
            HStack {
                Button("Browse Other App...") {
                    browseCustomApp()
                }
                .buttonStyle(.link)
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Choose Application") {
                    if let app = selectedApp {
                        onSelect(app.name)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedApp == nil)
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 480, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func browseCustomApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        if panel.runModal() == .OK, let url = panel.url {
            let appName = url.deletingPathExtension().lastPathComponent
            onSelect(appName)
            isPresented = false
        }
    }
}

struct AppRowView: View {
    let app: DiscoveredApp
    let isSelected: Bool
    let onSelect: () -> Void
    let onDoubleSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: AppDiscoveryService.shared.iconForApp(nameOrBundle: app.name))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                
                Text(app.bundleID.isEmpty ? app.path : app.bundleID)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleSelect()
        }
        .onTapGesture(count: 1) {
            onSelect()
        }
    }
}
