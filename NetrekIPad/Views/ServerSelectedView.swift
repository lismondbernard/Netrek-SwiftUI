//
//  ServerSelectedView.swift
//  NetrekIPad
//
//  Created by Darrell Root on 6/10/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct ServerSelectedView: View {
    @EnvironmentObject var gameStateManager: GameStateManager

    var server: String

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "chevron.left")
                Text("Abort Connection")
                Spacer()
            }.foregroundColor(Color.blue)
            .onTapGesture {
                self.gameStateManager.newGameState(.noServerSelected)
            }
            Spacer()
            Text("Server \(server) Selected")
            Text("Attempting to connect")
            Spacer()
        }.font(.title)
    }
}

/*struct ServerSelectedView_Previews: PreviewProvider {
    static var previews: some View {
        ServerSelectedView()
    }
}*/
