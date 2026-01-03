//
//  PickServer.swift
//  NetrekIPad
//
//  Created by Darrell Root on 6/6/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI
//import Speech
import Combine

struct PickServerView: View {
    @ObservedObject var metaServer: MetaServer
    @ObservedObject var universe: Universe
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass

    @State var manualServer = "" // see serverBinding below
    
    @State private var keyboardHeight: CGFloat = 0
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
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
    var body: some View {
        
        let serverBinding = Binding<String> ( get: {
            self.manualServer
        }, set: {
            self.manualServer = $0.lowercased()
        })

        
        return VStack(alignment: .leading) {
            HStack {
                Spacer()
                Text("Netrek").font(bigText)
                Spacer()
            }
            Text("Pick Server").font(bigText)
            List {
                ForEach(metaServer.servers.keys.sorted(), id: \.self) { hostname in
                    HStack {
                        Text("\(hostname) \(self.metaServer.servers[hostname]?.type.description ?? "Unknown") players \(self.metaServer.servers[hostname]?.players ?? 0)")
                                .onTapGesture {
                                    debugPrint("server \(hostname) selected")
                                    _ = self.appDelegate.selectServer(hostname: hostname)
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }.font(bigText)
            Spacer()
            Text("We recommend \"Bronco\" servers for new Netrek players")
                .font(regularText)
            Spacer()
            HStack {
                Text("Manually Enter Server Hostname or IP Address")
                TextField("servername", text: serverBinding)
                Button("Connect to Manual Server") {
                    _ = self.appDelegate.selectServer(hostname: self.manualServer)
                }
            }.font(regularText)
            Spacer()
            HStack {
                Text("How To Play")
                    .font(bigText)
                    .foregroundColor(Color.blue)
                    .onTapGesture {
                        self.appDelegate.gameScreen = .howToPlay
                }
                Spacer()
                Text("Preferences")
                    .font(bigText)
                    .foregroundColor(Color.blue)
                    .onTapGesture {
                        self.appDelegate.gameScreen = .preferences
                }
                Spacer()
                Text("Credits")
                    .font(bigText)
                    .foregroundColor(Color.blue)
                    .onTapGesture {
                        self.appDelegate.gameScreen = .credits
                }
            }
            
        }
            .padding([.leading,.top,.trailing])
            .padding(.bottom, keyboardHeight)
            .onReceive(Publishers.keyboardHeight) {
                self.keyboardHeight = $0
        }
    }
}

