import SwiftUI

// Right-hand tool window like JetBrains IDEs: an icon rail on the window edge, one panel at a time at full height,
// "–" hides it. Uses glassSurface(cornerRadius:) from adopting-liquid-glass.

/// The panels the rail switches between; ⌥⌘1…n toggle them in this order. Edit the cases for your app.
enum ToolPanel: String, CaseIterable, Identifiable {
    case history, agent, help, appearance, about

    /// Pinned to the bottom of the rail (settings-like panels).
    static let bottom: [ToolPanel] = [.appearance, .about]

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .history: "clock.arrow.circlepath"
        case .agent: "sparkles"
        case .help: "questionmark.circle"
        case .appearance: "paintpalette"
        case .about: "info.circle"
        }
    }

    var title: String {
        switch self {
        case .history: String(localized: "History")
        case .agent: String(localized: "AI Agent")
        case .help: String(localized: "Help")
        case .appearance: String(localized: "Appearance")
        case .about: String(localized: "About")
        }
    }
}

/// Panel (when open) + icon rail on the trailing edge. `panel == nil` = hidden.
struct ToolWindow<Content: View>: View {
    @Binding var panel: ToolPanel?
    /// Two colours for an ambient glow in the panel's corner; empty = none.
    var glow: [Color] = []
    @ViewBuilder var content: (ToolPanel) -> Content
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        // Every panel stays mounted (hidden, zero-width when closed): @State inside a panel — a chat in progress,
        // a scroll position — would be lost on each switch otherwise.
        HStack(spacing: 0) {
            window
                .frame(width: panel == nil ? 0 : 320)
                .opacity(panel == nil ? 0 : 1)
                .allowsHitTesting(panel != nil)
                .accessibilityHidden(panel == nil)
            rail
        }
    }

    private var rail: some View {
        VStack(spacing: 6) {
            ForEach(ToolPanel.allCases.filter { !ToolPanel.bottom.contains($0) }) { railButton($0) }
            Spacer()
            ForEach(ToolPanel.bottom) { railButton($0) }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .overlay(alignment: .leading) { Divider() }
    }

    private func railButton(_ item: ToolPanel) -> some View {
        let number = (ToolPanel.allCases.firstIndex(of: item) ?? 0) + 1
        return Button { panel = panel == item ? nil : item } label: {
            Image(systemName: item.icon)
                .font(.system(size: 15))
                .frame(width: 32, height: 32)
                .foregroundStyle(panel == item ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .background(panel == item ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear),
                            in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(Character("\(number)")), modifiers: [.command, .option])
        .help("\(item.title) (⌥⌘\(number))")
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(panel == item ? .isSelected : [])
    }

    private var window: some View {
        let shown = panel ?? ToolPanel.allCases[0]
        return VStack(spacing: 0) {
            HStack {
                Text(shown.title).font(.system(size: 13, weight: .semibold))
                Spacer()
                Button { panel = nil } label: { Image(systemName: "minus") }
                    .buttonStyle(.borderless)
                    .help(String(localized: "Hide"))
                    .accessibilityLabel(String(localized: "Hide \(shown.title)"))
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)
            ZStack {
                ForEach(ToolPanel.allCases) { item in
                    VStack(spacing: 0) {
                        content(item)
                        Spacer(minLength: 0)
                    }
                    .opacity(item == shown ? 1 : 0)
                    .allowsHitTesting(item == shown)
                    .accessibilityHidden(item != shown)
                }
            }
        }
        .background(alignment: .bottomTrailing) { glowView }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .glassSurface(cornerRadius: 18)
        .padding(10)
    }

    /// Ambient light only — never under text. Off with Reduce Transparency.
    @ViewBuilder
    private var glowView: some View {
        if glow.count >= 2 && !reduceTransparency {
            Ellipse()
                .fill(LinearGradient(colors: glow, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 340, height: 280)
                .blur(radius: 60)
                .opacity(0.75)
                .offset(x: 110, y: 110)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
