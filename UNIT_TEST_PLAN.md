# Unit Test Plan: Protecting Gameplay Dynamics During MVVM/App-Scene Refactor

## Executive Summary

The refactor branch broke gameplay dynamics by changing core dependencies (AppDelegate → ServerConnectionManager) and modifying state flow. This plan creates a comprehensive test suite to protect gameplay dynamics before further refactoring.

## Key Insight from Branch Comparison

The refactor branch made these breaking changes:
1. **Removed GameControllerManager** - Controller input handling deleted
2. **Changed PacketAnalyzer dependency** - `appDelegate` → `connectionManager` (weak reference)
3. **Modified state machine** - Game state transitions now go through different paths
4. **Removed 20Hz timer from AppDelegate** - Update cycle potentially broken
5. **Changed Model classes** - 485 lines removed from Player, Planet, Torpedo, etc.

## Testing Strategy: Test the Contracts, Not the Implementation

We'll create tests that verify **what** the code does (inputs → outputs) rather than **how** it does it. This allows the refactor to change implementation while preserving behavior.

---

## Phase 1: Core Math & Coordinate Conversion (Critical)

These are pure functions - easiest to test, highest impact if broken.

### 1.1 NetrekMath Tests (`NetrekMathTests.swift`)

```swift
// Test: Direction conversion (Netrek 0-255 → radians 0-2π)
func testDirectionNetrek2Radian_Zero()
func testDirectionNetrek2Radian_64_Is_PI_Over_2()
func testDirectionNetrek2Radian_128_Is_PI()
func testDirectionNetrek2Radian_192_Is_3PI_Over_2()
func testDirectionNetrek2Radian_255_ApproachesFullCircle()

// Test: Coordinate conversion (Netrek 0-1000000 → Game 0-10000)
func testNetrekX2GameX_Zero()
func testNetrekX2GameX_MaxValue()
func testNetrekY2GameY_Midpoint()

// Test: Reverse direction calculation (screen coords → Netrek direction)
func testCalculateNetrekDirection_North()
func testCalculateNetrekDirection_East()
func testCalculateNetrekDirection_Southwest()

// Test: String sanitization
func testSanitizeString_RemovesNullBytes()
func testSanitizeString_PreservesValidCharacters()

// Test: Galactic size constants
func testGalacticSize_Is10000()
```

**Files to Test:**
- `Shared/Model/NetrekMath.swift`

---

## Phase 2: Packet Parsing (Critical - Game Breaking if Wrong)

Binary protocol parsing is the heart of the game. Any mistake = corrupted game state.

### 2.1 Packet Size Table Tests (`PacketSizeTests.swift`)

```swift
// Verify PACKET_SIZES array is correct
func testPacketSizes_SP_MESSAGE_Is84()       // Type 1
func testPacketSizes_SP_PLAYER_INFO_Is4()    // Type 2
func testPacketSizes_SP_PLAYER_Is12()        // Type 4
func testPacketSizes_SP_YOU_Is32()           // Type 12
func testPacketSizes_SP_PLANET_Is16()        // Type 15
func testPacketSizes_SP_PICKOK_Is4()         // Type 16
func testPacketSizes_SP_LOGIN_Is104()        // Type 17
func testPacketSizes_AllTypesHaveValidSizes()
```

### 2.2 PacketAnalyzer Framing Tests (`PacketFramingTests.swift`)

```swift
// Test: Partial packet buffering (leftOverData)
func testAnalyze_PartialPacket_BuffersForNextCall()
func testAnalyze_CompletePacket_ProcessesImmediately()
func testAnalyze_MultiplePackets_ProcessesAll()
func testAnalyze_PartialThenComplete_ReassemblesCorrectly()

// Test: Invalid packet handling
func testAnalyze_InvalidPacketType_DoesNotCrash()
func testAnalyze_ZeroLengthPacket_DoesNotCrash()
func testAnalyze_EmptyData_DoesNotCrash()
```

