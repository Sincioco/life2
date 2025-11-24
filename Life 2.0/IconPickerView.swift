// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                         Life 2.0 - Icon Picker View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 22, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Allow the user to pick an Icon symbol for their activity.
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation
import SwiftUI
import UIKit

// MARK: - Models

struct SymbolItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

enum IconCategory: String, CaseIterable, Identifiable {
    case recent
    case all
    case school
    case work
    case exercise
    case lifestyle
    case sports
    case tech
    case family
    case mindfulness
    case people
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .recent:      return "Recent"
        case .all:         return "All"
        case .school:      return "School"
        case .work:        return "Work"
        case .exercise:    return "Exercise"
        case .lifestyle:   return "Lifestyle"
        case .sports:      return "Sports"
        case .tech:        return "Tech"
        case .family:      return "Family"
        case .mindfulness: return "Mind"
        case .people:      return "People"
        }
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    
    @State private var searchText: String = ""
    @State private var allSymbols: [SymbolItem] = []
    @State private var recentIcons: [String] = []
    
    @State private var selectedCategory: IconCategory = .all
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // Persist recent icon names (comma-separated)
    @AppStorage("recentIconNames") private var recentIconNamesStorage: String = ""
    
    // MARK: Category symbol lists (~30 each)

    private let schoolSymbols = [
        "book", "book.fill", "book.closed", "book.closed.fill",
        "text.book.closed", "text.book.closed.fill",
        "graduationcap", "graduationcap.fill",
        "pencil", "pencil.circle", "pencil.circle.fill",
        "pencil.and.outline",
        "highlighter",
        "paperplane", "paperplane.fill",
        "lasso",
        "folder", "folder.fill",
        "doc", "doc.fill",
        "doc.text", "doc.text.fill",
        "doc.richtext", "doc.richtext.fill",
        "text.alignleft", "text.aligncenter",
        "text.alignright", "text.justify",
        "studentdesk",
        "brain.head.profile"
    ]
    
    private let workSymbols = [
        "briefcase", "briefcase.fill",
        "calendar", "calendar.badge.clock", "calendar.badge.exclamationmark",
        "clock", "alarm",
        "hourglass", "hourglass.bottomhalf.filled",
        "chart.bar", "chart.bar.fill",
        "chart.line.uptrend.xyaxis", "chart.xyaxis.line",
        "list.bullet", "list.bullet.rectangle.portrait", "checklist",
        "tray", "tray.fill", "tray.full", "tray.full.fill",
        "folder", "folder.fill",
        "doc.badge.gearshape", "doc.text.magnifyingglass",
        "envelope", "envelope.fill",
        "paperclip", "paperclip.circle", "paperclip.circle.fill",
        "person.text.rectangle"
    ]
    
    private let exerciseSymbols = [
        "figure.walk", "figure.walk.circle", "figure.walk.circle.fill",
        "figure.run", "figure.run.circle", "figure.run.circle.fill",
        "figure.strengthtraining.traditional",
        "figure.core.training",
        "figure.flexibility",
        "figure.cooldown",
        "figure.indoor.cycle",
        "bicycle",
        "flame", "flame.fill",
        "heart", "heart.fill", "bolt.heart",
        "sportscourt", "sportscourt.fill",
        "dumbbell", "dumbbell.fill",
        "figure.mind.and.body",
        "figure.yoga", "figure.pilates",
        "shoeprints.fill",
        "lungs.fill",
        "speedometer",
        "stopwatch",
        "figure.stairs",
        "medal.fill"
    ]
    
    private let lifestyleSymbols = [
        "sun.max", "sun.max.fill",
        "moon.stars", "moon.stars.fill",
        "house", "house.fill", "house.and.flag",
        "bed.double", "bed.double.fill",
        "sofa.fill",
        "lamp.table.fill",
        "cart", "cart.fill",
        "bag", "bag.fill",
        "wineglass", "wineglass.fill",
        "mug.fill",
        "fork.knife",
        "takeoutbag.and.cup.and.straw.fill",
        "leaf", "leaf.fill",
        "camera", "camera.fill",
        "photo", "photo.fill",
        "music.note", "music.note.list",
        "sparkles",
        "theatermasks.fill"
    ]
    
    private let sportsSymbols = [
        "sportscourt", "sportscourt.fill",
        "basketball", "basketball.fill",
        "soccerball", "soccerball.fill",
        "tennis.racket",
        "baseball", "baseball.fill",
        "football", "football.fill",
        "cricket.ball.fill",
        "hockey.puck", "hockey.puck.fill",
        "figure.golf",
        "figure.badminton",
        "figure.boxing",
        "figure.archery",
        "figure.skiing.downhill",
        "figure.snowboarding",
        "flag", "flag.fill",
        "target",
        "trophy", "trophy.fill",
        "medal", "medal.fill",
        "laurel.leading", "laurel.trailing"
    ]
    
    private let techSymbols = [
        "iphone", "iphone.gen3",
        "ipad",
        "laptopcomputer",
        "desktopcomputer",
        "macbook",
        "display",
        "tv",
        "applewatch",
        "airpods", "airpodspro",
        "keyboard", "keyboard.fill",
        "printer", "printer.fill",
        "wifi", "wifi.circle", "wifi.circle.fill",
        "antenna.radiowaves.left.and.right",
        "router",
        "cpu",
        "memorychip",
        "gearshape", "gearshape.fill",
        "bolt", "bolt.fill",
        "battery.100", "battery.25",
        "cloud",
        "server.rack"
    ]
    
    private let familySymbols = [
        "person", "person.fill",
        "person.2", "person.2.fill",
        "person.3", "person.3.fill",
        "figure.child",
        "figure.2.child.holdinghands",
        "figure.and.child.holdinghands",
        "figure.2.and.child.holdinghands",
        "house", "house.fill",
        "heart", "heart.fill",
        "calendar.badge.heart",
        "gift", "gift.fill",
        "car", "car.fill",
        "photo.on.rectangle",
        "photo.stack",
        "person.crop.circle.badge.checkmark",
        "person.crop.circle.badge.questionmark",
        "person.line.dotted.person",
        "hands.sparkles.fill",
        "hand.raised.fill",
        "figure.2",
        "person.2.badge.gearshape",
        "person.crop.circle"
    ]
    
    private let mindfulnessSymbols = [
        "brain.head.profile",
        "figure.mind.and.body",
        "figure.cooldown",
        "figure.yoga",
        "figure.seated.side",
        "figure.lotus",
        "spa", "spa.fill",
        "leaf", "leaf.fill",
        "wind",
        "drop", "drop.fill",
        "water.waves",
        "waveform",
        "waveform.path.ecg",
        "sparkles",
        "sun.max",
        "moon", "moon.stars",
        "heart.text.square", "heart.text.square.fill",
        "face.smiling", "smiley",
        "cloud",
        "cloud.sun", "cloud.moon",
        "clock",
        "pause.circle"
    ]
    
    private let peopleSymbols = [
        "person", "person.fill",
        "person.circle", "person.circle.fill",
        "person.crop.circle", "person.crop.circle.fill",
        "person.crop.square", "person.crop.square.fill",
        "person.crop.rectangle", "person.crop.rectangle.fill",
        "person.crop.circle.badge.plus",
        "person.crop.circle.badge.minus",
        "person.crop.circle.badge.checkmark",
        "person.crop.circle.badge.xmark",
        "person.fill.turn.right",
        "person.fill.turn.left",
        "person.badge.plus",
        "person.badge.minus",
        "person.2", "person.2.fill", "person.2.circle",
        "person.3", "person.3.fill",
        "person.2.wave.2",
        "person.2.gobackward",
        "person.2.crop.square.stack",
        "person.and.arrow.left.and.arrow.right",
        "person.line.dotted.person",
        "person.icloud", "person.icloud.fill"
    ]
    
    private var allBaseNames: [String] {
        Array(Set(
            schoolSymbols +
            workSymbols +
            exerciseSymbols +
            lifestyleSymbols +
            sportsSymbols +
            techSymbols +
            familySymbols +
            mindfulnessSymbols +
            peopleSymbols
        ))
    }
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 56), spacing: 16)
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Group {
                if verticalSizeClass == .compact {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(IconCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(IconCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    .pickerStyle(.automatic)
                }
            }
            .padding([.horizontal, .top])
            
            
            ScrollView {
                if displayedSymbols.isEmpty {
                    VStack(spacing: 12) {
                        Text("No symbols")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if selectedCategory == .recent {
                            Text("Recently used icons will appear here.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(displayedSymbols) { symbol in
                            Button {
                                select(symbol.name)
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: symbol.name)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 28)
                                    
                                    Text(symbol.name)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Choose Icon")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search symbols")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .onAppear {
            if allSymbols.isEmpty {
                loadAllSymbols()
            }
            loadRecentIcons()
        }
    }
    
    // MARK: - Filtering
    
    private var displayedSymbols: [SymbolItem] {
        let base = symbolsForSelectedCategory()
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func symbolsForSelectedCategory() -> [SymbolItem] {
        switch selectedCategory {
        case .recent:
            let recentSet = Set(recentIcons)
            return allSymbols.filter { recentSet.contains($0.name) }
        case .all:
            return allSymbols
        case .school:
            return allSymbols.filter { schoolSymbols.contains($0.name) }
        case .work:
            return allSymbols.filter { workSymbols.contains($0.name) }
        case .exercise:
            return allSymbols.filter { exerciseSymbols.contains($0.name) }
        case .lifestyle:
            return allSymbols.filter { lifestyleSymbols.contains($0.name) }
        case .sports:
            return allSymbols.filter { sportsSymbols.contains($0.name) }
        case .tech:
            return allSymbols.filter { techSymbols.contains($0.name) }
        case .family:
            return allSymbols.filter { familySymbols.contains($0.name) }
        case .mindfulness:
            return allSymbols.filter { mindfulnessSymbols.contains($0.name) }
        case .people:
            return allSymbols.filter { peopleSymbols.contains($0.name) }
        }
    }
    
    // MARK: - Data setup
    
    private func loadAllSymbols() {
        // Only keep symbols that are actually available on this OS
        allSymbols = allBaseNames
            .filter { UIImage(systemName: $0) != nil }
            .sorted()
            .map { SymbolItem(name: $0) }
    }
    
    private func loadRecentIcons() {
        guard !recentIconNamesStorage.isEmpty else {
            recentIcons = []
            return
        }
        recentIcons = recentIconNamesStorage
            .split(separator: ",")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }
    
    private func saveRecentIcons() {
        recentIconNamesStorage = recentIcons.joined(separator: ",")
    }
    
    // MARK: - Selection / recents
    
    private func select(_ symbolName: String) {
        selectedIcon = symbolName
        updateRecent(with: symbolName)
        dismiss()
    }
    
    private func updateRecent(with symbolName: String) {
        // Move to front, keep unique, limit to 20
        recentIcons.removeAll { $0 == symbolName }
        recentIcons.insert(symbolName, at: 0)
        
        if recentIcons.count > 20 {
            recentIcons = Array(recentIcons.prefix(20))
        }
        
        saveRecentIcons()
    }
}

