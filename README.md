# ExpenseFlow

A modern, production-ready iOS expense tracking application built with SwiftUI and MVVM architecture.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square)
![iOS](https://img.shields.io/badge/iOS-16.0+-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

## Features

✅ **Track Expenses** - Log expenses by category with date and amount
✅ **Categorization** - 8+ predefined expense categories (Food, Transport, Health, etc.)
✅ **Analytics Dashboard** - View spending trends with monthly and category breakdowns
✅ **Budget Management** - Set and monitor monthly budget with configurable alerts
✅ **Secure Authentication** - Email-based login with Keychain-stored credentials
✅ **Local Storage** - All data stored securely on device (no cloud required)
✅ **Offline-First** - Works completely offline with automatic local persistence
✅ **Customizable Settings** - Theme (Light/Dark/System), week start, currency, notifications
✅ **Production Ready** - Comprehensive error handling, logging, and data validation
✅ **Privacy-Focused** - No tracking, no ads, all data stays on device

## Requirements

- **Xcode:** 15.0 or later
- **iOS:** 16.0 or later
- **Swift:** 5.9 or later
- **macOS:** 12.0 or later (for development)

## Installation

### Option 1: Using Xcode

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/ExpenseFlow.git
   cd ExpenseFlow
   ```

2. **Install dependencies** (if using CocoaPods):
   ```bash
   pod install
   ```

3. **Open the project:**
   ```bash
   open ExpenseFlow.xcodeproj
   # or if using CocoaPods:
   open ExpenseFlow.xcworkspace
   ```

4. **Configure signing:**
   - Select the project in Xcode
   - Go to Signing & Capabilities
   - Update Team ID with your Apple Developer Team
   - Update Bundle Identifier to your domain (e.g., `com.yourcompany.expenseflow`)

5. **Select your development device** and press **Run** (⌘R)

### Option 2: Using XcodeGen

```bash
git clone https://github.com/yourusername/ExpenseFlow.git
cd ExpenseFlow
xcodegen generate
xcodebuild -scheme ExpenseFlow -configuration Release
```

## Project Structure

```
ExpenseFlow/
├── Sources/
│   ├── ExpenseFlowApp.swift           # App entry point
│   ├── App/
│   │   └── Theme.swift                # Color scheme and styling
│   ├── Views/                          # SwiftUI screens
│   │   ├── Expense/
│   │   ├── Settings/
│   │   └── ...
│   ├── Components/                     # Reusable UI components
│   ├── Stores/                         # State management (MVVM)
│   │   ├── AuthStore.swift            # Authentication logic
│   │   ├── ExpenseStore.swift         # Expense management
│   │   └── SettingsStore.swift        # User preferences
│   ├── Models/                         # Data models
│   │   ├── Expense.swift
│   │   └── ExpenseCategory.swift
│   └── Utilities/                      # Helper functions
│       ├── KeychainHelper.swift       # Secure credential storage
│       ├── Logger.swift               # Structured logging
│       ├── DateHelpers.swift
│       └── Formatters.swift
├── Resources/
│   └── PrivacyInfo.xcprivacy         # iOS 17 Privacy Manifest
├── project.yml                         # XcodeGen configuration
├── LICENSE                            # MIT License
├── README.md                          # This file
└── .gitignore                         # Git ignore rules
```

## Architecture

### MVVM Pattern
ExpenseFlow follows the Model-View-ViewModel pattern for clean separation of concerns:

- **Models** (`Expense`, `ExpenseCategory`): Plain Swift structs representing data
- **Views**: SwiftUI components displaying UI and handling user interaction
- **ViewModels (Stores)**: Observable objects managing state and business logic

### State Management
- **@Published** properties in `@ObservableObject` stores
- **@StateObject** in SwiftUI views for store lifecycle management
- **Combine** framework for reactive updates

### Data Persistence
- **Local Storage**: Expenses stored as JSON in Documents directory
- **Keychain**: Passwords stored securely using Apple's Keychain API
- **UserDefaults**: Settings and authentication state stored safely
- **Automatic Sync**: Changes automatically saved to disk via Combine publishers

## Security

### Password Security
- ✅ Passwords are **NOT stored in UserDefaults** (would be visible in plaintext)
- ✅ Passwords stored securely in **Keychain** using Security framework
- ✅ Keychain access controlled via biometric/passcode authentication

### Data Protection
- ✅ Expenses stored encrypted locally (via FileProtection)
- ✅ No hardcoded API keys or secrets
- ✅ All validation and sanitization on user input

### Privacy
- ✅ **No tracking** - No analytics or third-party tracking code
- ✅ **No ads** - No advertisements or promotional content
- ✅ **On-device only** - All data stays on your device
- ✅ **Privacy Manifest** - iOS 17 compliant with declared data collection

## Configuration

### Build Settings
Update `project.yml` with your configuration:

```yaml
settings:
  DEVELOPMENT_TEAM: "YOUR_TEAM_ID"
  ORGANIZATION_IDENTIFIER: "com.yourcompany"
  PRODUCT_NAME: "ExpenseFlow"
  MARKETING_VERSION: "1.0"
  CURRENT_PROJECT_VERSION: "1"
```

### App Configuration
Edit `Sources/App/Theme.swift` to customize:
- Color scheme and appearance
- Typography and fonts
- Component styling
- Spacing and layout

## Testing

### Run Tests
```bash
xcodebuild test -scheme ExpenseFlow
```

### Test Coverage
- ✅ Auth validation (email format, password strength)
- ✅ Expense calculations (daily/monthly totals)
- ✅ Data persistence (save/load)
- ⚠️ UI tests planned for future release

## Known Issues & Limitations

- 📝 **Notifications**: Toggle exists but notification delivery not yet implemented
- 📝 **Budget Alerts**: Settings stored but alert system not active
- 📝 **Cloud Sync**: No iCloud or multi-device synchronization
- 📝 **Export**: No CSV/PDF export functionality (coming soon)
- 📝 **Edit Expenses**: Expenses can only be deleted, not edited (workaround: delete and re-add)

## Troubleshooting

### App won't build
- [ ] Check Xcode version: `xcode-select --print-path` (should be 15.0+)
- [ ] Update signing team: Xcode → Project Settings → Signing & Capabilities
- [ ] Clean build folder: Cmd+Shift+K
- [ ] Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`

### Keychain errors
- [ ] Ensure app signing is configured correctly
- [ ] Try deleting app and reinstalling
- [ ] Check device/simulator storage space

### Data not saving
- [ ] Check app has Documents folder access
- [ ] Verify UserDefaults is not disabled in developer settings
- [ ] Check Console.app logs for detailed error messages

### Crashes on launch
- [ ] Check Console.app for crash logs
- [ ] Check system log: `log stream --level debug --predicate 'eventMessage contains "ExpenseFlow"'`
- [ ] Ensure iOS version matches minimum requirement (iOS 16+)

## Development

### Code Style
- Swift 5.9+ syntax
- MARK comments for logical sections
- Minimal inline comments (code should be self-documenting)
- File-scoped access control where possible

### Logging
The app uses structured logging with `os_log`:

```swift
import os.log

AppLogger.log("Message", category: .auth, level: .info)
AppLogger.error("Error occurred", error: error, category: .auth)
AppLogger.debug("Debug info", category: .storage)
```

### Adding New Features
1. Create models in `Sources/Models/`
2. Add store logic in `Sources/Stores/`
3. Create views in `Sources/Views/`
4. Add UI components in `Sources/Components/`
5. Write tests for business logic
6. Update this README

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create a branch**: `git checkout -b feature/my-feature`
3. **Make changes** and test thoroughly
4. **Commit**: `git commit -am 'Add my feature'`
5. **Push**: `git push origin feature/my-feature`
6. **Open a Pull Request**

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## Support

Found a bug? Have a feature request?

- 🐛 **Report bugs**: [GitHub Issues](https://github.com/yourusername/ExpenseFlow/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/ExpenseFlow/discussions)
- 📧 **Email**: support@example.com

## Roadmap

### v1.1 (Next Release)
- [ ] Expense editing UI
- [ ] Working budget alerts (local notifications)
- [ ] Receipt image attachment
- [ ] Data export (CSV/PDF)
- [ ] Search and filtering

### v2.0 (Future)
- [ ] iCloud sync via CloudKit
- [ ] Shared budgets (family mode)
- [ ] Real backend API
- [ ] Web dashboard
- [ ] Advanced analytics and reports

## Changelog

### v1.0.0 - Initial Release
- Core expense tracking functionality
- Secure authentication with Keychain
- Local data persistence
- Analytics dashboard
- Settings and customization
- iOS 16+ support

---

**Made with ❤️ by the ExpenseFlow team**
