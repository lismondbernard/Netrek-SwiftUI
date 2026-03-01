//
//  GameControllerHelpView.swift
//  Netrek
//
//  Created by Claude on 1/23/26.
//  Copyright © 2026 Network Mom LLC. All rights reserved.
//

import SwiftUI

struct GameControllerHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Game Controller Support")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)

                Text("Netrek supports MFI game controllers including Xbox, PlayStation, and other Bluetooth controllers.")
                    .font(.body)

                Divider()

                Text("Button Mapping")
                    .font(.headline)
                    .fontWeight(.semibold)

                Group {
                    ControlRow(input: "Left Stick", action: "Set Course", description: "Steer your ship continuously")
                    ControlRow(input: "Right Stick", action: "Aim", description: "Aim direction for weapons")
                    ControlRow(input: "D-Pad", action: "Set Course", description: "Alternative steering control")
                }

                Divider()

                Text("Face Buttons")
                    .font(.headline)

                Group {
                    ControlRow(input: "A Button", action: "Fire Torpedo", description: "Launch torpedo in aim direction")
                    ControlRow(input: "B Button", action: "Fire Laser", description: "Fire phaser in aim direction")
                    ControlRow(input: "X Button", action: "Toggle Shields", description: "Raise or lower shields")
                    ControlRow(input: "Y Button", action: "Toggle Cloak", description: "Activate or deactivate cloaking")
                }

                Divider()

                Text("Shoulder Buttons & Triggers")
                    .font(.headline)

                Group {
                    ControlRow(input: "Left Shoulder", action: "Decrease Speed", description: "Slow down by 1")
                    ControlRow(input: "Right Shoulder", action: "Increase Speed", description: "Speed up by 1")
                    ControlRow(input: "Left Trigger", action: "Detonate Enemy Torps", description: "Detonate nearby enemy torpedoes")
                    ControlRow(input: "Right Trigger", action: "Fire Plasma", description: "Fire plasma torpedo")
                }

                Divider()

                Text("Notes")
                    .font(.headline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 8) {
                    BulletPoint("Controllers are detected automatically when connected")
                    BulletPoint("Keyboard and mouse still work alongside the controller")
                    BulletPoint("Complex commands (beam, bomb, orbit, etc.) remain keyboard-only")
                    BulletPoint("If no aim direction is set, weapons fire in ship's current direction")
                }

                Spacer()
            }
            .padding()
        }
        #if os(macOS)
        .frame(minWidth: 450, minHeight: 500)
        #endif
    }
}

struct ControlRow: View {
    let input: String
    let action: String
    let description: String

    var body: some View {
        HStack(alignment: .top) {
            Text(input)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(action)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{2022}")
            Text(text)
        }
    }
}

struct GameControllerHelpView_Previews: PreviewProvider {
    static var previews: some View {
        GameControllerHelpView()
    }
}
