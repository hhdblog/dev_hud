import 'dart:async';
import 'package:dev_hud/dev_hud.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DevHudExampleApp());
}

/// The root widget of the example application.
class DevHudExampleApp extends StatefulWidget {
  const DevHudExampleApp({super.key});

  @override
  State<DevHudExampleApp> createState() => _DevHudExampleAppState();
}

class _DevHudExampleAppState extends State<DevHudExampleApp> {
  // This controls the "Zero-Cost" mode.
  // When false, the HUD is completely removed from the widget tree.
  bool _isHudEnabled = true;

  @override
  Widget build(BuildContext context) {
    return DevHud(
      // 1. Toggle visibility and performance cost
      enabled: _isHudEnabled,
      // 2. Enable the built-in FPS monitor
      showFps: true,
      // 3. Enable memory usage monitor (NEW)
      showMemory: true,
      // 4. Persist HUD position across restarts (NEW)
      persistPosition: true,
      // 5. Set initial position (e.g., Top-Left)
      initialPosition: const Offset(20, 60),
      // 6. Wrap your main app
      child: MaterialApp(
        // 7. Set the scaffoldMessengerKey for the clipboard feature
        scaffoldMessengerKey: DevHudService.messengerKey,
        debugShowCheckedModeBanner: false,
        title: 'DevHud Demo',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
        ),
        home: GameSimulationScreen(
          isHudEnabled: _isHudEnabled,
          onToggleHud: () {
            setState(() {
              _isHudEnabled = !_isHudEnabled;
            });
          },
        ),
      ),
    );
  }
}

class GameSimulationScreen extends StatefulWidget {
  final bool isHudEnabled;
  final VoidCallback onToggleHud;

  const GameSimulationScreen({
    super.key,
    required this.isHudEnabled,
    required this.onToggleHud,
  });

  @override
  State<GameSimulationScreen> createState() => _GameSimulationScreenState();
}

class _GameSimulationScreenState extends State<GameSimulationScreen> {
  int _score = 0;
  int _energy = 100;
  bool _isUnderHeavyLoad = false;
  Timer? _heavyLoadTimer;

  @override
  void initState() {
    super.initState();
    // Initialize HUD with some default game data
    DevHudService.instance.update("GameState", "Running");

    // NEW: Using groups with "/" separator
    DevHudService.instance.update("Player/Name", "Hero_01");
    DevHudService.instance.update("Player/Energy", _energy);
    DevHudService.instance.update("Player/Level", 5);

    DevHudService.instance.update("World/Zone", "Forest");
    DevHudService.instance.update("World/Enemies", 12);
  }

  @override
  void dispose() {
    _heavyLoadTimer?.cancel();
    super.dispose();
  }

  // --- GAME LOGIC ---

  void _addScore() {
    setState(() {
      _score += 100;
    });
    // Update HUD: Int values are colored Cyan
    DevHudService.instance.update("Player/Score", _score);
  }

  void _takeDamage() {
    setState(() {
      _energy = (_energy - 10).clamp(0, 100);
    });
    // Update HUD: You can update existing keys instantly
    DevHudService.instance.update("Player/Energy", _energy);

    if (_energy == 0) {
      DevHudService.instance.update("GameState", "GAME OVER");
    }
  }

  // --- LAG SIMULATION LOGIC ---

  /// Simulates a heavy computational task that blocks the UI thread.
  /// This demonstrates how the FPS counter reacts to performance drops.
  void _toggleHeavyLoad() {
    setState(() {
      _isUnderHeavyLoad = !_isUnderHeavyLoad;
    });

    // Update HUD: Bool values are colored Green (True) / Red (False)
    DevHudService.instance.update("Heavy Load", _isUnderHeavyLoad);

    if (_isUnderHeavyLoad) {
      // Start a timer that blocks the main thread every 50ms
      _heavyLoadTimer = Timer.periodic(const Duration(milliseconds: 50), (
        timer,
      ) {
        // Busy-wait loop to waste CPU cycles (Simulates complex physics/AI)
        final stopwatch = Stopwatch()..start();
        while (stopwatch.elapsedMilliseconds < 30) {
          // Blocking the thread...
        }
      });
    } else {
      _heavyLoadTimer?.cancel();
    }
  }

  void _clearHud() {
    DevHudService.instance.clear();
    // Re-add essential data so the screen isn't empty
    DevHudService.instance.update("Status", "Cleared");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DevHud Performance Test"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 40),

              // 1. GAME ACTIONS
              const Text(
                "Game Actions",
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.add_circle,
                    label: "Add Score",
                    color: Colors.blueAccent,
                    onTap: _addScore,
                  ),
                  const SizedBox(width: 15),
                  _ActionButton(
                    icon: Icons.flash_on,
                    label: "Damage",
                    color: Colors.orangeAccent,
                    onTap: _takeDamage,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 2. PERFORMANCE TEST
              const Text(
                "Performance Test",
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 10),

              InkWell(
                onTap: _toggleHeavyLoad,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _isUnderHeavyLoad
                        ? Colors.redAccent.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.1),
                    border: Border.all(
                      color: _isUnderHeavyLoad
                          ? Colors.redAccent
                          : Colors.green,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isUnderHeavyLoad
                            ? Icons.warning_amber_rounded
                            : Icons.speed,
                        color: _isUnderHeavyLoad
                            ? Colors.redAccent
                            : Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isUnderHeavyLoad
                            ? "STOP HEAVY LOAD"
                            : "SIMULATE HEAVY LOAD",
                        style: TextStyle(
                          color: _isUnderHeavyLoad
                              ? Colors.redAccent
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isUnderHeavyLoad)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Observe FPS dropping in the HUD!",
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),

              const Divider(height: 50, color: Colors.white12),

              // 3. SETTINGS
              ListTile(
                leading: const Icon(
                  Icons.developer_mode,
                  color: Colors.white70,
                ),
                title: const Text("Enable DevHud"),
                subtitle: const Text("Toggle 'Zero-Cost' mode"),
                trailing: Switch(
                  value: widget.isHudEnabled,
                  onChanged: (_) => widget.onToggleHud(),
                  activeThumbColor: Colors.deepPurpleAccent,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.white70),
                title: const Text("Clear Data"),
                onTap: _clearHud,
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.gamepad, size: 48, color: Colors.deepPurpleAccent),
          const SizedBox(height: 12),
          Text(
            "Score: $_score  •  Energy: $_energy%",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Drag the HUD anywhere (even over status bar!).\n"
            "Long press data to copy. Tap groups to collapse.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
