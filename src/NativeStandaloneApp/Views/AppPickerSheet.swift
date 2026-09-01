import SwiftUI
import Cocoa

struct AppPickerItem: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let icon: NSImage
    let targetId: String
    let isChromeProfile: Bool
}

public struct AppPickerSheet: View {
    @ObservedObject var discovery = AppDiscoveryService.shared
    @Binding var isPresented: Bool
    var onSelect: (String) -> Void
    
    @State private var searchText: String = ""
    @State private var selectedTargetId: String?
    
    var items: [AppPickerItem] {
        var list: [AppPickerItem] = []
        
        // Add Chrome Profiles
        for p in ChromeProfileHelper.shared.profiles {
            let icon = p.avatarImage ?? AppDiscoveryService.shared.iconForApp(nameOrBundle: "Google Chrome")
            list.append(AppPickerItem(
                name: p.name,
                subtitle: p.email ?? "Chrome Profile (\(p.dir))",
                icon: icon,
                targetId: "chrome-profile:\(p.dir)",
                isChromeProfile: true
            ))
        }
        
        // Add Apps
        for app in discovery.search(query: searchText) {
            let icon = discovery.iconForApp(nameOrBundle: app.name)
            list.append(AppPickerItem(
                name: app.name,
                subtitle: app.bundleID.isEmpty ? app.path : app.bundleID,
                icon: icon,
                targetId: app.name,
                isChromeProfile: false
            ))
        }
        
        if searchText.isEmpty {
            return list
        } else {
            let lowerQuery = searchText.lowercased()
            return list.filter { $0.name.lowercased().contains(lowerQuery) || $0.subtitle.lowercased().contains(lowerQuery) }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(.blue)
                Text("Select Application or Profile")
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
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search apps or Chrome profiles...", text: $searchText)
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
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(items) { item in
                        AppRowView(
                            item: item,
                            isSelected: selectedTargetId == item.targetId,
                            onSelect: {
                                selectedTargetId = item.targetId
                            },
                            onDoubleSelect: {
                                onSelect(item.targetId)
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
                
                Button("Choose") {
                    if let t = selectedTargetId {
                        onSelect(t)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedTargetId == nil)
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
    let item: AppPickerItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onDoubleSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .clipShape(item.isChromeProfile ? AnyShape(Circle()) : AnyShape(Rectangle()))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                
                Text(item.subtitle)
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
