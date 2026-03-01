//
//  MessagesViewModelTests.swift
//  NetrekTests
//
//  Unit tests for MessagesViewModel
//

import XCTest
@testable import Netrek

@MainActor
final class MessagesViewModelTests: XCTestCase {

    var sut: MessagesViewModel!
    var mockNetworkSender: MockNetworkSender!
    var mockGameStateProvider: MockGameStateProvider!

    override func setUp() async throws {
        try await super.setUp()
        mockNetworkSender = MockNetworkSender()
        mockGameStateProvider = MockGameStateProvider(gameState: .gameActive)

        sut = MessagesViewModel(
            universe: .universe,
            networkSender: mockNetworkSender,
            gameStateProvider: mockGameStateProvider
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockNetworkSender = nil
        mockGameStateProvider = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_SetsDefaultValues() {
        // Then
        XCTAssertTrue(sut.newMessage.isEmpty)
        XCTAssertTrue(sut.sendToAll)
    }

    func testInitialization_WithoutNetworkSender() {
        // When
        let viewModel = MessagesViewModel(universe: .universe, networkSender: nil)

        // Then
        XCTAssertNotNil(viewModel)
    }

    // MARK: - Send Message Tests

    func testSendMessage_WithMessage_SendsData() {
        // Given
        sut.newMessage = "Hello world"

        // When
        sut.sendMessage()

        // Then
        XCTAssertTrue(mockNetworkSender.didSendData)
        XCTAssertEqual(mockNetworkSender.sendCallCount, 1)
    }

    func testSendMessage_ClearsNewMessage() {
        // Given
        sut.newMessage = "Test message"

        // When
        sut.sendMessage()

        // Then
        XCTAssertTrue(sut.newMessage.isEmpty)
    }

    func testSendMessage_EmptyMessage_DoesNotSend() {
        // Given
        sut.newMessage = ""

        // When
        sut.sendMessage()

        // Then
        XCTAssertFalse(mockNetworkSender.didSendData)
    }

    func testSendMessage_WithoutNetworkSender_DoesNotCrash() {
        // Given
        let viewModel = MessagesViewModel(universe: .universe, networkSender: nil)
        viewModel.newMessage = "Test"

        // When/Then - should not crash
        viewModel.sendMessage()
    }

    func testSendMessageDirectly_WithText_SendsData() {
        // When
        sut.sendMessage(message: "Direct message", toAll: true)

        // Then
        XCTAssertTrue(mockNetworkSender.didSendData)
        XCTAssertEqual(mockNetworkSender.sendCallCount, 1)
    }

    func testSendMessageDirectly_EmptyText_DoesNotSend() {
        // When
        sut.sendMessage(message: "", toAll: true)

        // Then
        XCTAssertFalse(mockNetworkSender.didSendData)
    }

    // MARK: - Toggle Tests

    func testSendToAll_CanBeToggled() {
        // Given
        XCTAssertTrue(sut.sendToAll)

        // When
        sut.sendToAll = false

        // Then
        XCTAssertFalse(sut.sendToAll)
    }

    // MARK: - Mayday Tests

    func testSendMayday_SendsTeamMessage() {
        // When
        sut.sendMayday()

        // Then
        XCTAssertTrue(mockNetworkSender.didSendData)
        XCTAssertEqual(mockNetworkSender.sendCallCount, 1)
    }

    // MARK: - Escort Request Tests

    func testSendEscortRequest_SendsTeamMessage() {
        // When
        sut.sendEscortRequest()

        // Then
        XCTAssertTrue(mockNetworkSender.didSendData)
        XCTAssertEqual(mockNetworkSender.sendCallCount, 1)
    }

    // MARK: - Configuration Tests

    func testConfigure_UpdatesNetworkSender() {
        // Given
        let viewModel = MessagesViewModel(universe: .universe, networkSender: nil)
        let newSender = MockNetworkSender()

        // When
        viewModel.configure(networkSender: newSender, gameStateProvider: nil)
        viewModel.newMessage = "Test"
        viewModel.sendMessage()

        // Then
        XCTAssertTrue(newSender.didSendData)
    }

    // MARK: - Team Property Tests

    func testMyTeam_ReturnsCurrentPlayerTeam() {
        // Given
        let expectedTeam = Universe.universe.players[Universe.universe.me].team

        // Then
        XCTAssertEqual(sut.myTeam, expectedTeam)
    }
}
