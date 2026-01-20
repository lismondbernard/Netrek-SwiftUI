//
//  BottomView.swift
//  Netrek2
//
//  Created by Darrell Root on 5/9/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct CommunicationsView: View {
    @EnvironmentObject var universe: Universe
    @FocusState var textFieldFocused


    var body: some View {
        HStack {
            StatisticsView(me: universe.players[universe.me])
            MessagesView(textFieldFocused: _textFieldFocused)
        }.frame(minWidth: 1000)
    }
}

#if DEBUG
#Preview {
    _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe

    CommunicationsView()
        .environmentObject(universe)
}
#endif
