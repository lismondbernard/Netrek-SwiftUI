//
//  EverythingView.swift
//  Netrek
//
//  Created by Darrell Root on 3/4/22.
//  Copyright © 2022 Darrell Root. All rights reserved.
//

import SwiftUI

struct EverythingView: View {
    @ObservedObject var help: Help
    @EnvironmentObject var universe: Universe
    @ObservedObject var preferencesController: PreferencesController
    @FocusState var textFieldFocused
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    TacticalView(help: help, preferencesController: preferencesController)
                        .frame(width: geo.size.width / 2, height: geo.size.width / 2)
                        .border(universe.players[universe.me].alertCondition.color.opacity(0.5), width: 10)
                        .onTapGesture {
                            textFieldFocused = false
                        }
                        .clipped()

                    StrategicView()
                        .frame(width: geo.size.width / 2, height: geo.size.width / 2)
                        .border(universe.players[universe.me].alertCondition.color.opacity(0.5), width: 10)
                        .onTapGesture {
                            textFieldFocused = false
                        }
                        .clipped()
                }
                CommunicationsView(textFieldFocused: _textFieldFocused)
                    .frame(width: geo.size.width)
                    .border(universe.players[universe.me].alertCondition.color.opacity(0.5), width: 3)
                    .clipped()
            }
        }
    }
}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()

    EverythingView(
        help: Help(),
        preferencesController: PreferencesController(defaults: .standard)
    )
    .environmentObject(Universe.universe)
    .frame(width: 1200, height: 800)
}
#endif
