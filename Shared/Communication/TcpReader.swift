//
//  TcpReader.swift
//  Netrek
//
//  Created by Darrell Root on 3/1/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
import SwiftUI
import Network

class TcpReader {
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
    let hostname: String
    let port: Int
    let connection: NWConnection
    var delegate: NetworkDelegate
    let queue: DispatchQueue
    var receiving: Bool = false // primitive lock on receiving
    var receiveCount: Int = 0
    var complete = false // set to true once we get complete in our receive closure
    init?(hostname: String, port: Int, delegate: NetworkDelegate) {
        self.hostname = hostname
        self.port = port
        self.delegate = delegate
        let serverEndpoint = NWEndpoint.Host(hostname)
        guard hostname.count > 2 else {
            return nil
        }
        guard port <= UInt16.max else { return nil }
        guard port > 0 else { return nil }
        let port = UInt16(port)
        queue = DispatchQueue(label: "hostname", attributes: .concurrent)
        guard let portEndpoint = NWEndpoint.Port(rawValue: port) else { return nil }

        connection = NWConnection(host: serverEndpoint, port: portEndpoint, using: .tcp)
        connection.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready:
                GameLogger.info("TcpReader ready to send", category: .connection)
                self?.delegate.connectionStateChanged(connected: true)
                self?.receive()
            case .failed(let error):
                GameLogger.error("TcpReader client failed with error: \(error)", category: .connection)
                self?.delegate.connectionStateChanged(connected: false)
            case .setup:
                GameLogger.debug("TcpReader setup", category: .connection)
            case .waiting:
                GameLogger.debug("TcpReader waiting", category: .connection)
            case .preparing:
                GameLogger.debug("TcpReader preparing", category: .connection)
            case .cancelled:
                GameLogger.info("TcpReader cancelled", category: .connection)
                self?.delegate.connectionStateChanged(connected: false)
            }
        }

        connection.start(queue: queue)
    }
    func resetConnection() {
        self.connection.cancel()
    }
    func receive() {
        guard self.complete == false else {
            GameLogger.debug("TCPReader.receive: already complete, not trying to receive", category: .network)
            return
        }
        guard self.connection.state == .ready else {
            GameLogger.debug("TCPReader.receive: connection state \(self.connection.state), not trying to receive", category: .network)
            return
        }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16384) { content, _, _, _ in
            if (content?.count ?? 0) > 0 {
                GameLogger.debug("\(Date()) TcpReader: got a message \(String(describing: content?.count)) bytes", category: .network)
            }
            if let content = content {
                self.delegate.gotData(data: content, from: self.hostname, port: self.port)
            }
        }
        receiveCount += 1
    }

    func send(content: Data) {
        GameLogger.debug("\(Date()) TcpReader sending data \(content.count) bytes", category: .network)
        connection.send(content: content, completion: .contentProcessed { error in
            if let error = error {
                GameLogger.error("TcpReader send error: \(error)", category: .network)
            }
        })
    }
}
