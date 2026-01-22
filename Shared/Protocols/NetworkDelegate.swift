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
    func connectionStateChanged(connected: Bool)
}
