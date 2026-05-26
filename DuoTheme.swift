// MARK: - DuoTheme.swift
//
// Duolingo-inspired design tokens. Lives alongside the legacy `Theme` enum
// (Theme.swift) so the visual refactor can be done file-by-file without
// breaking any shipped feature. Once every view uses `Duo.*`, Theme.swift
// can be slimmed down.
//
// Source of truth for these values:
//   docs/character-explorations.html  (Set 02 Duolingo)
//   docs/DuolingoPortDemo.swift       (compile-checked reference port)

import SwiftUI

/// Duolingo design tokens — palette, type, primitives.
enum Duo {

    // MARK: Palette
    /// Near-black ink. Every outline + dark text. Replaces Theme.textPrimary in new views.
    static let ink           = Color(red: 0.169, green: 0.145, blue: 0.208)  // #2B2535
    /// Default tooth/card surface.
    static let cream         = Color(red: 0.980, green: 0.980, blue: 0.961)  // #FAFAF5
    /// Off-paper background top (page gradient start).
    static let bgTop         = Color(red: 0.969, green: 0.973, blue: 0.941)  // #F7F8F0
    /// Off-paper background bottom (page gradient end).
    static let bgBottom      = Color(red: 0.925, green: 0.969, blue: 0.910)  // #ECF7E8

    /// Duolingo signature green — primary CTA.
    static let green         = Color(red: 0.345, green: 0.800, blue: 0.008)  // #58CC02
    /// Drop-shadow companion to `green`.
    static let greenShadow   = Color(red: 0.247, green: 0.561, blue: 0.000)  // #3F8F00

    /// Blue — secondary CTA, toothbrush character.
    static let blue          = Color(red: 0.110, green: 0.690, blue: 0.965)  // #1CB0F6
    static let blueShadow    = Color(red: 0.063, green: 0.514, blue: 0.714)  // #1083B6

    /// Yellow — XP / level badges.
    static let yellow        = Color(red: 1.000, green: 0.784, blue: 0.000)  // #FFC800
    static let yellowShadow  = Color(red: 0.847, green: 0.620, blue: 0.000)  // #D89E00

    /// Red — error / "miss" / "streak at risk" / plaque accents.
    static let red           = Color(red: 1.000, green: 0.294, blue: 0.294)  // #FF4B4B
    static let redShadow     = Color(red: 0.769, green: 0.157, blue: 0.157)  // #C42828

    /// Soft pink for blush highlights.
    static let blush         = Color(red: 1.000, green: 0.702, blue: 0.757)  // #FFB3C1

    /// Plaque-creature green.
    static let plaqueGreen      = Color(red: 0.435, green: 0.722, blue: 0.369)  // #6FB85E
    static let plaqueGreenDeep  = Color(red: 0.353, green: 0.608, blue: 0.302)  // #5A9B4D

    /// Foam bubble fill.
    static let foamFill      = Color(red: 0.902, green: 0.957, blue: 1.000)    // #E6F4FF

    /// Standard secondary text (60% ink).
    static let muted         = Color(red: 0.443, green: 0.443, blue: 0.478)    // #71717A
    /// Pip / disabled.
    static let stoneLight    = Color(red: 0.898, green: 0.898, blue: 0.886)    // #E5E5E2

    // MARK: Type
    enum Fnt {
        static func ebd(_ size: CGFloat) -> Font { .custom("Nunito-ExtraBold", size: size) }
        static func bld(_ size: CGFloat) -> Font { .custom("Nunito-Bold",      size: size) }
        static func sbd(_ size: CGFloat) -> Font { .custom("Nunito-SemiBold",  size: size) }
        static func reg(_ size: CGFloat) -> Font { .custom("Nunito-Regular",   size: size) }
    }

    // MARK: Layout primitives
    /// 4pt shadow offset that gives Duolingo cards/buttons their depth.
    static let depthOffset: CGFloat = 4
    /// Standard outline thickness on chunky surfaces.
    static let outlineWidth: CGFloat = 2
    /// Standard corner radius for chunky surfaces.
    static let cornerRadius: CGFloat = 14

    // MARK: Gradients
    static var pageBackground: LinearGradient {
        LinearGradient(colors: [bgTop, bgBottom],
                       startPoint: .top, endPoint: .bottom)
    }
}
