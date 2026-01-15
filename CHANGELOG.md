## 0.0.9

### 🚀 New Features
- **Memory Usage Tracking**: Added `showMemory` parameter to display real-time RSS memory usage.
- **Collapsible Groups**: Use `/` in keys (e.g., `"Player/Health"`) to create collapsible groups.
- **Position Persistence**: Added `persistPosition` parameter to remember HUD position across app restarts.

### ⚡ Optimizations  
- **FPS Calculation**: Optimized Ticker-based FPS calculation with throttled updates (every 500ms).
- **Equality Check**: `update()` now skips `notifyListeners()` if the value hasn't changed.

### 🎨 UI Improvements
- **Drag Feedback**: Animated cyan glow border and shadow when dragging.
- **Rounded Splash Effects**: InkWell ripple effects now have rounded corners.
- **Invisible Grab Handle**: Added transparent touch area below collapsed HUD for easier dragging near status bar.
- **Safe Area Boundaries**: HUD respects bottom navigation bar/gesture area.

### 🐛 Bug Fixes
- **Status Bar Overlap**: HUD can now be dragged over the status bar in fullscreen apps.
- **MessengerKey Warning**: Copy-to-clipboard now prints a debug message instead of silently failing when `scaffoldMessengerKey` is not set.
- **ListenableBuilder**: Replaced deprecated `AnimatedBuilder` with `ListenableBuilder` for better semantics.

## 0.0.8

- **Fixed Screenshot Display**: Updated README.md image URL from `blob` to `raw` for proper rendering on pub.dev and GitHub.

## 0.0.7

- **Enhanced Documentation**: Completely redesigned README.md with modern formatting, improved readability, and comprehensive examples.
- **Better Developer Experience**: Added structured sections including Quick Start, Usage Examples, Best Practices, and Troubleshooting guide.
- **Visual Improvements**: Added badges, tables, collapsible sections, and emoji indicators for better navigation.
- **Extended Examples**: Included real-world use cases for game development, API monitoring, and performance testing scenarios.

## 0.0.6

- **Fixed Clipboard Notification**: Resolved issue where SnackBar message text was invisible after copying data.
- **Improved User Feedback**: Copy notifications now display with proper text styling and visibility.

## 0.0.5

- **UI/UX Overhaul**: Switched to a high-performance "Console" design.
- **Optimized Rendering**: Removed heavy blur effects for 0% performance impact on game frames.
- **Clipboard Support**: Added "Long Press to Copy" feature for all data rows.
- **Enhanced Example**: Added a "Lag Simulation" tool to demonstrate FPS monitoring under heavy load.
- **Type-Based Coloring**: Improved automatic coloring for different data types (Booleans, Numbers, Strings).

## 0.0.4

- Added screenshot to README.md.
- Improved metadata for better pub.dev ranking.

## 0.0.3

- Fixed `homepage` URL verification issue on pub.dev.
- Added `repository` field to `pubspec.yaml`.

## 0.0.2

- Added full English documentation (README and Code Comments).
- Improved example application to demonstrate "Zero-Cost" mode.
- Refactored API comments for better IDE support.

## 0.0.1

- Initial release.
- Added draggable floating overlay.
- Added built-in FPS monitor.
- Added support for custom key-value data logging.
