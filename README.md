# dev_hud 🚀

# DevHud

A high-performance, draggable, and game-focused debug overlay for Flutter.  
Monitor FPS and track custom data in real-time without compromising your app's performance.

<p align="center">
  <img src="https://github.com/hhdblog/dev_hud/raw/main/screenshots/demo.png" width="300" alt="DevHud Demo">
</p>

## ✨ Features

- **⚡ High Performance:** Optimized with `RepaintBoundary` and throttled updates. Uses semi-transparent backgrounds instead of expensive blur effects to ensure 0% impact on your game/app FPS.
- **🖱️ Draggable UI:** Move the HUD anywhere. It remembers its position and never blocks your interaction with the underlying UI.
- **📉 Smart FPS Monitor:** Built-in FPS counter that changes color (Green/Orange/Red) based on performance.
- **📋 Copy on Long Press:** Long press any data row to copy the value to your clipboard. Perfect for capturing IDs, tokens, or coordinates.
- **🎨 Auto-Formatting:** Automatically detects types and applies colors (Green for Booleans, Cyan for Numbers, Amber for Strings).
- **🛡️ Zero-Cost Mode:** When `enabled: false`, it returns a `SizedBox.shrink()` and stops all tickers, consuming zero CPU/GPU cycles.

## 📦 Installation

Add `dev_hud` to your `pubspec.yaml`:

```yaml
dependencies:
  dev_hud: ^0.0.6
```

````

## 🚀 Quick Start

Wrap your `MaterialApp` (or root widget) with `DevHud`:

```dart
import 'package:dev_hud/dev_hud.dart';

void main() {
  runApp(
    DevHud(
      enabled: true, // Toggle this based on kDebugMode or remote config
      showFps: true,
      initialPosition: const Offset(20, 60),
      child: MaterialApp(
        home: MyGamePage(),
      ),
    ),
  );
}

```

## 📝 Usage

Update the HUD from anywhere in your code (Controllers, Game Loop, Services) using the `DevHudService` singleton.

```dart
// Track simple values
DevHudService.instance.update("Score", 1250);

// Track boolean states (Auto-colors Green/Red)
DevHudService.instance.update("GodMode", true);

// Track complex strings
DevHudService.instance.update("API_Status", "200_OK");

// Clear all data
DevHudService.instance.clear();

```

## 🛠 Advanced: Performance Testing

You can use `DevHud` to visualize how your app handles heavy loads. Check the `example` folder for a "Lag Simulation" demo that intentionally blocks the UI thread to see the FPS counter in action.

## 📸 Screenshots

| Feature        | Description                                              |
| -------------- | -------------------------------------------------------- |
| **Draggable**  | Drag the "Terminal" icon to reposition the HUD.          |
| **Data Types** | Auto-coloring for `bool`, `int`, `double`, and `String`. |
| **Clipboard**  | Long-press any row to copy data to clipboard.            |

---

## 🛡️ License

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.

```
````
