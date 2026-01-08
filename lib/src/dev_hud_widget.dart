import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dev_hud_service.dart';

/// A high-performance, draggable debug overlay.
///
/// Designed to have minimal impact on the rendering loop of the host application.
class DevHud extends StatefulWidget {
  /// The root widget of your application (usually MaterialApp).
  final Widget child;

  /// If false, the widget disappears completely and consumes 0 resources.
  final bool enabled;

  /// The starting position of the overlay.
  final Offset initialPosition;

  /// Whether to calculate and display FPS.
  final bool showFps;

  const DevHud({
    super.key,
    required this.child,
    this.enabled = true,
    this.initialPosition = const Offset(10, 50),
    this.showFps = true,
  });

  @override
  State<DevHud> createState() => _DevHudState();
}

class _DevHudState extends State<DevHud> with SingleTickerProviderStateMixin {
  // State variables
  bool _isOpen = false;
  late Offset _position;

  // FPS Logic variables
  Ticker? _ticker;
  int _frameCount = 0;
  Duration _lastUpdate = Duration.zero;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;

    // Start FPS tracker only if needed
    if (widget.enabled && widget.showFps) {
      _ticker = createTicker(_onTick);
      _ticker?.start();
    }
  }

  void _onTick(Duration elapsed) {
    _frameCount++;
    // Update FPS only twice per second (every 500ms) to save CPU cycles.
    // Updating 60 times a second for text is unnecessary overhead.
    if (elapsed - _lastUpdate >= const Duration(milliseconds: 500)) {
      double elapsedSeconds = (elapsed - _lastUpdate).inMilliseconds / 1000.0;
      if (elapsedSeconds > 0) {
        double fps = _frameCount / elapsedSeconds;
        DevHudService.instance.update("FPS", fps);
      }
      _lastUpdate = elapsed;
      _frameCount = 0;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Zero-Cost Check:
    // If disabled, we return the child directly. No Stack, no Listeners.
    if (!widget.enabled) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          // The main app
          widget.child,

          // The HUD Overlay
          // Using Positioned ensures we don't affect the layout of the child.
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: _buildDraggableOverlay(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // AnimatedBuilder listens only to specific data changes, highly optimized.
    return AnimatedBuilder(
      animation: DevHudService.instance,
      builder: (context, _) {
        final service = DevHudService.instance;
        final dataEntries = service.data.entries.toList();

        return Material(
          type: MaterialType.transparency,
          // GestureDetector handles the dragging logic
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                double newX = _position.dx + details.delta.dx;
                double newY = _position.dy + details.delta.dy;

                // Screen Boundary Clamping
                // Prevents the overlay from being dragged off-screen
                newX = newX.clamp(0.0, size.width - 40);
                newY = newY.clamp(padding.top, size.height - 40);

                _position = Offset(newX, newY);
              });
            },
            child: Container(
              // Styling: "Console" Look
              // Semi-transparent black is much faster to render than Blur effects.
              decoration: BoxDecoration(
                color: const Color(0xDD101010), // ~87% Opacity Black
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: 120,
                // If open, allow it to grow, but limit height
                maxWidth: _isOpen ? 250 : 120,
                maxHeight: _isOpen ? size.height * 0.5 : 50,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- HEADER ---
                  InkWell(
                    onTap: () => setState(() => _isOpen = !_isOpen),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isOpen ? Icons.expand_less : Icons.terminal,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isOpen
                                ? const Text(
                                    "DEV HUD",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : _buildMiniFpsOrTitle(service.data),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- DATA CONTENT ---
                  if (_isOpen)
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1, color: Colors.white12),
                            const SizedBox(height: 8),
                            if (dataEntries.isEmpty)
                              const Text(
                                "Waiting for data...",
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 11,
                                ),
                              ),

                            for (var entry in dataEntries)
                              _buildDataRow(context, entry.key, entry.value),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniFpsOrTitle(Map<String, dynamic> data) {
    if (data.containsKey('FPS')) {
      final fps = data['FPS'] as num;
      Color color = Colors.greenAccent;
      if (fps < 30) {
        color = Colors.redAccent;
      } else if (fps < 50) {
        color = Colors.orangeAccent;
      }

      return Text(
        "${fps.toStringAsFixed(0)} FPS",
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
    }
    return const Text(
      "HUD",
      style: TextStyle(color: Colors.white54, fontSize: 12),
    );
  }

  Widget _buildDataRow(BuildContext context, String key, dynamic value) {
    Color valueColor = Colors.white;
    String displayValue = value.toString();

    // Smart coloring based on type
    if (value is bool) {
      valueColor = value ? const Color(0xFF69F0AE) : const Color(0xFFFF5252);
      displayValue = value ? "ON" : "OFF";
    } else if (value is num) {
      valueColor = const Color(0xFF40C4FF); // Cyan
      if (value is double) displayValue = value.toStringAsFixed(2);
    } else if (value is String) {
      valueColor = const Color(0xFFFFD740); // Amber
    }

    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: "$key: $displayValue"));
        // Minimal feedback to user
        DevHudService.messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text("Copied '$key' to clipboard"),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                key,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                displayValue,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
