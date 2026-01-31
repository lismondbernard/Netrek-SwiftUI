//
//  KeymapControllerTests.swift
//  NetrekCoreTests
//
//  Tests for KeymapController command execution.
//  Validates that commands send correct packets and respect game state guards.
//

import XCTest
@testable import Netrek

final class KeymapControllerTests: XCTestCase {

    var keymapController: KeymapController!
    var mockSender: MockNetworkSender!
    var mockStateProvider: MockGameStateProvider!

    override func setUp() {
        super.setUp()
        mockSender = MockNetworkSender()
        mockStateProvider = MockGameStateProvider(gameState: .gameActive)
        keymapController = KeymapController()
        keymapController.networkSender = mockSender
        keymapController.gameStateProvider = mockStateProvider
    }

    override func tearDown() {
        keymapController = nil
        mockSender = nil
        mockStateProvider = nil
        super.tearDown()
    }

    // MARK: - Default Keymap Tests

    func testDefaultKeymaps_TorpedoMapped() {
        XCTAssertEqual(keymapController.keymap[.tKey], .fireTorpedo)
    }

    func testDefaultKeymaps_LaserMapped() {
        XCTAssertEqual(keymapController.keymap[.pKey], .fireLaser)
    }

    func testDefaultKeymaps_ShieldsMapped() {
        XCTAssertEqual(keymapController.keymap[.sKey], .toggleShields)
    }

    func testDefaultKeymaps_CloakMapped() {
        XCTAssertEqual(keymapController.keymap[.cKey], .cloak)
    }

    func testDefaultKeymaps_SpeedKeys() {
        XCTAssertEqual(keymapController.keymap[.zeroKey], .speedZero)
        XCTAssertEqual(keymapController.keymap[.fiveKey], .speedFive)
        XCTAssertEqual(keymapController.keymap[.nineKey], .speedNine)
    }

    func testDefaultKeymaps_MouseButtons() {
        XCTAssertEqual(keymapController.keymap[.leftMouse], .fireTorpedo)
        XCTAssertEqual(keymapController.keymap[.rightMouse], .setCourse)
        XCTAssertEqual(keymapController.keymap[.otherMouse], .fireLaser)
    }

    // MARK: - Speed Command Tests

    func testSpeedZero_SendsPacket() {
        keymapController.execute(.speedZero, location: nil)
        XCTAssertTrue(mockSender.didSendData, "Speed 0 should send data")
        XCTAssertEqual(mockSender.sendCallCount, 1)
    }

