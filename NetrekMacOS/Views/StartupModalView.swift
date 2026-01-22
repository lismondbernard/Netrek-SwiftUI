//
//  StartupModalView.swift
//  Netrek
//
//  Created by Claude Code
//

import SwiftUI

struct StartupModalView: View {
    @State private var serverHostname: String = "localhost"
    @ObservedObject var connectionManager: ServerConnectionManager
    var onConnect: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Connect to Netrek Server")
                .font(.title)
                .padding(.top)

            VStack(alignment: .leading, spacing: 8) {
                Text("Server Hostname or IP:")
                    .font(.headline)

                HStack {
                    TextField("localhost", text: $serverHostname)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)

                    Button("Connect") {
                        connectToServer()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }

            if let metaServer = connectionManager.metaServer, !metaServer.servers.isEmpty {
                Divider()
                    .padding(.vertical, 8)

                Text("Available Servers:")
                    .font(.headline)

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(metaServer.servers.keys.sorted(), id: \.self) { hostname in
                            Button(action: {
                                serverHostname = hostname
                                connectToServer()
                            }) {
                                HStack {
                                    Text(hostname)
                                    Spacer()
                                    if let server = metaServer.servers[hostname] {
                                        Text("\(server.players) players")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                    }
                }
                .frame(height: 200)
            }

            Spacer()
        }
        .padding()
        .frame(width: 450, height: 450)
    }

    private func connectToServer() {
        guard !serverHostname.isEmpty else { return }
        _ = connectionManager.connectToServer(hostname: serverHostname, port: 2592)
        onConnect()
    }
}

#if DEBUG
#Preview {
    let connectionManager = ServerConnectionManager(loginInformationController: LoginInformationController())
    return StartupModalView(connectionManager: connectionManager, onConnect: {})
}
#endif
