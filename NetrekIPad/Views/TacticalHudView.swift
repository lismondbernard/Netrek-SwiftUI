//
//  TacticalHudView.swift
//  NetrekIPad
//
//  Created by Darrell Root on 6/9/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct TacticalHudView: View {
    #if os(macOS)
    // Safe optional access - won't crash if delegate is nil or wrong type
    var appDelegate: AppDelegate? {
        return NSApplication.shared.delegate as? AppDelegate
    }
    #elseif os(iOS)
    // Safe optional access - won't crash if delegate is nil or wrong type
    var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    #endif

    @EnvironmentObject var universe: Universe
    @ObservedObject var me: Player
    @ObservedObject var help: Help

    @State var newMessage: String = ""
    @State var sendToAll = true

    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass

    var bigText: Font {
        guard let vSizeClass = vSizeClass else {
            return Font.headline
        }
        switch vSizeClass {
        case .regular:
            return .title
        case .compact:
            return .headline
        }
    }
    var regularText: Font {
        guard let vSizeClass = vSizeClass else {
            return Font.body
        }
        switch vSizeClass {
        case .regular:
            return .headline
        case .compact:
            return Font.body
        }
    }

    var SendToAll: String {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "All"
        case .pad:
            return "Send To All"
        default:
            return "Send To All"
        }
    }
    var SendToMyTeam: String {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "Team"
        case .pad:
            return "Send To My Team"
        default:
            return "Send To My Team"
        }
    }
    var Speed: String {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "S"
        case .pad:
            return "Speed"
        default:
            return "Speed"
        }
    }
    var Fuel: String {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "F"
        case .pad:
            return "Fuel"
        default:
            return "Fuel"
        }
    }


    var body: some View {
        return GeometryReader { geo in
            HStack {
                LeftTacticalControlView(me: self.universe.players[self.universe.me])
                    .frame(width: geo.size.width * 0.15, height: geo.size.height)
                    .border(Color.blue)
                VStack {
                    HStack {
                        Text("                                       ")
                            .overlay(Text("\(self.Speed) \(self.me.speed) \(self.Fuel) \(self.me.fuel)"))
                                .font(.system(.body, design: .monospaced))
                        TextField("New Message", text: self.$newMessage, onCommit: self.sendMessage)

                            .border(Color.primary, width: 1)

                        Toggle(self.sendToAll ? self.SendToAll : self.SendToMyTeam, isOn: self.$sendToAll).toggleStyle(SwitchToggleStyle())
                            .frame(width: geo.size.width * 0.20)
                        Button("Escort") {
                            self.appDelegate?.messagesController?.sendEscort()
                        }
                    .padding(4)
                        .border(Color.blue)
                        Button("MAYDAY") {
                            self.appDelegate?.messagesController?.sendMayday()
                        }
                    .padding(4)
                        .border(Color.blue)
                    }
                    .frame(width: geo.size.width * 0.77)
                    .layoutPriority(1)

                    TacticalView(me: self.me, help: self.help)
                        .frame(width: geo.size.width * 0.8, height: geo.size.height * 0.8)
                    .clipped()
                    HStack {
                        Stepper(
                            onIncrement: {
                                self.me.throttle += 1
                                self.appDelegate?.keymapController.setSpeed(Int(self.me.throttle))
                            },
                            onDecrement: {
                                self.me.throttle -= 1
                                self.appDelegate?.keymapController.setSpeed(Int(self.me.throttle))
                            }) {
                            Text("Requested Speed \(self.me.throttle)")
                        }
                            .padding([.leading, .trailing])
                    }
                }
            }
        }
    }

    func sendMessage() {
        GameLogger.debug("sending message \(newMessage)", category: .ui)
        self.sendMessage(message: newMessage, sendToAll: self.sendToAll)
    }

    func sendMessage(message: String, sendToAll: Bool) {
        if message.isEmpty {
            return
        }
        if sendToAll {
            let data = MakePacket.cpMessage(message: message, team: .independent, individual: 0)
            self.appDelegate?.reader?.send(content: data)
            self.newMessage = ""
        } else {
            let data = MakePacket.cpMessage(message: message, team: self.universe.players[self.universe.me].team, individual: 0)
            self.appDelegate?.reader?.send(content: data)
            self.newMessage = ""
        }
    }
}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe
    let me = universe.players[universe.me]

    return TacticalHudView(
        me: me,
        help: Help()
    )
    .environmentObject(universe)
}
#endif