    func testSpeedFive_SendsPacket() {
        keymapController.execute(.speedFive, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testSetSpeed_SendsCorrectPacket() {
        keymapController.setSpeed(5)
        XCTAssertEqual(mockSender.sendCallCount, 1)
        // Verify the packet matches what MakePacket.cpSpeed produces
        if let expected = MakePacket.cpSpeed(speed: 5) {
            XCTAssertEqual(mockSender.lastSentData, expected)
        }
    }

    func testSpeedIncrease_SendsPacket() {
        let me = Universe.universe.me
        Universe.universe.players[me].update(directionNetrek: 0, speed: 5, positionX: 5000, positionY: 5000)
        keymapController.execute(.speedIncrease, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testSpeedDecrease_SendsPacket() {
        let me = Universe.universe.me
        Universe.universe.players[me].update(directionNetrek: 0, speed: 5, positionX: 5000, positionY: 5000)
        keymapController.execute(.speedDecrease, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testSpeedDecrease_AtZero_DoesNotSend() {
        let me = Universe.universe.me
        Universe.universe.players[me].update(directionNetrek: 0, speed: 0, positionX: 5000, positionY: 5000)
        keymapController.execute(.speedDecrease, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    func testSpeedIncrease_AtMax_DoesNotSend() {
        let me = Universe.universe.me
        Universe.universe.players[me].update(directionNetrek: 0, speed: 12, positionX: 5000, positionY: 5000)
        keymapController.execute(.speedIncrease, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    // MARK: - Weapon Command Tests

    func testFireTorpedo_GameActive_SendsPacket() {
        let location = CGPoint(x: 5000, y: 5000)
        keymapController.execute(.fireTorpedo, location: location)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testFireTorpedo_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .loginAccepted)
        let location = CGPoint(x: 5000, y: 5000)
        keymapController.execute(.fireTorpedo, location: location)
        XCTAssertFalse(mockSender.didSendData)
    }

    func testFireTorpedo_NoLocation_DoesNotSend() {
        keymapController.execute(.fireTorpedo, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    func testFireLaser_GameActive_SendsPacket() {
        let location = CGPoint(x: 5000, y: 5000)
        keymapController.execute(.fireLaser, location: location)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testFireLaser_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .serverConnected)
        let location = CGPoint(x: 5000, y: 5000)
        keymapController.execute(.fireLaser, location: location)
        XCTAssertFalse(mockSender.didSendData)
    }

    func testFirePlasma_GameActive_SendsPacket() {
        let location = CGPoint(x: 5000, y: 5000)
        keymapController.execute(.firePlasma, location: location)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testFirePlasma_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .noServerSelected)
        let location = CGPoint(x: 5000, y: 5000)
        keymapController.execute(.firePlasma, location: location)
        XCTAssertFalse(mockSender.didSendData)
    }

    // MARK: - Shield Command Tests

    func testToggleShields_GameActive_SendsPacket() {
        keymapController.execute(.toggleShields, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testToggleShields_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .loginAccepted)
        keymapController.execute(.toggleShields, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    func testRaiseShields_GameActive_SendsPacket() {
        keymapController.execute(.raiseShields, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testRaiseShields_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .serverSlotFound)
        keymapController.execute(.raiseShields, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    func testLowerShields_GameActive_SendsPacket() {
        keymapController.execute(.lowerShields, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testLowerShields_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .serverConnected)
        keymapController.execute(.lowerShields, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    // MARK: - Cloak Command Tests

    func testCloak_GameActive_SendsPacket() {
        keymapController.execute(.cloak, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testCloak_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .noServerSelected)
        keymapController.execute(.cloak, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    func testCloakUp_GameActive_SendsPacket() {
        keymapController.execute(.cloakUp, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testCloakUp_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .loginAccepted)
        keymapController.execute(.cloakUp, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    func testCloakDown_GameActive_SendsPacket() {
        keymapController.execute(.cloakDown, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testCloakDown_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .serverSelected)
        keymapController.execute(.cloakDown, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    // MARK: - Detonate Command Tests

    func testDetEnemy_GameActive_SendsPacket() {
        keymapController.execute(.detEnemy, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testDetEnemy_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .loginAccepted)
        keymapController.execute(.detEnemy, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    func testDetOwn_GameActive_SendsMultiplePackets() {
        keymapController.execute(.detOwn, location: nil)
        // Should send 8 packets (one per torpedo slot)
        XCTAssertEqual(mockSender.sendCallCount, 8)
    }

    func testDetOwn_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .loginAccepted)
        keymapController.execute(.detOwn, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    // MARK: - Navigation Command Tests

    func testSetCourse_WithLocation_SendsPacket() {
        let location = CGPoint(x: 5000, y: 5000)
        keymapController.execute(.setCourse, location: location)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testSetCourse_NoLocation_DoesNotSend() {
        keymapController.execute(.setCourse, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    func testOrbit_SendsPacket() {
        keymapController.execute(.orbit, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    // MARK: - Repair Command Tests

    func testRepair_GameActive_SendsPacket() {
        keymapController.execute(.repair, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testRepair_GameNotActive_DoesNotSend() {
        mockStateProvider.transition(to: .loginAccepted)
        keymapController.execute(.repair, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    // MARK: - Beam Command Tests

    func testBeamUp_SendsPacket() {
        keymapController.execute(.beamUp, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testBeamDown_SendsPacket() {
        keymapController.execute(.beamDown, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testBomb_SendsPacket() {
        keymapController.execute(.bomb, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    // MARK: - Tractor/Pressor Tests

    func testTractorPressorOff_SendsTwoPackets() {
        keymapController.execute(.tractorPressorOff, location: nil)
        XCTAssertEqual(mockSender.sendCallCount, 2)
    }

    // MARK: - Other Commands

    func testQuitGame_SendsPacket() {
        keymapController.execute(.quitGame, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testPracticeRobot_SendsPacket() {
        keymapController.execute(.practiceRobot, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testCoup_SendsPacket() {
        keymapController.execute(.coup, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testDockingPermission_SendsPacket() {
        keymapController.execute(.dockingPermission, location: nil)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testNothing_DoesNotSend() {
        keymapController.execute(.nothing, location: nil)
        XCTAssertFalse(mockSender.didSendData)
    }

    // MARK: - Control-to-Command Execution

    func testExecuteControl_MapsToCommand() {
        // .tKey maps to .fireTorpedo which requires gameActive + location
        let location = CGPoint(x: 5000, y: 5000)
        keymapController.execute(.tKey, location: location)
        XCTAssertTrue(mockSender.didSendData)
    }

    func testExecuteControl_UnmappedControl_DoesNotSend() {
        // Remove a mapping and verify nothing happens
        keymapController.keymap.removeAll()
        keymapController.execute(.tKey, location: CGPoint(x: 5000, y: 5000))
        XCTAssertFalse(mockSender.didSendData)
    }

    // MARK: - Keymap Persistence

    func testSetKeymap_UpdatesMapping() {
        keymapController.setKeymap(control: .aKey, command: .fireTorpedo)
        XCTAssertEqual(keymapController.keymap[.aKey], .fireTorpedo)
    }

    func testResetKeymaps_RestoresDefaults() {
        keymapController.setKeymap(control: .aKey, command: .fireTorpedo)
        keymapController.resetKeymaps()
        XCTAssertEqual(keymapController.keymap[.aKey], .nothing)
    }

    // MARK: - NetworkSender nil safety

    func testExecute_NilNetworkSender_DoesNotCrash() {
        keymapController.networkSender = nil
        keymapController.execute(.speedZero, location: nil)
        // Should not crash, just silently do nothing
    }

    func testExecute_NilGameStateProvider_GuardRejects() {
        keymapController.gameStateProvider = nil
        // Commands guarded by gameState should not send
        keymapController.execute(.fireTorpedo, location: CGPoint(x: 5000, y: 5000))
        XCTAssertFalse(mockSender.didSendData)
    }
}
