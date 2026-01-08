import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dev_hud_service.dart';

/// A draggable, overlay widget that displays developer statistics and custom data.
///
/// Wrap your root widget (usually [MaterialApp]) with [DevHud] to enable it.
/// When [enabled] is set to false, this widget consumes zero resources.
class DevHud extends StatefulWidget {
  /// The child widget to wrap. usually the root [MaterialApp] or [Scaffold].
  final Widget child;

  /// Controls whether the HUD is active.
  ///
  /// * `true`: The HUD is visible, draggable, and tracking FPS (if enabled).
  /// * `false`: The HUD is completely removed from the tree, consuming **0% performance**.
  ///
  /// It is recommended to toggle this via a remote config or a compile-time constant (kDebugMode).
  final bool enabled;

  /// The initial position of the floating button on the screen.
  /// Defaults to `Offset(10, 50)`.
  final Offset initialPosition;

  /// Whether to calculate and show the FPS (Frames Per Second) counter automatically.
  /// Defaults to `true`.
  final bool showFps;

  /// Creates a developer HUD overlay.
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
  bool _isOpen = false;
  Ticker? _ticker;
  int _frameCount = 0;
  Duration _lastUpdate = Duration.zero;
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;

    // Only start the Ticker if the widget is enabled and FPS tracking is requested.
    if (widget.enabled && widget.showFps) {
      _ticker = createTicker((Duration elapsed) {
        _frameCount++;
        // Update FPS calculation every 500ms
        if (elapsed - _lastUpdate >= const Duration(milliseconds: 500)) {
          double elapsedSeconds =
              (elapsed - _lastUpdate).inMilliseconds / 1000.0;
          if (elapsedSeconds > 0) {
            double fps = _frameCount / elapsedSeconds;
            DevHudService.instance.update("FPS", fps);
          }
          _lastUpdate = elapsed;
          _frameCount = 0;
        }
      });
      _ticker?.start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Zero-Cost check: If disabled, return child directly.
    if (!widget.enabled) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [widget.child, _buildOverlay(context)]),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return AnimatedBuilder(
      animation: DevHudService.instance,
      builder: (context, _) {
        final service = DevHudService.instance;
        final dataEntries = service.data.entries.toList();

        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: Material(
            type: MaterialType.transparency,
            child: GestureDetector(
              // Drag Logic
              onPanUpdate: (details) {
                setState(() {
                  double newX = _position.dx + details.delta.dx;
                  double newY = _position.dy + details.delta.dy;

                  // Screen Boundary Clamping (Prevent dragging off-screen)
                  // We subtract 40 to account for the button size roughly.
                  newX = newX.clamp(0.0, size.width - 40);
                  newY = newY.clamp(padding.top, size.height - 40);

                  _position = Offset(newX, newY);
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- TOGGLE BUTTON ---
                  InkWell(
                    onTap: () => setState(() => _isOpen = !_isOpen),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isOpen
                            ? Colors.redAccent.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isOpen ? Icons.close : Icons.analytics_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          // Show Mini FPS when closed
                          if (!_isOpen && service.data.containsKey('FPS')) ...[
                            const SizedBox(width: 6),
                            Text(
                              "FPS: ${(service.data['FPS'] as num).toStringAsFixed(1)}",
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // --- EXPANDED DATA LIST ---
                  if (_isOpen)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        minWidth: 140,
                        maxWidth: 220,
                        // Limit height to half screen to prevent overflow
                        maxHeight: size.height * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: SingleChildScrollView(
                        child: dataEntries.isEmpty
                            ? const Text(
                                "No Data",
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 10,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (
                                    var i = 0;
                                    i < dataEntries.length;
                                    i++
                                  ) ...[
                                    _buildRow(
                                      dataEntries[i].key,
                                      dataEntries[i].value,
                                    ),
                                    if (i != dataEntries.length - 1)
                                      const Divider(
                                        color: Colors.white12,
                                        height: 8,
                                      ),
                                  ],
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

  /// Builds a single row of key-value data with auto-coloring.
  Widget _buildRow(String key, dynamic value) {
    Color valueColor = Colors.white;
    String displayValue = value.toString();

    // Auto-formatting based on type
    if (value is bool) {
      valueColor = value ? Colors.greenAccent : Colors.redAccent;
      displayValue = value ? "ON" : "OFF";
    } else if (value is num) {
      valueColor = Colors.cyanAccent;
      // Truncate long doubles
      if (value is double) displayValue = value.toStringAsFixed(1);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            key,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          displayValue,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            fontFamily: 'Monospace',
          ),
        ),
      ],
    );
  }
}