### 2.3 Individual Packet Parsing Tests (`PacketParsingTests.swift`)

```swift
// SP_PLAYER (Type 4) - Position updates
func testParseSpPlayer_ExtractsPlayerId()
func testParseSpPlayer_ExtractsDirection()
func testParseSpPlayer_ExtractsSpeed()
func testParseSpPlayer_ExtractsPosition()
func testParseSpPlayer_ConvertsCoordinates()

// SP_YOU (Type 12) - Own ship status
func testParseSpYou_ExtractsPlayerNumber()
func testParseSpYou_ExtractsFlags()
func testParseSpYou_ExtractsDamage()
func testParseSpYou_ExtractsFuel()
func testParseSpYou_ExtractsShieldStrength()
func testParseSpYou_ExtractsAlertCondition()

// SP_FLAGS (Type 18) - Player flags
func testParseSpFlags_ExtractsTractor()
func testParseSpFlags_ExtractsShieldFlag()
func testParseSpFlags_ExtractsCloakFlag()

// SP_PLANET (Type 15) - Planet state
func testParseSpPlanet_ExtractsPlanetId()
func testParseSpPlanet_ExtractsOwner()
func testParseSpPlanet_ExtractsArmies()
func testParseSpPlanet_ExtractsFlags()
```

**Files to Test:**
- `Shared/Communication/PacketAnalyzer.swift`
- `Shared/Communication/packets.swift`
- `Shared/Global/Globals.swift` (PACKET_SIZES)

---

## Phase 3: Model State Updates (Critical)

Verify that model objects update correctly from packet data.

### 3.1 Player State Tests (`PlayerStateTests.swift`)

```swift
// Direction wrapping (the 270° → 1° smooth animation bug)
func testPlayerUpdate_DirectionWrapping_359To1()
func testPlayerUpdate_DirectionWrapping_1To359()
func testPlayerUpdate_DirectionNoWrapping_90To180()

// Position updates
func testPlayerUpdate_PositionUpdates()
func testPlayerUpdate_SpeedUpdates()

// Flag decoding (32-bit field)
func testPlayerFlags_Shield_IsCorrect()
func testPlayerFlags_Cloak_IsCorrect()
func testPlayerFlags_Orbit_IsCorrect()
func testPlayerFlags_Repair_IsCorrect()
func testPlayerFlags_AlertGreen_IsCorrect()
func testPlayerFlags_AlertYellow_IsCorrect()
func testPlayerFlags_AlertRed_IsCorrect()
func testPlayerFlags_PlayerLock_IsCorrect()
func testPlayerFlags_PlanetLock_IsCorrect()
func testPlayerFlags_Tractor_IsCorrect()
func testPlayerFlags_Pressor_IsCorrect()

// Slot status transitions
func testSlotStatus_Free_To_Outfit()
func testSlotStatus_Outfit_To_Alive()
func testSlotStatus_Alive_To_Explode()
func testSlotStatus_Explode_To_Dead()

// War/hostile masks
func testPlayerWar_Federation_BitMask()
func testPlayerWar_Roman_BitMask()
func testPlayerWar_Kazari_BitMask()
func testPlayerWar_Orion_BitMask()
```

### 3.2 Planet State Tests (`PlanetStateTests.swift`)

```swift
func testPlanetUpdate_OwnerFromTeamValue()
func testPlanetUpdate_ArmiesCount()
func testPlanetUpdate_AgriFlag()
func testPlanetUpdate_FuelFlag()
func testPlanetUpdate_RepairFlag()
func testPlanetUpdate_SeenByTeam()
```

### 3.3 Weapon State Tests (`WeaponStateTests.swift`)

