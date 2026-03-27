# Contributing to ExpenseFlow

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the ExpenseFlow project.

## Code of Conduct

We are committed to providing a welcoming and inspiring community for all. Please read and adhere to our Code of Conduct:
- Be respectful and inclusive
- Welcome diverse perspectives
- Report unacceptable behavior to maintainers

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0 SDK
- Swift 5.9 or later
- Git

### Setup Development Environment
1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/ExpenseFlow.git`
3. Add upstream: `git remote add upstream https://github.com/ORIGINAL_OWNER/ExpenseFlow.git`
4. Create a feature branch: `git checkout -b feature/my-feature`

## Development Guidelines

### Code Style
- Follow Swift language guidelines (https://swift.org/documentation/#the-swift-programming-language)
- Use 4 spaces for indentation
- Use camelCase for variables and functions
- Use PascalCase for types and protocols
- Keep lines under 120 characters where practical

### File Organization
```
Sources/
├── Models/           # Data models (Codable, Equatable)
├── Views/            # SwiftUI view components
├── Components/       # Reusable UI components
├── Stores/          # ViewModel/Store classes
└── Utilities/       # Helper functions and extensions
```

### Naming Conventions
- Files: PascalCase (e.g., `AuthStore.swift`)
- Classes/Structs: PascalCase (e.g., `ExpenseStore`)
- Functions/Variables: camelCase (e.g., `addExpense()`)
- Private members: prefix with underscore (e.g., `_private`)
- Constants: UPPER_SNAKE_CASE or camelCase (e.g., `let maxRetries = 3`)

### Comments
- Write self-documenting code; avoid unnecessary comments
- Use comments to explain **why**, not **what**
- Use MARK comments for logical sections:
  ```swift
  // MARK: - Public Methods
  // MARK: - Private Methods
  ```

### Error Handling
- Use proper error types with LocalizedError
- Handle all file I/O operations with do-catch
- Log errors for debugging: `AppLogger.error("message", error: error)`
- Provide user-friendly error messages

### Testing
- Write unit tests for business logic
- Test all validation functions
- Mock external dependencies
- Use XCTest framework

Example test:
```swift
import XCTest
@testable import ExpenseFlow

class AuthStoreTests: XCTestCase {
    var store: AuthStore!
    
    override func setUp() {
        super.setUp()
        store = AuthStore()
    }
    
    func testValidEmailFormat() {
        XCTAssertTrue(store.isValidEmail("user@example.com"))
        XCTAssertFalse(store.isValidEmail("invalid.email"))
    }
}
```

## Commit Guidelines

- Use descriptive commit messages
- Start with imperative mood: "Add feature" not "Added feature"
- Reference issues: "Fix bug in auth (Fixes #123)"
- Keep commits focused and atomic

Example:
```
Add expense filtering by date range

- Add DateRange model
- Update ExpenseStore filter methods
- Add tests for date filtering

Fixes #456
```

## Pull Request Process

1. **Update your branch**: `git pull upstream main`
2. **Create descriptive PR title**: "Add feature X" or "Fix bug Y"
3. **Fill out PR template** with:
   - What changes were made
   - Why were these changes made
   - How to test the changes
   - Any breaking changes
4. **Ensure CI passes**: All GitHub Actions workflows must succeed
5. **Request review** from maintainers
6. **Address feedback**: Push updates to the same branch
7. **Merge**: Maintainer will merge after approval

### PR Title Format
- `[Feature]`: New functionality
- `[Fix]`: Bug fixes
- `[Refactor]`: Code restructuring without behavior change
- `[Docs]`: Documentation updates
- `[Chore]`: Maintenance tasks

Example: `[Feature] Add expense search functionality`

## Reporting Issues

### Bug Report
Include:
- iOS version and device/simulator
- Xcode version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Logs or error messages
- Screenshots if applicable

### Feature Request
Include:
- Use case and motivation
- Proposed solution
- Alternative solutions considered
- Examples from other apps

## Documentation

- Update README.md for user-facing changes
- Add code comments for complex logic
- Update CHANGELOG.md for releases
- Keep API documentation current

## Release Process

1. Update version number in `project.yml`
2. Update CHANGELOG.md
3. Create Git tag: `git tag v1.0.0`
4. Push tag: `git push origin v1.0.0`
5. Create GitHub Release with release notes

## Questions?

- 📧 Email: support@example.com
- 💬 Discussions: GitHub Discussions
- 🐛 Issues: GitHub Issues

---

Thank you for contributing to ExpenseFlow! 🎉
