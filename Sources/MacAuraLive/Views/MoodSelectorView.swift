import SwiftUI
import AppKit

public struct MoodSelectorView: View {
    @ObservedObject var moodManager = MoodProfileManager.shared
    @ObservedObject var storage = WallpaperStorageManager.shared
    @State private var showingCreateSheet: Bool = false
    @State private var moodToEdit: MoodProfile? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Moods & Profiles")
                        .font(.system(size: 26, weight: .bold))
                    Text("Custom wallpaper templates that automatically adapt to your mindset and macOS Focus/Sleep modes.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // macOS Mode Sync Toggle
                HStack(spacing: 12) {
                    MacaRetroToggle("macOS Sync", isOn: $moodManager.isSyncEnabled)
                        .help("Automatically switch mood when macOS changes Focus mode, DND, or Sleep state.")
                    
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Label("New Mood", systemImage: "plus.circle.fill")
                    }
                    .macaButtonStyle(.primary)
                }
            }
            
            // Sync status banner if triggered
            if let reason = moodManager.lastTriggeredReason {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                    Text("Auto-switched via macOS event: \(reason)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Dismiss") {
                        moodManager.lastTriggeredReason = nil
                    }
                    .font(.caption2)
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .macaSubcardStyle(cornerRadius: 8)
            }
            
            // Moods Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 360), spacing: 18)], spacing: 18) {
                    ForEach(moodManager.moods) { mood in
                        MoodCard(
                            mood: mood,
                            isActive: moodManager.activeMoodId == mood.id,
                            onActivate: {
                                moodManager.activateMood(mood)
                            },
                            onEdit: {
                                moodToEdit = mood
                            },
                            onDuplicate: {
                                moodManager.duplicateMood(mood)
                            },
                            onDelete: {
                                moodManager.deleteMood(id: mood.id)
                            }
                        )
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(24)
        .sheet(isPresented: $showingCreateSheet) {
            MoodEditorSheet(existingMood: nil) { newMood in
                moodManager.addMood(newMood)
            }
        }
        .sheet(item: $moodToEdit) { mood in
            MoodEditorSheet(existingMood: mood) { updatedMood in
                moodManager.updateMood(updatedMood)
            }
        }
    }
}

// MARK: - Mood Card View

