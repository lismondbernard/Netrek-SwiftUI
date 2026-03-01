# NetrekCoreTests Target Setup

This guide explains how to add the `NetrekCoreTests` unit test target to the Xcode project.

## Quick Setup in Xcode

1. **Open the project** in Xcode: `Netrek2.xcodeproj`

2. **Add a new Unit Test target:**
   - File → New → Target...
   - Choose "Unit Testing Bundle" under iOS or macOS
   - Name it `NetrekCoreTests`
   - Set the "Target to be Tested" to `Netrek` (macOS target)
   - Click Finish

3. **Configure the test target:**
   - Select the `NetrekCoreTests` target in the project navigator
   - Go to "Build Settings"
   - Set "iOS Deployment Target" to match your main target (iOS 17.0+)
   - Set "macOS Deployment Target" to match (macOS 14.0+)

4. **Add existing test files:**
   - Right-click on `NetrekCoreTests` group in Project Navigator
   - Choose "Add Files to 'Netrek2'..."
   - Navigate to `NetrekCoreTests/` directory
   - Select all `.swift` files and the `Info.plist`
   - Make sure "NetrekCoreTests" is checked in "Add to targets"
   - Click "Add"

5. **Add Shared files to test target:**
   The test target needs access to the Shared code. In the target's "Build Phases":
   - Go to "Compile Sources"
   - Click "+" and add all necessary files from `Shared/`:
     - `Shared/Model/NetrekMath.swift`
     - `Shared/Model/Player.swift`
     - `Shared/Model/Planet.swift`
     - `Shared/Model/Torpedo.swift`
     - `Shared/Model/Laser.swift`
     - `Shared/Model/Plasma.swift`
     - `Shared/Model/Universe.swift`
     - `Shared/Communication/MakePacket.swift`
     - `Shared/Communication/packets.swift`
     - `Shared/Communication/PacketAnalyzer.swift`
     - `Shared/Global/Globals.swift`
     - `Shared/Enumerations/*.swift` (all enum files)

   **Alternative (Recommended):** Instead of adding files individually, you can:
   - Select the main `Netrek` target
   - Go to Build Settings → Defines Module = YES
   - In tests, use `@testable import Netrek`

6. **Run the tests:**
   - Product → Test (⌘U)
   - Or use the Test Navigator (⌘6)

## Test File Structure

```
NetrekCoreTests/
├── Info.plist
├── TEST_TARGET_SETUP.md (this file)
├── NetrekMathTests.swift           # Math & coordinate tests
├── Math/                           # (alternative location)
├── Packets/
│   ├── PacketSizeTests.swift       # Protocol size verification
│   └── PacketFramingTests.swift    # Packet reassembly tests
├── Models/
│   └── PlayerFlagTests.swift       # Flag decoding tests
├── Commands/
│   └── MakePacketTests.swift       # Outgoing packet tests
└── TestFixtures/
    └── PacketBuilder.swift         # Test data builders
```

## Running Specific Tests

- **Run all tests:** ⌘U
- **Run single test file:** Click the diamond icon next to the test class
- **Run single test:** Click the diamond icon next to the test method
- **Test Navigator:** ⌘6 to see all tests

## Common Issues

### "No such module 'XCTest'"
This error appears before the test target is properly configured. It resolves once you:
1. Add the test target to the project
2. Add the test files to the target

### "@testable import Netrek" fails
Make sure:
1. The main target has "Defines Module" = YES
2. The test target has the main target as its "Host Application" or "Target to be Tested"

### Tests can't find Shared types
Either:
1. Add Shared files to the test target's "Compile Sources"
2. Or ensure the main target is properly linked as a host application

## Test Categories

| Test File | What It Tests | Priority |
|-----------|---------------|----------|
| NetrekMathTests | Coordinate conversion, direction, string sanitization | Critical |
| PacketSizeTests | PACKET_SIZES array correctness | Critical |
| PacketFramingTests | Packet reassembly logic | Critical |
| PlayerFlagTests | 32-bit flag decoding, team masks | Critical |
| MakePacketTests | Outgoing packet construction | Critical |

## Next Steps After Setup

1. Run all tests: `⌘U`
2. Verify all tests pass on `develop` branch
3. Create baseline before refactoring
4. Run tests after each refactor change
