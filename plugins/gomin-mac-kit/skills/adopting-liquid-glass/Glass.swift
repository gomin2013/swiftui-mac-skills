import SwiftUI

// Liquid Glass (macOS 26) with a material fallback (macOS 14–15).
// `#if compiler(>=6.2)` keeps this compiling on toolchains whose SDK has no glass API at all;
// `#available` picks the look at run time.

extension View {
    /// Control-layer surface: Liquid Glass on macOS 26, `.regularMaterial` before. Never for list content.
    @ViewBuilder
    func glassSurface(cornerRadius: CGFloat) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26, *) {
            glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
        #else
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        #endif
    }

    /// `.glassProminent` / `.glass` on macOS 26, `.borderedProminent` / `.bordered` before.
    @ViewBuilder
    func glassButton(prominent: Bool = false) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26, *) {
            // Only the primary action carries the accent; plain glass stays neutral (HIG: colour the key action only)
            if prominent { buttonStyle(.glassProminent) } else { buttonStyle(.glass).tint(nil) }
        } else {
            if prominent { buttonStyle(.borderedProminent) } else { buttonStyle(.bordered) }
        }
        #else
        if prominent { buttonStyle(.borderedProminent) } else { buttonStyle(.bordered) }
        #endif
    }

    /// Groups neighbouring glass so it blends (macOS 26); a plain container before.
    @ViewBuilder
    func glassGroup(spacing: CGFloat = 8) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26, *) {
            GlassEffectContainer(spacing: spacing) { self }
        } else {
            self
        }
        #else
        self
        #endif
    }
}