struct MoodCard: View {
    let mood: MoodProfile
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top Row: Icon + Name + Active Status Badge
            let accentColor = Color(hex: mood.accentColorHex) ?? .purple
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppSettings.shared.appTheme == "classic" ? 4 : 12)
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: mood.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mood.name)
                        .font(.system(size: 16, weight: .bold))
                    Text("\(mood.wallpaperIDs.count) Wallpapers • \(mood.playbackMode.rawValue)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(AppSettings.shared.appTheme == "classic" ? 3 : 12)
                }
            }
            
            // Description
            if !mood.description.isEmpty {
                Text(mood.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Linked Trigger Tag
            if mood.linkedMode != .none {
                HStack(spacing: 6) {
                    Image(systemName: mood.linkedMode.iconName)
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("Trigger: \(mood.linkedMode.rawValue)")
                        .font(.caption2)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .macaSubcardStyle(cornerRadius: 6)
            }
            
            Divider()
            
            // Bottom Action Controls
            HStack(spacing: 8) {
                Button(action: onActivate) {
                    Label(isActive ? "Active Mood" : "Apply Mood", systemImage: isActive ? "checkmark.circle.fill" : "play.fill")
                }
                .macaButtonStyle(.primary, size: .small)
                .disabled(isActive)
                
                Spacer(minLength: 6)
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit Template", systemImage: "pencil")
                    }
                    Button(action: onDuplicate) {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    Divider()
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(MacaThemeTokens.classicTextDark)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(MacaThemeTokens.classicButtonBg)
                        .macaItemRadius(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSettings.shared.appTheme == "classic" ? 2 : 4)
                                .stroke(MacaThemeTokens.classicBorder, lineWidth: 1)
                        )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(16)
        .macaCardStyle(cornerRadius: 14)
    }
}

// MARK: - Mood Editor Sheet

struct MoodEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    let existingMood: MoodProfile?
    let onSave: (MoodProfile) -> Void
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var icon: String = "sparkles"
    @State private var accentColorHex: String = "#3B82F6"
    @State private var selectedWallpaperIDs: Set<String> = []
    @State private var playbackMode: MoodPlaybackMode = .single
    @State private var cycleIntervalMinutes: Double = 15.0
    @State private var isMuted: Bool = false
    @State private var linkedMode: LinkedMacOSMode = .none
    
    private let availableIcons = ["sparkles", "brain.head.profile", "moon.stars.fill", "sun.max.fill", "sparkles.tv", "laptopcomputer", "gamecontroller.fill", "headphones", "cup.and.saucer.fill", "bolt.fill"]
    private let availableColors = ["#3B82F6", "#8B5CF6", "#EC4899", "#F59E0B", "#10B981", "#6366F1", "#EF4444"]
    
    init(existingMood: MoodProfile?, onSave: @escaping (MoodProfile) -> Void) {
        self.existingMood = existingMood
        self.onSave = onSave
        
        if let existing = existingMood {
            _name = State(initialValue: existing.name)
            _description = State(initialValue: existing.description)
            _icon = State(initialValue: existing.icon)
            _accentColorHex = State(initialValue: existing.accentColorHex)
            _selectedWallpaperIDs = State(initialValue: Set(existing.wallpaperIDs))
            _playbackMode = State(initialValue: existing.playbackMode)
            _cycleIntervalMinutes = State(initialValue: existing.cycleIntervalMinutes)
            _isMuted = State(initialValue: existing.isMuted ?? false)
            _linkedMode = State(initialValue: existing.linkedMode)
        }
    }
    
    var body: some View {
        let isClassic = AppSettings.shared.appTheme == "classic"
        
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                Text(existingMood == nil ? "Create Custom Mood" : "Edit Mood Template")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Cancel") { dismiss() }
                    .macaButtonStyle(.secondary)
                    .keyboardShortcut(.cancelAction)
                Button("Save Mood") {
                    let mood = MoodProfile(
                        id: existingMood?.id ?? UUID().uuidString,
                        name: name.isEmpty ? "New Mood" : name,
                        description: description,
                        icon: icon,
                        accentColorHex: accentColorHex,
                        wallpaperIDs: Array(selectedWallpaperIDs),
                        playbackMode: playbackMode,
                        cycleIntervalMinutes: cycleIntervalMinutes,
                        isMuted: isMuted,
                        linkedMode: linkedMode,
                        isBuiltIn: false
                    )
                    onSave(mood)
                    dismiss()
                }
                .macaButtonStyle(.primary)
                .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Name & Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mood Name & Tagline").font(.caption).bold()
                        TextField("e.g. Deep Coding, Relaxing Rain, Nightshift", text: $name)
                            .textFieldStyle(.roundedBorder)
                        TextField("Description of what this mood is for", text: $description)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Icon & Accent Color Row
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Icon").font(.caption).bold()
                            HStack(spacing: 8) {
                                ForEach(availableIcons, id: \.self) { sym in
                                    Image(systemName: sym)
                                        .font(.system(size: 16))
                                        .frame(width: 32, height: 32)
                                        .background(icon == sym ? (isClassic ? MacaThemeTokens.classicOlive.opacity(0.2) : Color.accentColor.opacity(0.2)) : Color.clear)
                                        .macaItemRadius(4)
                                        .overlay(RoundedRectangle(cornerRadius: isClassic ? 2 : 6).stroke(icon == sym ? (isClassic ? MacaThemeTokens.classicOlive : Color.accentColor) : Color.gray.opacity(0.3)))
                                        .onTapGesture { icon = sym }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Accent Color").font(.caption).bold()
                            HStack(spacing: 8) {
                                ForEach(availableColors, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex) ?? .blue)
                                        .frame(width: 24, height: 24)
                                        .overlay(Circle().stroke(accentColorHex == hex ? (isClassic ? MacaThemeTokens.classicTextDark : Color.white) : Color.clear, lineWidth: 2))
                                        .shadow(radius: accentColorHex == hex ? 2 : 0)
                                        .onTapGesture { accentColorHex = hex }
                                }
                            }
                        }
                    }
                    
                    // macOS Sync Link Dropdown
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Linked macOS Trigger").font(.caption).bold()
                        Picker("Trigger on macOS Event:", selection: $linkedMode) {
                            ForEach(LinkedMacOSMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Playback & Timing
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Playback Mode").font(.caption).bold()
                            HStack(spacing: 4) {
                                ForEach(MoodPlaybackMode.allCases, id: \.self) { mode in
                                    let isSel = playbackMode == mode
                                    Button(action: { playbackMode = mode }) {
                                        Text(mode.rawValue)
                                            .font(.system(size: 11, weight: isSel ? .bold : .medium, design: isClassic ? .monospaced : .default))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(
                                                isSel
                                                    ? (isClassic ? MacaThemeTokens.classicOlive : Color.accentColor)
                                                    : (isClassic ? MacaThemeTokens.classicButtonBg : Color(NSColor.controlBackgroundColor))
                                            )
                                            .foregroundColor(isSel ? .white : (isClassic ? MacaThemeTokens.classicTextDark : .primary))
                                            .macaItemRadius(3)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: isClassic ? 2 : 3)
                                                    .stroke(isClassic ? MacaThemeTokens.classicBorder : Color.clear, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        MacaRetroToggle("Mute Audio", isOn: $isMuted)
                            .padding(.top, 14)
                    }
                    
                    // Wallpaper Selection List
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Wallpapers in this Mood (\(selectedWallpaperIDs.count) selected)")
                            .font(.caption).bold()
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 10)], spacing: 10) {
                            ForEach(WallpaperStorageManager.shared.wallpapers) { item in
                                let isSelected = selectedWallpaperIDs.contains(item.id)
                                VStack(alignment: .leading, spacing: 4) {
                                    ZStack(alignment: .topTrailing) {
                                        RoundedRectangle(cornerRadius: isClassic ? 2 : 8)
                                            .fill(isClassic ? MacaThemeTokens.classicSubcardBg : Color.gray.opacity(0.15))
                                            .frame(height: 80)
                                        
                                        Image(systemName: item.thumbnailIcon)
                                            .font(.system(size: 24))
                                            .foregroundColor(isClassic ? MacaThemeTokens.classicTextDark : .secondary)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(isClassic ? MacaThemeTokens.classicOlive : .blue)
                                                .padding(6)
                                        }
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: isClassic ? 2 : 8)
                                            .stroke(isSelected ? (isClassic ? MacaThemeTokens.classicOlive : Color.blue) : (isClassic ? MacaThemeTokens.classicBorder : Color.clear), lineWidth: 1.5)
                                    )
                                    
                                    Text(item.title)
                                        .font(.system(size: 11, design: isClassic ? .monospaced : .default))
                                        .lineLimit(1)
                                }
                                .onTapGesture {
                                    if isSelected {
                                        selectedWallpaperIDs.remove(item.id)
                                    } else {
                                        selectedWallpaperIDs.insert(item.id)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 520)
        .background(isClassic ? MacaThemeTokens.classicCanvas : Color(NSColor.windowBackgroundColor))
    }
}
