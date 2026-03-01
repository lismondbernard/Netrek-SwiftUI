# SwiftLint Setup Guide

## What is SwiftLint?

SwiftLint is a tool to enforce Swift style and conventions, based on the community-accepted [Swift Style Guide](https://github.com/raywenderlich/swift-style-guide).

## Installation

### Option 1: Homebrew (Recommended)

```bash
brew install swiftlint
```

### Option 2: Mint

```bash
mint install realm/SwiftLint
```

### Option 3: CocoaPods

Add to your `Podfile`:
```ruby
pod 'SwiftLint'
```

## Verification

After installation, verify SwiftLint is available:

```bash
swiftlint version
```

## Running SwiftLint

### Command Line

From the project root directory:

```bash
# Lint all files
swiftlint

# Lint and show all violations
swiftlint --strict

# Auto-fix violations where possible
swiftlint --fix

# Analyze with additional analyzer rules (slower, more thorough)
swiftlint analyze
```

### Xcode Integration

Add a Run Script Phase to your Xcode target:

1. Select the **Netrek** target in Xcode
2. Go to **Build Phases**
3. Click **+** → **New Run Script Phase**
4. Name it "SwiftLint"
5. Add the script:

```bash
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

6. Move the SwiftLint phase **before** "Compile Sources"

### GitHub Actions / CI Integration

Add to `.github/workflows/swift.yml`:

```yaml
- name: SwiftLint
  run: |
    brew install swiftlint
    swiftlint --strict
```

## Configuration

The project uses a custom `.swiftlint.yml` configuration file that:

- **Enforces** Swift best practices and style guidelines
- **Allows** game-specific patterns (longer functions for packet parsing)
- **Excludes** generated files and dependencies
- **Enables** analyzer rules for deeper code analysis
- **Customizes** rules to fit Netrek's architecture

### Key Configuration Choices

**Relaxed Rules:**
- `function_body_length`: 100/200 (packet parsing functions are necessarily long)
- `cyclomatic_complexity`: 20/30 (game logic can be complex)
- `line_length`: 140/150 (allow longer lines for readability)
- `identifier_name`: Allow short names like `id`, `me`, `x`, `y`

**Strict Rules:**
- `weak_delegate`: Ensure delegates are marked weak
- `force_unwrap`: Warning for force unwraps
- `unused_declaration`: Find unused code
- `vertical_whitespace`: Max 2 blank lines

**Custom Rules:**
- `no_direct_print`: Encourage GameLogger usage
- `discourage_force_unwrap`: Prefer optional binding
- `future_comments`: Use `FUTURE:` prefix instead of `TODO:`

## Common Violations and Fixes

### Trailing Whitespace

**Violation:**
```swift
let name = "Player"
```

**Fix:**
```swift
let name = "Player"
```

**Auto-fix:** `swiftlint --fix`

### Force Unwrapping

**Violation:**
```swift
let player = universe.players[id]!
```

**Fix:**
```swift
guard let player = universe.players[id] else { return }
```

### Vertical Whitespace

**Violation:**
```swift
func foo() {



    // Too many blank lines
}
```

**Fix:**
```swift
func foo() {

    // Max 2 blank lines
}
```

### Weak Delegate

**Violation:**
```swift
var delegate: SomeDelegate?
```

**Fix:**
```swift
weak var delegate: SomeDelegate?
```

## Suppressing Warnings

Use `swiftlint:disable` comments sparingly:

```swift
// swiftlint:disable force_cast
let player = entity as! Player
// swiftlint:enable force_cast
```

Or for a single line:
```swift
let player = entity as! Player // swiftlint:disable:this force_cast
```

## Excluding Files

Add to `.swiftlint.yml`:

```yaml
excluded:
  - Pods
  - Generated
  - ThirdParty
```

## CI/CD Integration

SwiftLint can fail builds on errors:

```bash
swiftlint lint --strict
```

This returns non-zero exit code if any violations exist.

## Resources

- [SwiftLint GitHub](https://github.com/realm/SwiftLint)
- [SwiftLint Rules Reference](https://realm.github.io/SwiftLint/rule-directory.html)
- [Swift Style Guide](https://google.github.io/swift/)

## Project Status

**SwiftLint Configuration:** ✅ Complete (`.swiftlint.yml`)
**Installation:** ⏳ Required (see Installation section above)
**Xcode Integration:** ⏳ Optional (see Xcode Integration section)
**Violations Fixed:** ⏳ Pending installation

Once SwiftLint is installed, run:

```bash
swiftlint
```

to see current violations and begin fixing them.
