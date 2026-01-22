//
//  PreferencesView.swift
//  Netrek2
//
//  Created by Darrell Root on 6/1/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

@MainActor
class ActivePreference: ObservableObject {
    let keymapController: KeymapController

    @Published var currentControl = Control.allCases.first! {
        didSet {
            GameLogger.debug("current control updated", category: .ui)
            self.readCommand()
        }
    }
    @Published var currentCommand = Command.allCases.first! {
        didSet {
            GameLogger.debug("considering whether keymap update is necessary", category: .ui)
            if currentCommand != keymapController.keymap[currentControl] {
                GameLogger.debug("current control \(currentControl.rawValue) updated to \(currentCommand.rawValue)", category: .ui)
                keymapController.setKeymap(control: currentControl, command: currentCommand)
            }
        }
    }

    init(keymapController: KeymapController) {
        self.keymapController = keymapController
        currentCommand = keymapController.keymap[currentControl] ?? Command.nothing
    }
    func readCommand() {
        self.currentCommand = keymapController.keymap[currentControl] ?? Command.nothing
    }
}
struct PreferencesView: View {
    @ObservedObject var activePreference: ActivePreference
    @State var showHints = true

    var keymapController: KeymapController
    @ObservedObject var preferencesController: PreferencesController

    init(keymapController: KeymapController, preferencesController: PreferencesController) {
        self.keymapController = keymapController
        self.preferencesController = preferencesController
        self.activePreference = ActivePreference(keymapController: keymapController)
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack {
                    Text("Control")
                    Picker(selection: $activePreference.currentControl, label: EmptyView()) {
                        ForEach(Control.allCases, id: \.self) { control in
                            Text(control.rawValue)
                        }
                    }
                }
                VStack {
                    Text("")
                    Text("->").font(.headline).offset(y: 5)
                }
                VStack {
                    Text("Command")
                    Picker(selection: $activePreference.currentCommand, label: EmptyView()) {
                        ForEach(Command.allCases, id: \.self) { command in
                            Text(command.rawValue)
                        }
                    }
                }
            }
            Button("Reset All To Defaults") {
                self.keymapController.resetKeymaps()
                self.activePreference.readCommand()
            }
            Toggle("Hide Hints", isOn: $preferencesController.hideHints)
        }
        .padding(8)
    }
}
