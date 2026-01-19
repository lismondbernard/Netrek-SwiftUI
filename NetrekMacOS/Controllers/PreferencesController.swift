//
//  PreferencesController.swift
//  Netrek2
//
//  Created by Darrell Root on 6/4/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Foundation
import SwiftUI

class PreferencesController: ObservableObject {

    static let hideHintsKey = "showHints"
    static let preferUdpKey = "preferUdp"

    let defaults: UserDefaults
    @Published var hideHints = false {
        didSet {
            defaults.set(hideHints, forKey: PreferencesController.hideHintsKey)
            GameLogger.debug("set userdefaults hideHints \(hideHints)", category: .ui)
        }
    }
    @Published var preferUdp = false {
        didSet {
            defaults.set(preferUdp, forKey: PreferencesController.preferUdpKey)
            GameLogger.debug("set userdefaults preferUdp \(preferUdp)", category: .ui)
        }
    }
    
    init(defaults: UserDefaults) {
        self.defaults = defaults
        self.hideHints = defaults.bool(forKey: PreferencesController.hideHintsKey)
        self.preferUdp = defaults.bool(forKey: PreferencesController.preferUdpKey)
    }
}
