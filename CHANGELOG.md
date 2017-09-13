### [5.0.0](https://github.com/stack/Structure/releases/tag/v5.0.0)

### Updated

Switched to Swift 4.

Fixed macOS build to compile without warnings.

`sqlite3` has been updated to 3.20.1.

### [4.0.0](https://github.com/stack/Structure/releases/tag/v4.0.0)

### Updated

Added an `UPPER` SQLite function to use Swift's uppercase handling.

`sqlite3` has been updated to 3.19.3.

### [3.0.0](https://github.com/stack/Structure/releases/tag/v3.0.0)

### Updated

All methods names and parameters follow a more Swift-like naming convention.

`bind(_:value:)` is now `bind(value:for:)` and `bind(value:at:)`.

`finalize()` is no longer needed.

### [2.0.1](https://github.com/stack/Structure/releases/tag/v2.0.1)

### Updated

The `perform` method now has a throwable `rowCallback`, to allow bubbling up of
errors that occur in that callback.

### [2.0.0](https://github.com/stack/Structure/releases/tag/v2.0.0)

### Updated

*   Support for Xcode 8 & Swift 3.0

### [1.1.0](https://github.com/stack/Structure/releases/tag/v1.1.0)

### Updated

*   Support for Xcode 8 & Swift 2.3

### [1.0.1](https://github.com/stack/Structure/releases/tag/v1.0.1)

#### Updated

*   Audited closures for use of `@noescape`.
*   Audited parameter `throws` for use of `rethrows`.
*   Concurrency testing.


### [1.0](https://github.com/stack/Structure/releases/tag/v1.0.0)

Initial Release