```swift
// Torpedo lifecycle
func testTorpedoStatus_Inactive_Is0()
func testTorpedoStatus_Active_Is1()
func testTorpedoStatus_Exploding_Is2or3()
func testTorpedoWar_DeterminesColor()

// Laser lifecycle
func testLaserStatus_Inactive_Is0()
func testLaserStatus_Hit_Is1()
func testLaserStatus_Miss_Is2()
func testLaserStatus_HitPlasma_Is4()

// Plasma lifecycle
func testPlasmaStatus_SimilarToTorpedo()
```

**Files to Test:**
- `Shared/Model/Player.swift`
- `Shared/Model/Planet.swift`
- `Shared/Model/Torpedo.swift`
- `Shared/Model/Laser.swift`
- `Shared/Model/Plasma.swift`

---

## Phase 4: Universe Visibility & Filtering (Important)

These affect what the player sees on screen.

### 4.1 Universe Filtering Tests (`UniverseFilteringTests.swift`)

```swift
// Visible players (within visual range)
func testVisiblePlayers_InRange_Included()
func testVisiblePlayers_OutOfRange_Excluded()
func testVisiblePlayers_OnBoundary_Included()

// Visible torpedoes
func testVisibleTorpedoes_Active_InRange_Included()
func testVisibleTorpedoes_Inactive_Excluded()

// Visible planets
func testVisiblePlanets_InRange_Included()

// Team filtering
func testFederationPlayers_CountsCorrectly()
func testRomanPlayers_CountsCorrectly()
func testKazariPlayers_CountsCorrectly()
func testOrionPlayers_CountsCorrectly()

// Alive/exploding filters
func testAlivePlayers_ExcludesDead()
func testExplodingPlayers_OnlyExploding()
```

**Files to Test:**
- `Shared/Model/Universe.swift`

---

## Phase 5: Outgoing Packet Construction (Important)

Verify we send correct commands to the server.

### 5.1 MakePacket Tests (`MakePacketTests.swift`)

```swift
// Speed commands
func testCpSpeed_PacketType_Is2()
func testCpSpeed_SpeedValue_EncodedCorrectly()
func testCpSpeed_MaxSpeed_Capped()

// Direction commands
func testCpDirection_PacketType_Is3()
func testCpDirection_Direction_EncodedAs0to255()

// Weapon commands
func testCpLaser_PacketType_Is4()
func testCpLaser_Direction_EncodedCorrectly()
func testCpTorp_PacketType_Is6()
func testCpPlasma_PacketType_Is5()

// Ship selection
func testCpOutfit_TeamMapping_FederationIs0()
func testCpOutfit_TeamMapping_RomanIs1()
func testCpOutfit_TeamMapping_KazariIs2()
func testCpOutfit_TeamMapping_OrionIs3()
func testCpOutfit_ShipType_EncodedCorrectly()

// String packing
func testMake16Tuple_ShortString_PadsWithNulls()
func testMake16Tuple_ExactLength_NoTruncation()
func testMake16Tuple_LongString_Truncates()

// Login packet
func testCpLogin_ContainsUsername()
func testCpLogin_ContainsPassword()
```

**Files to Test:**
- `Shared/Communication/MakePacket.swift`

---

## Phase 6: Game State Machine (Important)

### 6.1 Game State Transition Tests (`GameStateTests.swift`)

```swift
// Valid transitions
func testGameState_NoServerSelected_To_ServerSelected()
func testGameState_ServerSelected_To_ServerConnected()
func testGameState_ServerConnected_To_ServerSlotFound()
func testGameState_ServerSlotFound_To_LoginAccepted()
func testGameState_LoginAccepted_To_GameActive()

// Reset transitions
func testGameState_AnyState_To_NoServerSelected_OnDisconnect()

// Packet triggers
func testSpYou_Triggers_ServerSlotFound()
func testSpLogin_Accept1_Triggers_LoginAccepted()
func testSpPickok_State1_Triggers_GameActive()
```

---

## Phase 7: Game Controller Input (If Restoring)

