//
//  NetworkDelegate.swift
//  Netrek
//
//  Created by Darrell Root on 3/1/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation

protocol NetworkDelegate {
    func gotData(data: Data, from: String, port: Int)
}

/// Extended protocol with connection state notifications
/// Used by managers that need to track connection lifecycle
protocol NetworkDelegateExtended: NetworkDelegate {
    func connectionStateChanged(connected: Bool)
}
