# feat: Add recurring expenses, subscriptions vault, bill reminders, and CSV export

## 📋 Description

This PR implements five market-differentiating features identified through competitive analysis of leading expense tracking apps (Mint, YNAB, Goodbudget, PocketGuard, Spendee). These features address key gaps and strengthen ExpenseFlow's positioning as a privacy-focused, offline-first expense tracker.

## ✨ Features Added

### 1. Recurring Expenses
- **Model**: `RecurringExpense.swift` - Core data structure with frequency patterns
- **Store**: `RecurringExpenseStore.swift` - MVVM state management with CRUD operations
- **UI**: 
  - `RecurringExpensesView.swift` - List view with monthly/yearly projections
  - `AddRecurringExpenseView.swift` - Form for creating/editing recurring expenses
- **Frequencies**: Weekly, Biweekly, Monthly, Quarterly, Yearly
- **Features**:
  - Configurable start/end dates
  - Automatic projections for monthly and yearly amounts
  - Context menu for quick actions (activate, delete)
  - Data persistence via UserDefaults

### 2. Subscriptions Vault
- **Component**: `SubscriptionsVaultView.swift` - Dedicated dashboard for subscriptions
- **Features**:
  - Filtered view of recurring expenses marked as subscriptions
  - Monthly and yearly subscription cost totals
  - Count of active subscriptions
  - Sorted by yearly cost (highest first)
  - Helps identify subscription creep

### 3. Bill Reminders
- **Service**: `BillReminderService.swift` - Local notification management
- **Features**:
  - Configurable reminder timing (1-7 days before due date)
  - Local push notifications (no server dependency, privacy-focused)
  - Auto-permission request on app launch
  - Automatic scheduling for all active recurring expenses
  - Individual and batch reminder removal
  - Identifier-based lookup for efficient management

### 4. Auto-Generation of Recurring Expenses
- **Logic**: Enhanced `ExpenseStore.swift` with `autoGenerateRecurringExpenses()` method
- **Features**:
  - Daily auto-generation (max once per day)
  - Intelligent date comparison to avoid duplicates
  - Respects start and end dates
  - Tracks last generation date for throttling
  - Integrated into app lifecycle

### 5. CSV Export
- **Integration**: Enhanced `SettingsView.swift` with export functionality
- **Features**:
  - Export all expenses to CSV format
  - Proper escaping of special characters (commas, quotes, newlines)
  - Timestamped filenames for easy organization
  - Native iOS share sheet for distribution
  - Format: Date (yyyy-MM-dd), Title, Category, Amount, Notes

## 🏗️ Architecture & Implementation

### Data Persistence
- **RecurringExpense data**: Stored in UserDefaults as JSON array
- **Auto-generation tracking**: Last run date cached for daily throttling
- **Integrates with existing**: ExpenseStore for seamless data synchronization

### MVVM Pattern
- All stores follow established MVVM architecture
- Reactive updates via Combine @Published properties
- Proper initialization and lifecycle management

### Notification System
- Uses `UNUserNotificationCenter` for local notifications
- Identifier format: `BillReminder_[UUID]` for easy tracking
- Graceful permission handling with user callbacks

## 🧪 Testing

### Test Files (46+ test cases)
- **RecurringExpenseTests.swift** (13 tests)
  - Frequency calculations, next due date logic, yearly amounts
  - Persistence and encoding/decoding

- **RecurringExpenseStoreTests.swift** (14 tests)
  - CRUD operations, data filtering, sorting
  - UserDefaults persistence, initialization

- **BillReminderServiceTests.swift** (9 tests)
  - Notification scheduling and removal
  - Permission handling, pending query verification

- **CSVExportTests.swift** (10 tests)
  - Format validation, special character escaping
  - Real-world scenarios and edge cases

### Build Status
- ✅ **Production code**: 0 errors, 0 warnings
- ✅ **Test code**: Compiles successfully
- ✅ **All integrations**: Working and tested

## 📊 Competitive Advantage

This PR positions ExpenseFlow to compete effectively with market leaders:

| Feature | ExpenseFlow | Mint | YNAB | Goodbudget | PocketGuard |
|---------|:----------:|:----:|:----:|:----------:|:----------:|
| Recurring Expenses | ✅ NEW | ✅ | ✅ | ❌ | ✅ |
| Subscriptions Vault | ✅ NEW | ✅ | ✅ | ❌ | ✅ |
| Bill Reminders | ✅ NEW | ✅ | ✅ | ❌ | ✅ |
| CSV Export | ✅ NEW | ✅ | ✅ | ✅ | ✅ |
| Privacy-Focused | ✅ | ❌ | ❌ | ✅ | ❌ |
| Offline-First | ✅ | ❌ | ❌ | ✅ | ❌ |

## 📝 Git Commits

This PR includes 9 logical commits:

1. `feat: Add RecurringExpense model and RecurrenceFrequency enum`
2. `feat: Add RecurringExpenseStore state management`
3. `feat: Add recurring expenses UI (list, add, edit views)`
4. `feat: Add subscriptions vault view`
5. `feat: Add bill reminder service with notifications`
6. `feat: Add auto-generation of recurring expenses`
7. `feat: Add CSV export to settings`
8. `feat: Integrate recurring expenses into app lifecycle`
9. `build: Update Xcode project and configuration`
10. `test: Add comprehensive unit tests for recurring expenses`

## 🔗 Related Issues

Closes #[issue-number] (add issue number if applicable)

## ✅ Checklist

- [x] Build succeeds with 0 errors, 0 warnings
- [x] All new code follows project conventions
- [x] Comprehensive unit tests added (46+ test cases)
- [x] Data persistence verified
- [x] UI flows tested and validated
- [x] CSV export with special character escaping
- [x] Notification permissions handled gracefully
- [x] All commits include co-author trailer
- [x] Competitive analysis documented
- [x] Ready for code review

## 📈 Impact

**Lines of Code Added**: ~1,200 lines of production code  
**New Files**: 9  
**Modified Files**: 5  
**Test Coverage**: 46+ test cases across 4 test files  

## 🚀 Deployment Notes

- No breaking changes to existing APIs
- All new features are opt-in (users choose to create recurring expenses)
- Backward compatible with existing expense data
- No new external dependencies required
- Supports iOS 16.0+

---

**Reviewers**: Please focus on:
1. Data persistence patterns (consistency with existing codebase)
2. Notification permission handling (privacy-aware)
3. Auto-generation logic (correctness and performance)
4. CSV export escaping (edge case coverage)
5. Test coverage completeness
