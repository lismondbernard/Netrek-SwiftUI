//
//  EnvironmentKeys.swift
//  Netrek
//
//  Environment keys for dependency injection
//

import SwiftUI

// MARK: - KeymapController

private struct KeymapControllerKey: EnvironmentKey {
    static let defaultValue: KeymapController? = nil
}

extension EnvironmentValues {
    var keymapController: KeymapController? {
        get { self[KeymapControllerKey.self] }
        set { self[KeymapControllerKey.self] = newValue }
    }
}

// MARK: - MessagesController

#if os(iOS)
private struct MessagesControllerKey: EnvironmentKey {
    static let defaultValue: MessagesController? = nil
}

extension EnvironmentValues {
    var messagesController: MessagesController? {
        get { self[MessagesControllerKey.self] }
        set { self[MessagesControllerKey.self] = newValue }
    }
}
#endif

// MARK: - Help

private struct HelpKey: EnvironmentKey {
    static let defaultValue: Help? = nil
}

extension EnvironmentValues {
    var help: Help? {
        get { self[HelpKey.self] }
        set { self[HelpKey.self] = newValue }
    }
}

// MARK: - LoginInformationController

private struct LoginInformationControllerKey: EnvironmentKey {
    static let defaultValue: LoginInformationController? = nil
}

extension EnvironmentValues {
    var loginInformationController: LoginInformationController? {
        get { self[LoginInformationControllerKey.self] }
        set { self[LoginInformationControllerKey.self] = newValue }
    }
}
