# 🎮 DevHud

<div align="center">

**A beautiful, high-performance debug overlay for Flutter games and apps**

Monitor FPS, track custom data, and debug in real-time — all without compromising performance.

[![pub package](https://img.shields.io/pub/v/dev_hud.svg)](https://pub.dev/packages/dev_hud)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

![DevHud Demo](https://raw.githubusercontent.com/hhdblog/dev_hud/main/screenshots/demo.png)

[Features](#-features) • [Installation](#-installation) • [Quick Start](#-quick-start) • [Usage](#-usage) • [Examples](#-examples)

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🚀 Performance First

- **Zero FPS impact** with optimized rendering
- Smart throttling and `RepaintBoundary`
- Semi-transparent backgrounds (no expensive blur)
- Completely disabled when `enabled: false`

</td>
<td width="50%">

### 🎨 Developer Experience

- **Draggable interface** - move it anywhere
- **Auto-formatting** with color coding
- **Copy on long press** - grab any value instantly
- **Smart FPS monitor** with color indicators

</td>
</tr>
</table>

### 🎯 What You Get

| Feature                    | Description                                                                                                                                             |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ⚡ **Real-time FPS**       | Visual performance monitoring with color-coded alerts                                                                                                   |
| 📊 **Custom Metrics**      | Track any data: scores, coordinates, API states                                                                                                         |
| 🎨 **Smart Colors**        | Auto-detects types: <span style="color:#4CAF50">Booleans</span>, <span style="color:#00BCD4">Numbers</span>, <span style="color:#FFC107">Strings</span> |
| 📋 **Quick Copy**          | Long-press any row to copy values to clipboard                                                                                                          |
| 🖱️ **Persistent Position** | Remembers where you placed it                                                                                                                           |
| 🛡️ **Production Safe**     | Zero overhead when disabled                                                                                                                             |

---

## 📦 Installation

Add `dev_hud` to your `pubspec.yaml`:

```yaml
dependencies:
  dev_hud: ^0.0.8
```

Then run:

```bash
flutter pub get
```

---

## 🚀 Quick Start

### 1️⃣ Wrap Your App

Wrap your `MaterialApp` with `DevHud`:

```dart
import 'package:dev_hud/dev_hud.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(
    DevHud(
      enabled: kDebugMode,  // Only show in debug mode
      showFps: true,
      initialPosition: const Offset(20, 60),
      child: MaterialApp(
        title: 'My Game',
        home: GamePage(),
      ),
    ),
  );
}
```

### 2️⃣ Track Your Data

Update the HUD from anywhere using `DevHudService`:

```dart
import 'package:dev_hud/dev_hud.dart';

// In your game loop, controller, or service
void updateGameStats() {
  DevHudService.instance.update("Score", 1250);
  DevHudService.instance.update("Health", 85.5);
  DevHudService.instance.update("GodMode", true);
  DevHudService.instance.update("Level", "Forest_Zone_2");
}
```

That's it! 🎉

---

## 📝 Usage

### Basic Tracking

```dart
// Track numbers (auto-colored in cyan)
DevHudService.instance.update("Score", 1250);
DevHudService.instance.update("Health", 85.5);

// Track booleans (auto-colored green/red)
DevHudService.instance.update("IsConnected", true);
DevHudService.instance.update("GamePaused", false);

// Track strings (auto-colored in amber)
DevHudService.instance.update("Status", "Loading...");
DevHudService.instance.update("PlayerID", "abc-123-xyz");
```

### Advanced Operations

```dart
// Clear all tracked data
DevHudService.instance.clear();

// Remove specific entry
DevHudService.instance.remove("OldMetric");

// Bulk updates in game loop
void onGameTick() {
  final service = DevHudService.instance;
  service.update("FPS", currentFps);
  service.update("Entities", entityCount);
  service.update("Memory", "${(memoryMb).toStringAsFixed(1)} MB");
}
```

### Configuration Options

```dart
DevHud(
  enabled: true,                    // Toggle visibility
  showFps: true,                    // Show FPS counter
  initialPosition: Offset(20, 60),  // Starting position
  child: YourApp(),
)
```

---

## 🎯 Examples

### Game Development

```dart
class GameController {
  void updateHud() {
    DevHudService.instance.update("Level", currentLevel);
    DevHudService.instance.update("Enemies", enemyCount);
    DevHudService.instance.update("Combo", comboMultiplier);
    DevHudService.instance.update("PowerUp", hasPowerUp);
  }
}
```

### API Monitoring

```dart
class ApiService {
  Future<void> fetchData() async {
    DevHudService.instance.update("API_Status", "Connecting...");

    try {
      final response = await http.get(url);
      DevHudService.instance.update("API_Status", "✓ ${response.statusCode}");
      DevHudService.instance.update("Latency", "${latency}ms");
    } catch (e) {
      DevHudService.instance.update("API_Status", "✗ Error");
    }
  }
}
```

### Performance Testing

```dart
// Simulate lag to test FPS counter
ElevatedButton(
  onPressed: () {
    final start = DateTime.now();
    while (DateTime.now().difference(start).inMilliseconds < 100) {
      // Block UI thread
    }
  },
  child: Text('Simulate Lag'),
)
```

Check the [`example`](example/) folder for a complete demo with lag simulation.

---

## 🎨 Color Coding

DevHud automatically applies colors based on data types:

| Type             | Color                            | Example                                                |
| ---------------- | -------------------------------- | ------------------------------------------------------ |
| `bool`           | 🟢 Green (true) / 🔴 Red (false) | `true` → <span style="color:#4CAF50">true</span>       |
| `int` / `double` | 🔵 Cyan                          | `42` → <span style="color:#00BCD4">42</span>           |
| `String`         | 🟡 Amber                         | `"Hello"` → <span style="color:#FFC107">"Hello"</span> |

### FPS Color Indicators

| Range     | Color     | Meaning               |
| --------- | --------- | --------------------- |
| ≥ 55 FPS  | 🟢 Green  | Excellent performance |
| 30-54 FPS | 🟠 Orange | Moderate performance  |
| < 30 FPS  | 🔴 Red    | Poor performance      |

---

## 🔧 Tips & Best Practices

### ✅ Do

- Use `kDebugMode` or remote config to control visibility
- Update HUD in existing game loops, not extra tickers
- Use descriptive keys: `"Player_Health"` instead of `"h"`
- Long-press values to copy them during debugging

### ❌ Don't

- Leave `enabled: true` in production builds
- Create separate timers just for HUD updates
- Update HUD on every frame if data hasn't changed
- Track sensitive data that shouldn't be visible

---

## 🛠️ Troubleshooting

<details>
<summary><b>HUD not showing?</b></summary>

- Check `enabled: true` is set
- Ensure you wrapped the correct widget (usually `MaterialApp`)
- Verify you're calling `DevHudService.instance.update()`
</details>

<details>
<summary><b>FPS counter seems inaccurate?</b></summary>

- FPS is measured using `SchedulerBinding` and updates every ~500ms
- Heavy background work may affect readings
- Use Flutter DevTools for precise profiling
</details>

<details>
<summary><b>Can't drag the HUD?</b></summary>

- Make sure nothing is blocking touch events
- The draggable area is the terminal icon at the top
</details>

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

- 🐛 Report bugs
- 💡 Suggest features
- 🔧 Submit pull requests

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Made with ❤️ for Flutter developers**

If this package helped you, consider giving it a ⭐ on [pub.dev](https://pub.dev/packages/dev_hud)!

</div>
