//
//  BoardColorTheme.swift
//  Claude_Chess
//
//  Chess board color theme definitions
//

import SwiftUI

/// Represents a color scheme for the chess board
struct BoardColorTheme: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let lightSquare: ColorComponents
    let darkSquare: ColorComponents

    /// RGB color components for Codable conformance
    struct ColorComponents: Codable, Equatable {
        let red: Double
        let green: Double
        let blue: Double

        var color: SwiftUI.Color {
            SwiftUI.Color(red: red, green: green, blue: blue)
        }
    }

    /// All available color themes
    static let allThemes: [BoardColorTheme] = [
        .classic,
        .wooden,
        .blue,
        .green,
        .marble,
        .tournament,
        .custom
    ]

    /// Classic brown/tan theme (default)
    static let classic = BoardColorTheme(
        id: "classic",
        name: "Classic",
        lightSquare: ColorComponents(red: 0.93, green: 0.85, blue: 0.71),
        darkSquare: ColorComponents(red: 0.72, green: 0.53, blue: 0.30)
    )

    /// Wooden theme with warm tones
    static let wooden = BoardColorTheme(
        id: "wooden",
        name: "Wooden",
        lightSquare: ColorComponents(red: 0.96, green: 0.84, blue: 0.65),
        darkSquare: ColorComponents(red: 0.55, green: 0.35, blue: 0.15)
    )

    /// Blue theme with cool tones
    static let blue = BoardColorTheme(
        id: "blue",
        name: "Blue",
        lightSquare: ColorComponents(red: 0.87, green: 0.93, blue: 0.97),
        darkSquare: ColorComponents(red: 0.45, green: 0.62, blue: 0.75)
    )

    /// Green theme with forest tones
    static let green = BoardColorTheme(
        id: "green",
        name: "Green",
        lightSquare: ColorComponents(red: 0.90, green: 0.95, blue: 0.85),
        darkSquare: ColorComponents(red: 0.47, green: 0.65, blue: 0.48)
    )

    /// Marble theme with elegant grey tones
    static let marble = BoardColorTheme(
        id: "marble",
        name: "Marble",
        lightSquare: ColorComponents(red: 0.95, green: 0.95, blue: 0.95),
        darkSquare: ColorComponents(red: 0.55, green: 0.55, blue: 0.60)
    )

    /// Tournament theme (high contrast)
    static let tournament = BoardColorTheme(
        id: "tournament",
        name: "Tournament",
        lightSquare: ColorComponents(red: 1.0, green: 1.0, blue: 1.0),
        darkSquare: ColorComponents(red: 0.20, green: 0.45, blue: 0.20)
    )

    /// Custom theme (placeholder - actual colors stored in UserDefaults)
    static let custom = BoardColorTheme(
        id: "custom",
        name: "Custom",
        lightSquare: ColorComponents(red: 0.93, green: 0.85, blue: 0.71),
        darkSquare: ColorComponents(red: 0.72, green: 0.53, blue: 0.30)
    )

    /// Get theme by ID, with optional custom colors
    static func theme(withId id: String, customLight: ColorComponents? = nil,
                     customDark: ColorComponents? = nil) -> BoardColorTheme {
        if id == "custom", let lightSquare = customLight, let darkSquare = customDark {
            return BoardColorTheme(id: "custom", name: "Custom",
                                  lightSquare: lightSquare, darkSquare: darkSquare)
        }
        return allThemes.first { $0.id == id } ?? .classic
    }

    /// Helper to convert SwiftUI.Color to ColorComponents
    static func componentsFrom(color: SwiftUI.Color) -> ColorComponents {
        // Extract RGB components from SwiftUI.Color
        // Note: This uses UIColor on iOS
        #if canImport(UIKit)
        let uiColor = UIKit.UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return ColorComponents(red: Double(red), green: Double(green), blue: Double(blue))
        #else
        // Fallback for non-iOS platforms
        return ColorComponents(red: 0.93, green: 0.85, blue: 0.71)
        #endif
    }
}
