//
//  ViewModelFactoryTests.swift
//  NetrekTests
//
//  Unit tests for ViewModelFactory
//

import XCTest
@testable import Netrek

@MainActor
final class ViewModelFactoryTests: XCTestCase {

    var mockNetworkSender: MockNetworkSender!
    var mockCommandExecutor: MockCommandExecutor!
    var mockGameStateProvider: MockGameStateProvider!

    override func setUp() async throws {
        try await super.setUp()
        mockNetworkSender = MockNetworkSender()
        mockCommandExecutor = MockCommandExecutor()
        mockGameStateProvider = MockGameStateProvider()
    }

    override func tearDown() async throws {
        mockNetworkSender = nil
        mockCommandExecutor = nil
        mockGameStateProvider = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testShared_ReturnsSameInstance() {
        // When
        let instance1 = ViewModelFactory.shared
        let instance2 = ViewModelFactory.shared

        // Then
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Factory Method Tests

    func testMakeTacticalViewModel_ReturnsViewModel() {
        // When
        let viewModel = ViewModelFactory.shared.makeTacticalViewModel()

        // Then
        XCTAssertNotNil(viewModel)
    }

    func testMakeStrategicViewModel_ReturnsViewModel() {
        // When
        let viewModel = ViewModelFactory.shared.makeStrategicViewModel()

        // Then
        XCTAssertNotNil(viewModel)
    }

    func testMakeMessagesViewModel_ReturnsViewModel() {
        // When
        let viewModel = ViewModelFactory.shared.makeMessagesViewModel()

        // Then
        XCTAssertNotNil(viewModel)
    }

    func testMakeStatisticsViewModel_ReturnsViewModel() {
        // When
        let viewModel = ViewModelFactory.shared.makeStatisticsViewModel()

        // Then
        XCTAssertNotNil(viewModel)
    }

    // MARK: - Configuration Tests

    func testConfigure_SetsUpDependencies() {
        // Given
        let factory = ViewModelFactory.shared

        // When
        factory.configure(
            commandExecutor: mockCommandExecutor,
            networkSender: mockNetworkSender,
            gameStateProvider: mockGameStateProvider
        )

        // Then - create a ViewModel and verify it works
        let messagesVM = factory.makeMessagesViewModel()
        messagesVM.newMessage = "Test"
        messagesVM.sendMessage()

        // The message should have been sent through our mock
        XCTAssertTrue(mockNetworkSender.didSendData)
    }

    #if DEBUG
    // MARK: - Testing Support Tests

    func testForTesting_ReturnsConfiguredFactory() {
        // When
        let testFactory = ViewModelFactory.forTesting(
            universe: .universe,
            commandExecutor: mockCommandExecutor,
            networkSender: mockNetworkSender
        )

        // Then
        XCTAssertNotNil(testFactory)

        // Should be able to create ViewModels
        let viewModel = testFactory.makeTacticalViewModel()
        XCTAssertNotNil(viewModel)
    }
    #endif
}
