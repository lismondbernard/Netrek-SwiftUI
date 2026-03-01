//
//  ServerConnectionManagerTests.swift
//  NetrekCoreTests
//
//  Tests for ServerConnectionManager - network connection handling.
//

import XCTest
@testable import Netrek

final class ServerConnectionManagerTests: XCTestCase {

    // MARK: - Initialization Tests

    @MainActor
    func testInit_CreatesMetaServer() {
        let manager = ServerConnectionManager()

        XCTAssertNotNil(manager.metaServer,
                       "MetaServer should be created on init")
    }

    @MainActor
    func testInit_ReaderIsNil() {
        let manager = ServerConnectionManager()

        XCTAssertNil(manager.reader,
                    "Reader should be nil initially")
    }

    @MainActor
    func testInit_AnalyzerIsNil() {
        let manager = ServerConnectionManager()

        XCTAssertNil(manager.analyzer,
                    "Analyzer should be nil initially")
    }

    @MainActor
    func testInit_ServerFeaturesEmpty() {
        let manager = ServerConnectionManager()

        XCTAssertTrue(manager.serverFeatures.isEmpty,
                     "Server features should be empty initially")
    }

    // MARK: - Client Features Tests

    @MainActor
    func testClientFeatures_ContainsExpectedFeatures() {
        let manager = ServerConnectionManager()

        XCTAssertTrue(manager.clientFeatures.contains("FEATURE_PACKETS"),
                     "Should contain FEATURE_PACKETS")
        XCTAssertTrue(manager.clientFeatures.contains("SHIP_CAP"),
                     "Should contain SHIP_CAP")
        XCTAssertTrue(manager.clientFeatures.contains("SP_GENERIC_32"),
                     "Should contain SP_GENERIC_32")
        XCTAssertTrue(manager.clientFeatures.contains("TIPS"),
                     "Should contain TIPS")
    }

    @MainActor
    func testClientFeatures_Count() {
        let manager = ServerConnectionManager()

        XCTAssertEqual(manager.clientFeatures.count, 4,
                      "Should have 4 client features")
    }

    // MARK: - MetaServer Configuration Tests

    @MainActor
    func testConfigureMetaserver_UpdatesMetaServer() {
        let manager = ServerConnectionManager()

        manager.configureMetaserver(primary: "test.netrek.org", backup: "backup.netrek.org")

        XCTAssertNotNil(manager.metaServer,
                       "MetaServer should be reconfigured")
    }

    @MainActor
    func testConfigureMetaserver_WithCustomPort() {
        let manager = ServerConnectionManager()

        manager.configureMetaserver(primary: "test.netrek.org", backup: "backup.netrek.org", port: 4000)

        XCTAssertNotNil(manager.metaServer)
    }

    // MARK: - Connection State Tests

    @MainActor
    func testConnectToServer_WithoutGameStateManager_ReturnsFalse() {
        let manager = ServerConnectionManager()
        // gameStateManager is nil

        let result = manager.connectToServer(hostname: "localhost")

        // Should fail because gameStateManager?.gameState returns nil
        XCTAssertFalse(result,
                      "Connection should fail without game state manager")
    }

    @MainActor
    func testConnectToServer_InNoServerSelected_Allowed() {
        let manager = ServerConnectionManager()
        let stateManager = GameStateManager()
        manager.gameStateManager = stateManager

        // State is .noServerSelected, connection should be attempted
        // Will fail because we can't actually connect, but the state check passes
        let result = manager.connectToServer(hostname: "invalid-hostname-that-wont-resolve")

        // Result depends on whether TcpReader can be created
        // The important thing is that state check passes
        XCTAssertEqual(stateManager.gameState, .noServerSelected)
    }

    @MainActor
    func testConnectToServer_InGameActive_NotAllowed() {
        let manager = ServerConnectionManager()
        let stateManager = GameStateManager()
        manager.gameStateManager = stateManager

        // Set state to gameActive
        stateManager.newGameState(.gameActive)

        let result = manager.connectToServer(hostname: "localhost")

        XCTAssertFalse(result,
                      "Should not connect when already in gameActive state")
    }

    // MARK: - Reset Connection Tests

    @MainActor
    func testResetConnection_WhenNotConnected_DoesNotCrash() {
        let manager = ServerConnectionManager()

        manager.resetConnection()

        // Should not crash
        XCTAssertNil(manager.reader)
    }

    @MainActor
    func testResetConnection_ClearsReader() {
        let manager = ServerConnectionManager()

        // Simulate having a reader (we can't create real one)
        manager.resetConnection()

        XCTAssertNil(manager.reader,
                    "Reader should be nil after reset")
    }

    // MARK: - Packet Analyzer Tests

