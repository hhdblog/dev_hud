import 'package:dev_hud/dev_hud.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DevHudExampleApp());
}

/// The root widget of the example application.
///
/// It holds the state for enabling/disabling the HUD to demonstrate
/// the "Zero-Cost" feature.
class DevHudExampleApp extends StatefulWidget {
  const DevHudExampleApp({super.key});

  @override
  State<DevHudExampleApp> createState() => _DevHudExampleAppState();
}

class _DevHudExampleAppState extends State<DevHudExampleApp> {
  // In a real app, this might come from Firebase Remote Config or a Debug Menu.
  bool _isHudEnabled = true;

  @override
  Widget build(BuildContext context) {
    return DevHud(
      // 1. Control visibility and performance (true = active, false = zero cost)
      enabled: _isHudEnabled,
      // 2. Optional: Show or hide the built-in FPS counter
      showFps: true,
      // 3. Optional: Set the initial position of the overlay button
      initialPosition: const Offset(20, 50),
      // 4. Wrap your MaterialApp
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DevHud Example',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1E1E1E),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
        ),
        home: HomeScreen(
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

class HomeScreen extends StatefulWidget {
  final bool isHudEnabled;
  final VoidCallback onToggleHud;

  const HomeScreen({
    super.key,
    required this.isHudEnabled,
    required this.onToggleHud,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _counter = 0;
  bool _godMode = false;

  @override
  void initState() {
    super.initState();
    // Initialize some dummy data
    DevHudService.instance.update("App State", "Started");
    DevHudService.instance.update("User ID", 1001);
  }

  void _simulateGameEvent() {
    setState(() {
      _counter += 50;
    });

    // Update specific keys
    DevHudService.instance.update("Score", _counter);
    DevHudService.instance.update("Level", (_counter / 100).floor() + 1);
    DevHudService.instance.update("Last Action", "Hit Enemy");
  }

  void _toggleGodMode() {
    setState(() {
      _godMode = !_godMode;
    });

    // Boolean values are automatically colored (Green=True, Red=False)
    DevHudService.instance.update("God Mode", _godMode);
  }

  void _clearData() {
    // Clear all custom data (FPS remains if enabled)
    DevHudService.instance.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DevHud Control Panel"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 30),

              const Text(
                "Simulate Data Updates:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                icon: const Icon(Icons.games),
                label: const Text("Simulate Game Event (+Score)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: _simulateGameEvent,
              ),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                icon: const Icon(Icons.shield),
                label: Text(_godMode ? "Disable God Mode" : "Enable God Mode"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _godMode ? Colors.green : Colors.redAccent,
                ),
                onPressed: _toggleGodMode,
              ),
              const SizedBox(height: 10),

              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text("Clear HUD Data"),
                onPressed: _clearData,
              ),

              const Divider(height: 40, color: Colors.white24),

              const Text(
                "Performance Control:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              SwitchListTile(
                title: const Text("Enable DevHud"),
                subtitle: const Text("Turn off to test 'Zero-Cost' mode"),
                value: widget.isHudEnabled,
                onChanged: (_) => widget.onToggleHud(),
                secondary: const Icon(Icons.developer_mode),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        children: [
          Icon(Icons.touch_app, size: 40, color: Colors.amber),
          SizedBox(height: 10),
          Text(
            "Try dragging the HUD button around!\nIt won't block your UI.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
