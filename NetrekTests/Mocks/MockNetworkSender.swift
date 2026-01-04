//
//  MockNetworkSender.swift
//  NetrekTests
//
//  Mock implementation of NetworkSending for unit tests
//

import Foundation
@testable import Netrek

/// Mock network sender that captures sent data for verification in tests
class MockNetworkSender: NetworkSending {

    // MARK: - Captured Data

    /// All data packets that have been sent
    private(set) var sentData: [Data] = []

    /// Number of times send was called
    var sendCallCount: Int {
        sentData.count
    }

    /// The last data packet that was sent
    var lastSentData: Data? {
        sentData.last
    }

    // MARK: - NetworkSending

    func send(content: Data) {
        sentData.append(content)
    }

    // MARK: - Test Helpers

    /// Clear all captured data
    func reset() {
        sentData.removeAll()
    }

    /// Check if any data was sent
    var didSendData: Bool {
        !sentData.isEmpty
    }

    /// Check if data matching a predicate was sent
    func didSend(where predicate: (Data) -> Bool) -> Bool {
        sentData.contains(where: predicate)
    }
}
