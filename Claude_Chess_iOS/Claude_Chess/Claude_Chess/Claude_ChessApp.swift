//
//  Claude_ChessApp.swift
//  Claude_Chess
//
//  Created by Jeff Rosengarden on 9/28/25.
//

import SwiftUI

@main
struct Claude_ChessApp: App {
    // Orientation support delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// App delegate to handle orientation locking
/// - iPhone: Portrait only
/// - iPad: All orientations supported
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // Check device type
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad: Allow all orientations
            return .all
        } else {
            // iPhone: Portrait only
            return .portrait
        }
    }
}