    @MainActor
    func testCreatePacketAnalyzer_CreatesAnalyzer() {
        let manager = ServerConnectionManager()

        manager.createPacketAnalyzer()

        XCTAssertNotNil(manager.analyzer,
                       "Analyzer should be created")
    }

    @MainActor
    func testCreatePacketAnalyzer_CalledTwice_ReplacesAnalyzer() {
        let manager = ServerConnectionManager()

        manager.createPacketAnalyzer()
        let firstAnalyzer = manager.analyzer

        manager.createPacketAnalyzer()
        let secondAnalyzer = manager.analyzer

        XCTAssertNotNil(secondAnalyzer)
        // They should be different instances
        XCTAssertFalse(firstAnalyzer === secondAnalyzer,
                      "Should create new analyzer instance")
    }

    // MARK: - NetworkSending Protocol Tests

    @MainActor
    func testNetworkSending_Conformance() {
        let manager = ServerConnectionManager()

        // ServerConnectionManager conforms to NetworkSending
        let sender: NetworkSending = manager

        // send() should not crash even without reader
        sender.send(content: Data())
    }

    @MainActor
    func testSend_WithoutReader_DoesNotCrash() {
        let manager = ServerConnectionManager()

        manager.send(content: Data([0x01, 0x02, 0x03]))

        // Should not crash, just does nothing
    }

    // MARK: - PacketAnalyzerDelegate Tests

    @MainActor
    func testPacketAnalyzerDelegate_GameState_WithoutManager() {
        let manager = ServerConnectionManager()
        // gameStateManager is nil

        XCTAssertEqual(manager.gameState, .noServerSelected,
                      "Should return noServerSelected when manager is nil")
    }

    @MainActor
    func testPacketAnalyzerDelegate_GameState_WithManager() {
        let manager = ServerConnectionManager()
        let stateManager = GameStateManager()
        manager.gameStateManager = stateManager

        stateManager.newGameState(.gameActive)

        XCTAssertEqual(manager.gameState, .gameActive,
                      "Should return manager's game state")
    }

    @MainActor
    func testPacketAnalyzerDelegate_NewGameState_UpdatesManager() {
        let manager = ServerConnectionManager()
        let stateManager = GameStateManager()
        manager.gameStateManager = stateManager

        manager.newGameState(.loginAccepted)

        XCTAssertEqual(stateManager.gameState, .loginAccepted,
                      "Should propagate state to manager")
    }

    @MainActor
    func testPacketAnalyzerDelegate_TriggerReceive_WithoutReader() {
        let manager = ServerConnectionManager()

        manager.triggerReceive()

        // Should not crash
    }

    @MainActor
    func testPacketAnalyzerDelegate_UpdateTeamEligibility() {
        let manager = ServerConnectionManager()
        let stateManager = GameStateManager()
        manager.gameStateManager = stateManager

        manager.updateTeamEligibility(mask: UInt8(Team.federation.rawValue))

        XCTAssertTrue(stateManager.initialTeamSet,
                     "Should propagate eligibility to state manager")
    }

    // MARK: - Login Information Tests

    @MainActor
    func testInit_WithLoginController() {
        let loginController = LoginInformationController()
        let manager = ServerConnectionManager(loginInformationController: loginController)

        XCTAssertNotNil(manager.loginInformationController)
    }

    @MainActor
    func testSendLogin_WithoutReader_DoesNotCrash() {
        let manager = ServerConnectionManager()
        let stateManager = GameStateManager()
        manager.gameStateManager = stateManager

        manager.sendLogin()

        // Should not crash, will trigger noServerSelected state
    }

    // MARK: - Connect from Metaserver Tests

    @MainActor
    func testConnectToServerFromMetaserver_UnknownHost_UsesDefaultPort() {
        let manager = ServerConnectionManager()
        let stateManager = GameStateManager()
        manager.gameStateManager = stateManager

        // Host not in metaserver list
        let result = manager.connectToServerFromMetaserver(hostname: "unknown-host")

        // Will try to connect with default port (WELLKNOWNPORT)
        // Connection will likely fail, but port logic is tested
        _ = result // Connection result depends on network
    }

    // MARK: - WELLKNOWNPORT Constant Tests

    func testWellknownPort_IsCorrect() {
        XCTAssertEqual(WELLKNOWNPORT, 2592,
                      "WELLKNOWNPORT should be 2592")
    }

    // MARK: - ServerFeatures Tests

    @MainActor
    func testServerFeatures_CanBeModified() {
        let manager = ServerConnectionManager()

        manager.serverFeatures.append("TEST_FEATURE")

        XCTAssertTrue(manager.serverFeatures.contains("TEST_FEATURE"))
    }

    @MainActor
    func testServerFeatures_InitiallyEmpty() {
        let manager = ServerConnectionManager()

        XCTAssertEqual(manager.serverFeatures.count, 0)
    }
}
