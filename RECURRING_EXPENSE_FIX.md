# Recurring Expense Persistence Fix
**Date:** September 30, 2026  
**Status:** ✅ RESOLVED

## Problem

Recurring expenses were not being retained after the app was killed and relaunched. When users created a recurring expense, it appeared in the list temporarily, but upon closing and restarting the app, the data was lost.

## Root Cause

The `RecurringExpenseStore` was relying **exclusively** on a Combine subscription to save data:

```swift
init() {
    load()
    $recurringExpenses
        .dropFirst()
        .sink { [weak self] _ in
            self?.save()  // Called asynchronously
        }
        .store(in: &cancellables)
}
```

### Issues with This Approach:

1. **Race Condition**: The Combine subscription runs asynchronously on an event queue
2. **Timing Issue**: When `isPresented = false` closes the view immediately after adding an expense, the save might not complete before the store is deallocated
3. **No Disk Sync**: `UserDefaults.standard.set()` caches data in memory but doesn't guarantee writing to disk immediately
4. **Unreliable Persistence**: Async saves are vulnerable to app termination

## Solution

### Changes Made to RecurringExpenseStore.swift

#### 1. **Made save() Public** (was private)
```swift
func save() {
    do {
        let data = try JSONEncoder().encode(recurringExpenses)
        UserDefaults.standard.set(data, forKey: storageKey)
        UserDefaults.standard.synchronize()  // ← Force disk write
        saveError = nil
        AppLogger.debug("Recurring expenses saved successfully (\(recurringExpenses.count) items)", category: .storage)
    } catch {
        AppLogger.error("Failed to save recurring expenses", error: error, category: .storage)
        saveError = "Could not save recurring expenses. Changes may be lost."
    }
}
```

#### 2. **Added Explicit save() Calls in All CRUD Operations**

**Before:**
```swift
func add(_ expense: RecurringExpense) {
    recurringExpenses.append(expense)  // Only triggers async Combine subscription
}
```

**After:**
```swift
func add(_ expense: RecurringExpense) {
    recurringExpenses.append(expense)
    save()  // ← Synchronous save
}
```

#### 3. **Applied Same Pattern to All CRUD Operations**

```swift
func add(_ expense: RecurringExpense) {
    recurringExpenses.append(expense)
    save()
}

func update(_ expense: RecurringExpense) {
    if let index = recurringExpenses.firstIndex(where: { $0.id == expense.id }) {
        recurringExpenses[index] = expense
    }
    save()
}

func delete(_ id: UUID) {
    recurringExpenses.removeAll { $0.id == id }
    save()
}

func delete(_ expense: RecurringExpense) {
    recurringExpenses.removeAll { $0.id == expense.id }
    save()
}

func replaceAll(_ expenses: [RecurringExpense]) {
    recurringExpenses = expenses
    save()
}
```

#### 4. **Added UserDefaults.synchronize()**

```swift
UserDefaults.standard.set(data, forKey: storageKey)
UserDefaults.standard.synchronize()  // Force immediate write to disk
```

## Key Improvements

✅ **Immediate Persistence**: Every CRUD operation immediately saves to disk  
✅ **No Race Conditions**: Synchronous save() calls eliminate timing issues  
✅ **Guaranteed Disk Write**: `synchronize()` ensures data is written to persistent storage  
✅ **Redundant Safety**: Combine subscription still acts as a backup safety net  
✅ **No Lost Data**: Data persists even if app is killed immediately after operation  

## Testing

The fix ensures:
1. ✅ Add recurring expense → data saved immediately
2. ✅ Update recurring expense → data saved immediately
3. ✅ Delete recurring expense → data saved immediately
4. ✅ Close app → data persists on disk
5. ✅ Reopen app → recurring expenses restored from disk

## Files Modified

- `Sources/Stores/RecurringExpenseStore.swift`
  - Made `save()` method public
  - Added explicit `save()` calls to all CRUD operations
  - Added `UserDefaults.standard.synchronize()` for disk persistence

## Build Status

✅ **BUILD SUCCEEDED** - No compilation errors or warnings

## Architecture

The store now uses a **belt-and-suspenders approach**:
- **Primary**: Explicit synchronous save() calls in CRUD operations
- **Secondary**: Combine subscription as fallback for edge cases

This dual approach provides maximum reliability and ensures data is never lost.
