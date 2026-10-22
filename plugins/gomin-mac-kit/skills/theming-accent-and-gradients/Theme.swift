import AppKit
import SwiftUI

// Light / Dark / System, 16 solid accents + System, and two-tone gradient themes (ambient light only).
// Storage: @AppStorage("ui.accent"), ("ui.gradient"), ("app.appearance") — same keys in the root view and the panel.

// MARK: - Appearance

/// Applied once at the root: `.onChange(of: appearance, initial: true) { NSApp.appearance = appearance.nsAppearance }`.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

// MARK: - Accent

/// 16 hues + System. Each colour sits at relative luminance ≈ 0.16, so white text on it is 5.0:1 and the colour on
/// a dark window (#1E1E1E) is 3.3:1 — one value works in light and dark, and filled buttons / selection stay legible.
/// More hues than 16 at that luminance become indistinguishable neighbours.
enum AccentChoice: String, CaseIterable, Identifiable {
    case system
    case red, orange, amber, olive, lime, green, emerald, teal
    case cyan, blue, indigo, violet, purple, magenta, pink, graphite

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    /// nil = the accent people chose in System Settings. Apply with `.tint(accent.color)` at the root.
    var color: Color? {
        let hex: UInt32? = switch self {
        case .system: nil
        case .red: 0xE00219
        case .orange: 0xB45403
        case .amber: 0x9A6405
        case .olive: 0x7F7002
        case .lime: 0x557B04
        case .green: 0x028132
        case .emerald: 0x057F60
        case .teal: 0x077D7A
        case .cyan: 0x027A8F
        case .blue: 0x036AE4
        case .indigo: 0x5C55FF
        case .violet: 0x8F3DFA
        case .purple: 0xB424D8
        case .magenta: 0xCF01A6
        case .pink: 0xDB045E
        case .graphite: 0x6F6F6F
        }
        return hex.map(Color.init(hex:))
    }

    /// `open MyApp.app --args -accent teal` for screenshots; otherwise the stored choice.
    static var launchOverride: AccentChoice? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: "-accent"), args.indices.contains(index + 1) else { return nil }
        return AccentChoice(rawValue: args[index + 1])
    }
}

// MARK: - Gradient theme

/// No pair keeps white text ≥ 4.5:1 end to end and some ends vanish on a dark window, so a theme is
/// **ambient light only** — never under text or controls. Controls take the paired solid `accent` instead.
enum GradientTheme: String, CaseIterable, Identifiable {
    case none, ocean, ember, lavender, watermelon, lagoon, meadow, dusk, peach

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var colors: [Color] {
        let pair: (UInt32, UInt32) = switch self {
        case .none: (0, 0)
        case .ocean: (0x007CBE, 0xFFF7AE)
        case .ember: (0xE57A44, 0x251351)
        case .lavender: (0xF1FEC6, 0xA882DD)
        case .watermelon: (0xDB5375, 0xB3FFB3)
        case .lagoon: (0x02C3BD, 0x4E148C)
        case .meadow: (0x629460, 0xF4D35E)
        case .dusk: (0x414288, 0xB0DB43)
        case .peach: (0xFFC145, 0xEC368D)
        }
        return self == .none ? [] : [Color(hex: pair.0), Color(hex: pair.1)]
    }

    /// Solid accent for controls — the palette hue closest to the gradient's stronger end.
    var accent: AccentChoice {
        switch self {
        case .none: .system
        case .ocean: .blue
        case .ember: .orange
        case .lavender: .violet
        case .watermelon: .pink
        case .lagoon: .teal
        case .meadow: .lime
        case .dusk: .indigo
        case .peach: .magenta
        }
    }

    /// `-gradient lagoon` for screenshots.
    static var launchOverride: GradientTheme? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: "-gradient"), args.indices.contains(index + 1) else { return nil }
        return GradientTheme(rawValue: args[index + 1])
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - Panel

/// Appearance, accent swatches (System + 2 × 8, like System Settings) and gradient themes; a theme also sets its
/// paired accent. Reads the same @AppStorage keys as the root view.
struct AppearancePanel: View {
    @AppStorage("ui.accent") private var accent = AccentChoice.system
    @AppStorage("ui.gradient") private var theme = GradientTheme.none
    @AppStorage("app.appearance") private var appearance = Appearance.system

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases) { option in
                            Label(option.rawValue.capitalized, systemImage: option.symbol).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                Divider()
                section("Accent") {
                    accentSwatch(.system, showsName: true)
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(26), spacing: 10), count: 8), spacing: 10) {
                        ForEach(AccentChoice.allCases.dropFirst()) { accentSwatch($0) }
                    }
                    Text(accent.name).font(.caption).foregroundStyle(.secondary)
                }
                Divider()
                section("Gradient") {
                    let themes = Array(GradientTheme.allCases.dropFirst())
                    Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                        ForEach([0, 4], id: \.self) { start in
                            GridRow { ForEach(themes[start..<start + 4]) { themeSwatch($0) } }
                        }
                    }
                    Button("No Gradient") { theme = .none }.disabled(theme == .none)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func section(_ title: LocalizedStringKey, @ViewBuilder _ body: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 13, weight: .semibold))
            body()
        }
        .padding(16)
    }

    private func accentSwatch(_ option: AccentChoice, showsName: Bool = false) -> some View {
        Button { accent = option } label: {
            HStack(spacing: 8) {
                ZStack {
                    if let color = option.color {
                        Circle().fill(color)
                    } else {
                        Circle().fill(AngularGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                                                      center: .center))
                    }
                    if option == accent {
                        Circle().strokeBorder(.background, lineWidth: 2).padding(2)
                        Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                    }
                }
                .frame(width: 22, height: 22)
                .overlay(Circle().strokeBorder(.primary.opacity(0.15)))
                if showsName { Text("Follow System").font(.callout) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(option.name)
        .accessibilityLabel(option.name)
        .accessibilityAddTraits(option == accent ? .isSelected : [])
    }

    private func themeSwatch(_ option: GradientTheme) -> some View {
        Button {
            theme = option
            accent = option.accent
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: option.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 56, height: 36)
                .overlay {
                    if option == theme { RoundedRectangle(cornerRadius: 8).strokeBorder(.primary, lineWidth: 2) }
                }
        }
        .buttonStyle(.plain)
        .help(option.name)
        .accessibilityLabel(option.name)
        .accessibilityAddTraits(option == theme ? .isSelected : [])
    }
}
