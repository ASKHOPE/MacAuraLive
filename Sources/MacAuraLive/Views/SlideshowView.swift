import SwiftUI

public struct SlideshowView: View {
    @ObservedObject var slideshow = SlideshowManager.shared
    @ObservedObject var storage = WallpaperStorageManager.shared

    // Form inputs for creating a new scheduled rule
    @State private var newTime: Date = Date()
    @State private var selectedWallpaperId: String = ""
    @State private var newLabel: String = ""
    @State private var showAddSheet: Bool = false

    @State private var searchText: String = ""
    @State private var thumbnailWidth: CGFloat = 130

    private var filteredWallpapers: [WallpaperItem] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if text.isEmpty {
            return storage.wallpapers
        } else {
            return storage.wallpapers.filter {
                $0.title.lowercased().contains(text) ||
                $0.category.lowercased().contains(text) ||
                $0.type.rawValue.lowercased().contains(text)
            }
        }
    }

    private let availableIntervals: [(label: String, seconds: Double)] = [
        ("30 Seconds (Testing)", 30),
        ("1 Minute", 60),
        ("5 Minutes", 300),
        ("15 Minutes", 900),
        ("30 Minutes", 1800),
        ("1 Hour", 3600),
        ("3 Hours", 10800),
        ("6 Hours", 21600),
        ("12 Hours", 43200),
        ("24 Hours (Daily)", 86400)
    ]

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Slideshow & Scheduled Rotation")
                    .font(.system(size: 28, weight: .bold))
                Text("Automate your wallpaper changes with interval slideshows or time-of-day schedules.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Card 1: Interval Slideshow Settings ───────────────────
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Interval Slideshow Engine")
                                    .font(.title3)
                                    .bold()
                                Text("Automatically rotate active wallpaper on a fixed timer.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $slideshow.isSlideshowEnabled)
                                .toggleStyle(.switch)
                        }

                        if slideshow.isSlideshowEnabled {
                            Divider()

                            // Interval Selector
                            HStack(spacing: 16) {
                                Text("Rotation Frequency:")
                                    .font(.subheadline)
                                    .bold()

                                Picker("", selection: $slideshow.intervalSeconds) {
                                    ForEach(availableIntervals, id: \.seconds) { item in
                                        Text(item.label).tag(item.seconds)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 220)

                                Spacer()

                                Button {
                                    slideshow.rotateWallpaper()
                                } label: {
                                    Label("Rotate Now", systemImage: "forward.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                            }

                            // Shuffle Option
                            Toggle(isOn: $slideshow.isShuffleEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Shuffle Mode")
                                        .font(.subheadline)
                                        .bold()
                                    Text("Pick wallpapers randomly instead of sequential order.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Active Timer Indicator
                            if let nextDate = slideshow.nextRotationDate {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.2.circlepath")
                                        .foregroundColor(.cyan)
                                    Text("Next rotation scheduled for:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(nextDate, style: .time)
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.cyan)
                                }
                                .padding(10)
                                .background(Color.cyan.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    // ── Card 2: Slideshow Playlist Image Picker ──────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Slideshow Playlist Selection")
                                    .font(.title3)
                                    .bold()
                                let count = slideshow.includedWallpaperIds.isEmpty ? storage.wallpapers.count : slideshow.includedWallpaperIds.count
                                Text("Selected \(count) of \(storage.wallpapers.count) wallpapers for rotation.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()

                            Button("Select All") {
                                slideshow.selectAllWallpapers()
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)

                            Button("Clear Selection") {
                                slideshow.clearPlaylist()
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                        }

                        // Search Bar & Thumbnail Size Slider Row
                        HStack(spacing: 16) {
                            // Search Field
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                TextField("Search by title, category, or type...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .font(.caption)
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .frame(maxWidth: 280)

                            Spacer()

                            // Thumbnail Zoom Size Slider
                            HStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Slider(value: $thumbnailWidth, in: 90...220)
                                    .frame(width: 110)
                                    .controlSize(.small)

                                Image(systemName: "photo.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        if filteredWallpapers.isEmpty {
                            Text(searchText.isEmpty ? "No wallpapers found in library." : "No wallpapers match '\(searchText)'.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(filteredWallpapers) { item in
                                        PlaylistThumbnailCard(item: item, cardWidth: thumbnailWidth)
                                    }
                                }
                                .padding(.horizontal, 2)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                    // ── Card 2: Time-Based Scheduled Rules ────────────────────
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time-of-Day Rotation Schedules")
                                    .font(.title3)
                                    .bold()
                                Text("Trigger specific wallpapers at exact times (e.g., Morning, Sunset, Night).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                if selectedWallpaperId.isEmpty, let first = storage.wallpapers.first {
                                    selectedWallpaperId = first.id
                                }
                                showAddSheet = true
                            } label: {
                                Label("Add Time Rule", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        }

                        Divider()

                        if slideshow.scheduleRules.isEmpty {
                            Text("No time-based rules defined yet. Click 'Add Time Rule' above to create one.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(slideshow.scheduleRules) { rule in
                                    HStack(spacing: 16) {
                                        // Time Badge
                                        Text(rule.timeString)
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.purple.opacity(0.2))
                                            .foregroundColor(.purple)
                                            .cornerRadius(8)

                                        // Label & Wallpaper Title
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(rule.label)
                                                .font(.subheadline)
                                                .bold()
                                            let wpTitle = storage.wallpapers.first(where: { $0.id == rule.wallpaperId })?.title ?? rule.wallpaperId
                                            Text("Wallpaper: \(wpTitle)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        // Enable Toggle
                                        Toggle("", isOn: Binding(
                                            get: { rule.isEnabled },
                                            set: { _ in slideshow.toggleRule(id: rule.id) }
                                        ))
                                        .toggleStyle(.switch)

                                        // Delete Button
                                        Button {
                                            slideshow.deleteRule(id: rule.id)
                                        } label: {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.red.opacity(0.8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Add Time-Based Schedule Rule")
                    .font(.headline)

                TextField("Rule Label (e.g. Morning Glow)", text: $newLabel)
                    .textFieldStyle(.roundedBorder)

                DatePicker("Trigger Time:", selection: $newTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.field)

                Picker("Select Wallpaper:", selection: $selectedWallpaperId) {
                    ForEach(storage.wallpapers) { item in
                        Text(item.title).tag(item.id)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Button("Cancel") {
                        showAddSheet = false
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Save Schedule") {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        let timeStr = formatter.string(from: newTime)
                        let labelToUse = newLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Scheduled Wallpaper" : newLabel
                        slideshow.addRule(timeString: timeStr, wallpaperId: selectedWallpaperId, label: labelToUse)
                        newLabel = ""
                        showAddSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(selectedWallpaperId.isEmpty)
                }
            }
            .padding(24)
            .frame(width: 380)
        }
    }
}

// MARK: - Playlist Thumbnail Selection Card

private struct PlaylistThumbnailCard: View {
    @ObservedObject var slideshow = SlideshowManager.shared
    let item: WallpaperItem
    var cardWidth: CGFloat = 130

    var body: some View {
        let isIncluded = slideshow.isWallpaperIncluded(id: item.id)
        let cardHeight = cardWidth * 0.66

        Button {
            slideshow.toggleWallpaperInSlideshow(id: item.id)
        } label: {
            ZStack(alignment: .topTrailing) {
                // Thumbnail preview box
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: cardWidth, height: cardHeight)

                        if item.type == .image, let img = ImageCache.shared.image(forPath: item.pathOrUrl) {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: cardWidth, height: cardHeight)
                                .cornerRadius(10)
                                .clipped()
                        } else {
                            Image(systemName: item.thumbnailIcon)
                                .font(.system(size: cardWidth * 0.22))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }

                    Text(item.title)
                        .font(.system(size: max(9, cardWidth * 0.085), weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(width: cardWidth)
                }

                // Selection Badge
                ZStack {
                    Circle()
                        .fill(isIncluded ? Color.green : Color.black.opacity(0.6))
                        .frame(width: 24, height: 24)
                    Image(systemName: isIncluded ? "checkmark" : "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(6)
            }
            .padding(6)
            .background(isIncluded ? Color.green.opacity(0.1) : Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isIncluded ? Color.green.opacity(0.6) : Color.white.opacity(0.1), lineWidth: isIncluded ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
