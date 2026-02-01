//
//  LocalServerBrowser.swift
//  Netrek
//
//  Created by Claude Code
//

import Foundation
import Network

class LocalServerBrowser: ObservableObject {
    private var browser: NWBrowser?
    private weak var metaServer: MetaServer?
    private var localHostnames: Set<String> = []

    init(metaServer: MetaServer) {
        self.metaServer = metaServer
    }

    func start() {
        let params = NWParameters()
        params.includePeerToPeer = true
        browser = NWBrowser(for: .bonjour(type: "_netrek._tcp", domain: nil), using: params)

        browser?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                debugPrint("LocalServerBrowser: browsing for _netrek._tcp")
            case .failed(let error):
                debugPrint("LocalServerBrowser: failed \(error)")
            default:
                break
            }
        }

        browser?.browseResultsChangedHandler = { results, changes in
            for change in changes {
                switch change {
                case .added(let result):
                    self.resolve(result: result)
                case .removed(let result):
                    self.remove(result: result)
                default:
                    break
                }
            }
        }

        browser?.start(queue: .main)
    }

    func stop() {
        browser?.cancel()
        browser = nil
        // Remove all local entries
        for hostname in localHostnames {
            metaServer?.servers.removeValue(forKey: hostname)
        }
        localHostnames.removeAll()
    }

    private func resolve(result: NWBrowser.Result) {
        let connection = NWConnection(to: result.endpoint, using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                if let innerEndpoint = connection.currentPath?.remoteEndpoint,
                   case .hostPort(let host, let port) = innerEndpoint {
                    let hostname: String
                    switch host {
                    case .ipv4(let addr):
                        hostname = "\(addr)"
                    case .ipv6(let addr):
                        hostname = "\(addr)"
                    case .name(let name, _):
                        hostname = name
                    @unknown default:
                        hostname = "\(host)"
                    }
                    let portInt = Int(port.rawValue)
                    DispatchQueue.main.async {
                        let name: String
                        if case .service(let serviceName, _, _, _) = result.endpoint {
                            name = serviceName
                        } else {
                            name = hostname
                        }
                        let entry = MetaServerEntry(hostname: hostname, port: portInt, age: 0, players: 0, type: .other)
                        entry.isLocal = true
                        entry.localName = name
                        self.metaServer?.servers[hostname] = entry
                        self.localHostnames.insert(hostname)
                        debugPrint("LocalServerBrowser: discovered \(name) at \(hostname):\(portInt)")
                    }
                }
                connection.cancel()
            case .failed:
                connection.cancel()
            default:
                break
            }
        }
        connection.start(queue: .main)
    }

    private func remove(result: NWBrowser.Result) {
        // Try to find and remove the entry by matching the service name
        if case .service(let name, _, _, _) = result.endpoint {
            DispatchQueue.main.async {
                for hostname in self.localHostnames {
                    if let entry = self.metaServer?.servers[hostname], entry.localName == name {
                        self.metaServer?.servers.removeValue(forKey: hostname)
                        self.localHostnames.remove(hostname)
                        debugPrint("LocalServerBrowser: removed \(name)")
                        break
                    }
                }
            }
        }
    }

    deinit {
        browser?.cancel()
    }
}
