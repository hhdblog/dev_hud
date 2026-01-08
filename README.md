# dev_hud

A lightweight, draggable, and game-focused debug overlay for Flutter applications.
**dev_hud** allows you to monitor FPS and track custom key-value data (like Player Health, Server State, Level, etc.) in real-time.

Designed for both **Games** and **Apps**, it features a "Zero-Cost" mode where it completely disables itself (stops ticking and rendering) when turned off, making it safe to leave in your production code behind a flag.

## 🚀 Features

- **🎮 Game Focused:** Perfect for tracking game states, enemy counts, or physics calculations.
- **🖱️ Draggable UI:** Drag the overlay anywhere on the screen so it never blocks your UI.
- **📉 FPS Monitor:** Built-in FPS counter (can be disabled).
- **⚡ Zero Performance Cost:** When `enabled` is set to `false`, the widget returns a `SizedBox.shrink()` and stops all Tickers. It consumes **0% CPU/GPU**.
- **📝 Custom Data:** Log any variable (`String`, `int`, `bool`, `double`) with a simple API.
- **🎨 Auto Formatting:** Automatically colors boolean values (Green/Red) and numbers (Cyan) for better readability.

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  dev_hud: ^0.0.3
```

````

## 💻 Usage

### 1. Wrap your App

Wrap your `MaterialApp` (or your root widget) with `DevHud`.

```dart
import 'package:flutter/material.dart';
import 'package:dev_hud/dev_hud.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DevHud(
      // Toggle this with a Remote Config or a global constant
      enabled: true,
      // Optional: Hide FPS if you only want custom data
      showFps: true,
      // Optional: Set initial position
      initialPosition: const Offset(10, 50),
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('My Game')),
          body: const GameLevel(),
        ),
      ),
    );
  }
}

```

### 2. Log Data Anywhere

You can update the HUD from anywhere in your code (Controllers, Game Loop, Services) using the singleton `DevHudService`.

**Update a single value:**

```dart
// Update String
DevHudService.instance.update("Weapon", "Sword of Truth");

// Update Integer (great for counting objects)
DevHudService.instance.update("Enemies", 12);

// Update Boolean (Shows as ON/OFF in Green/Red)
DevHudService.instance.update("God Mode", true);

```

**Remove a value:**

```dart
DevHudService.instance.remove("Loading State");

```

**Clear all data:**

```dart
DevHudService.instance.clear();

```

## 🛠 Configuration

| Parameter         | Type     | Default    | Description                                                 |
| ----------------- | -------- | ---------- | ----------------------------------------------------------- |
| `child`           | `Widget` | required   | The widget below this overlay (usually MaterialApp).        |
| `enabled`         | `bool`   | `true`     | If false, the overlay disappears and consumes no resources. |
| `showFps`         | `bool`   | `true`     | Show/Hide the built-in FPS counter.                         |
| `initialPosition` | `Offset` | `(10, 50)` | Starting position of the overlay button.                    |

## 🛡️ License

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.
````
