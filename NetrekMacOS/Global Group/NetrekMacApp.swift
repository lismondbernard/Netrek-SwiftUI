//
//  NetrekMacApp.swift
//  Netrek
//
//  Created with Claude Code
//

import SwiftUI

@main
struct NetrekMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty — AppDelegate manages all windows via storyboard
        Settings { EmptyView() }
    }
}
