//
//  WindowManager.swift
//  Netrek2
//
//  Created by Claude Code on 1/26/26.
//  Manages window and modal presentation state for macOS
//

import SwiftUI

/// Manages presentation state for modal sheets and windows.
/// Used by NetrekApp to show/hide preferences, login, statistics, and manual server modals.
/// Published properties are bound to .sheet() modifiers in NetrekApp.
@MainActor
class WindowManager: ObservableObject {
    /// Controls visibility of the Preferences sheet
    @Published var showingPreferences = false

    /// Controls visibility of the Login Information sheet
    @Published var showingLogin = false

    /// Controls visibility of the Detailed Statistics sheet
    @Published var showingStatistics = false

    /// Controls visibility of the Manual Server entry sheet
    @Published var showingManualServer = false

    /// Controls visibility of the Game Controller Help sheet
    @Published var showingGameControllerHelp = false
}
