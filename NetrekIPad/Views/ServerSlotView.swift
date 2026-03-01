//
//  ServerSlotView.swift
//  NetrekIPad
//
//  Created by Darrell Root on 6/11/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct ServerSlotView: View {
    @EnvironmentObject var gameStateManager: GameStateManager
    @EnvironmentObject var connectionManager: ServerConnectionManager

    var body: some View {
        VStack {
            HStack {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Disconnect From Server")
                }.onTapGesture {
                    self.gameStateManager.newGameState(.noServerSelected)
                }
                Spacer()
            }//HStack
            Spacer()
            Text("Server \(connectionManager.connectedServerHostname ?? "unknown") Slot Found")
            connectionManager.loginInformationController.loginAuthenticated ? Text("Attempting to login as user \(connectionManager.loginInformationController.loginName)") : Text("Attempting to login as guest")
            Spacer()
        }//VStack
    }//var body
}

/*struct ServerConnectedView_Previews: PreviewProvider {
    static var previews: some View {
        ServerConnectedView()
    }
}*/