### 7.1 Controller Input Tests (`GameControllerTests.swift`)

```swift
// Dead zone handling
func testDeadZone_SmallInput_Ignored()
func testDeadZone_LargeInput_Passed()

// Stick to direction conversion
func testLeftStick_ToCourse_North()
func testLeftStick_ToCourse_East()
func testRightStick_ToAim_Conversion()

// Speed controls
func testLeftShoulder_DecreasesSpeed()
func testRightShoulder_IncreasesSpeed()
```

**Files to Test (if restored):**
- `Shared/Controllers/GameControllerManager.swift`
- `Shared/Controllers/GameControllerInputState.swift`

---

## Implementation Priority

### Tier 1: Must Have Before Any Refactor (Week 1)
1. **NetrekMathTests** - Pure functions, no dependencies
2. **PacketSizeTests** - Critical protocol data
3. **PacketFramingTests** - Data reassembly
4. **PlayerStateTests** - Direction wrapping, flag decoding
5. **MakePacketTests** - Outgoing command correctness

### Tier 2: Should Have (Week 2)
6. **PacketParsingTests** - Individual packet types
7. **PlanetStateTests** - Planet updates
8. **WeaponStateTests** - Torpedo/laser lifecycle
9. **UniverseFilteringTests** - Visibility calculations

### Tier 3: Nice to Have (Week 3)
10. **GameStateTests** - State machine transitions
11. **GameControllerTests** - Controller input (if restoring)

---

## Test Infrastructure Requirements

### 1. Test Target Setup

Add to `Netrek2.xcodeproj`:
- `NetrekCoreTests` target for Shared code
- Include only `Shared/` files (no AppDelegate dependencies)

### 2. Test Helpers

```swift
// TestFixtures/PacketBuilder.swift
struct PacketBuilder {
    static func spPlayer(playerId: Int, direction: UInt8, speed: Int, x: Int, y: Int) -> Data
    static func spYou(playerId: Int, flags: UInt32, damage: Int, fuel: Int) -> Data
    static func spPlanet(planetId: Int, owner: Int, armies: Int, flags: UInt16) -> Data
}
```

```swift
// TestFixtures/TestUniverse.swift
extension Universe {
    static func createTestInstance() -> Universe
    func reset()
}
```

### 3. Mocks Required

```swift
// Mocks/MockTcpReader.swift
class MockTcpReader: TcpReaderProtocol {
    var sentPackets: [Data] = []
    func send(_ data: Data) { sentPackets.append(data) }
}
```

---

## Success Criteria

Before proceeding with MVVM/App-Scene refactor:

1. **All Tier 1 tests pass** on develop branch
2. **Test coverage >80%** for:
   - NetrekMath
   - Player flag decoding
   - Packet framing
   - Direction wrapping
3. **No gameplay-affecting code changes** without corresponding test

---

## Files to Create

```
NetrekCoreTests/
├── Math/
│   └── NetrekMathTests.swift
├── Packets/
│   ├── PacketSizeTests.swift
│   ├── PacketFramingTests.swift
│   └── PacketParsingTests.swift
├── Models/
│   ├── PlayerStateTests.swift
│   ├── PlanetStateTests.swift
│   └── WeaponStateTests.swift
├── Universe/
│   └── UniverseFilteringTests.swift
├── Commands/
│   └── MakePacketTests.swift
├── GameState/
│   └── GameStateTests.swift
└── TestFixtures/
    ├── PacketBuilder.swift
    ├── TestUniverse.swift
    └── Mocks/
        └── MockTcpReader.swift
```

---

## Refactoring Safety Process

1. **Run all tests** on develop branch (baseline)
2. **Make refactor changes** (small, focused commits)
3. **Run all tests** after each change
4. **If tests fail**: fix the refactor, not the test
5. **If behavior must change**: update test and document why

This ensures gameplay dynamics remain intact while architectural changes proceed safely.
