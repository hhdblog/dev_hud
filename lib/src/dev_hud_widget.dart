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

  /// Whether to display memory usage (RSS) in MB.
  /// Note: This only works on platforms that support dart:io (not web).
  final bool showMemory;

  /// Whether to persist the HUD position across app restarts.
  final bool persistPosition;

  const DevHud({
    super.key,
    required this.child,
    this.enabled = true,
    this.initialPosition = const Offset(10, 50),
    this.showFps = true,
    this.showMemory = false,
    this.persistPosition = false,
  });

  @override
  State<DevHud> createState() => _DevHudState();
}

class _DevHudState extends State<DevHud> with SingleTickerProviderStateMixin {
  // State variables
  bool _isOpen = false;
  bool _isDragging = false;
  late Offset _position;

  // FPS Logic using Ticker (more reliable in release mode)
  Ticker? _ticker;
  int _frameCount = 0;
  Duration _lastFpsUpdate = Duration.zero;
  Duration _lastMemoryUpdate = Duration.zero;

  // Invisible grab handle height when collapsed (for status bar case)
  static const double _grabHandleHeight = 25.0;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;

    if (widget.enabled) {
      // Load persisted position if enabled
      if (widget.persistPosition) {
        _loadPosition();
      }

      // Start FPS/Memory tracking using Ticker
      if (widget.showFps || widget.showMemory) {
        _ticker = createTicker(_onTick);
        _ticker?.start();
      }
    }
  }

  Future<void> _loadPosition() async {
    final savedPosition = await DevHudService.instance.loadPosition();
    if (savedPosition != null && mounted) {
      setState(() {
        _position = savedPosition;
      });
    }
  }

  void _savePosition() {
    if (widget.persistPosition) {
      // Fire and forget - don't await
      DevHudService.instance.savePosition(_position);
    }
  }

  void _onTick(Duration elapsed) {
    _frameCount++;

    // Update FPS every 500ms
    if (widget.showFps) {
      if (elapsed - _lastFpsUpdate >= const Duration(milliseconds: 500)) {
        double elapsedSeconds =
            (elapsed - _lastFpsUpdate).inMilliseconds / 1000.0;
        if (elapsedSeconds > 0) {
          double fps = _frameCount / elapsedSeconds;
          DevHudService.instance.update("FPS", fps);
        }
        _lastFpsUpdate = elapsed;
        _frameCount = 0;
      }
    }

    // Update Memory every 1 second
    if (widget.showMemory) {
      if (elapsed - _lastMemoryUpdate >= const Duration(milliseconds: 1000)) {
        final memoryMB = DevHudService.instance.getMemoryUsageMB();
        if (memoryMB != null) {
          DevHudService.instance.update(
            "Memory",
            "${memoryMB.toStringAsFixed(1)} MB",
          );
        }
        _lastMemoryUpdate = elapsed;
      }
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
            child: RepaintBoundary(child: _buildDraggableOverlay(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Calculate safe area bounds
    // Bottom: leave space for navigation bar/gesture area + HUD height
    final double maxY = size.height - padding.bottom - (_isOpen ? 25 : 25);

    // Border color animation based on drag state
    final borderColor = _isDragging
        ? Colors.cyanAccent.withValues(alpha: 0.6)
        : Colors.white24;

    // ListenableBuilder is more semantic than AnimatedBuilder for ChangeNotifier
    return ListenableBuilder(
      listenable: DevHudService.instance,
      builder: (context, _) {
        final service = DevHudService.instance;
        final groupedData = _groupData(service.data);

        return Material(
          type: MaterialType.transparency,
          // GestureDetector handles the dragging logic
          child: GestureDetector(
            onPanStart: (_) {
              setState(() => _isDragging = true);
            },
            onPanUpdate: (details) {
              setState(() {
                double newX = _position.dx + details.delta.dx;
                double newY = _position.dy + details.delta.dy;

                // Screen Boundary Clamping
                // Allow dragging anywhere, but respect bottom safe area
                newX = newX.clamp(0.0, size.width - 40);
                newY = newY.clamp(0.0, maxY);

                _position = Offset(newX, newY);
              });
            },
            onPanEnd: (_) {
              setState(() => _isDragging = false);
              _savePosition();
            },
            onPanCancel: () {
              setState(() => _isDragging = false);
            },
            // Column with visible HUD + invisible grab handle for status bar case
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main HUD Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  // Styling: "Console" Look with animated border
                  decoration: BoxDecoration(
                    color: const Color(0xDD101010), // ~87% Opacity Black
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: borderColor,
                      width: _isDragging ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isDragging
                            ? Colors.cyanAccent.withValues(alpha: 0.2)
                            : Colors.black45,
                        blurRadius: _isDragging ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    minWidth: 120,
                    // If open, allow it to grow, but limit height
                    maxWidth: _isOpen ? 250 : 120,
                    maxHeight: _isOpen ? size.height * 0.5 : 50,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- HEADER ---
                        InkWell(
                          onTap: () => setState(() => _isOpen = !_isOpen),
                          borderRadius: BorderRadius.circular(6),
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
                                  const Divider(
                                    height: 1,
                                    color: Colors.white12,
                                  ),
                                  const SizedBox(height: 8),
                                  if (groupedData.isEmpty)
                                    const Text(
                                      "Waiting for data...",
                                      style: TextStyle(
                                        color: Colors.white30,
                                        fontSize: 11,
                                      ),
                                    ),

                                  // Render grouped data with collapsible sections
                                  for (var group in groupedData.entries)
                                    _buildGroup(
                                      context,
                                      group.key,
                                      group.value,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Invisible grab handle (only when collapsed)
                // This allows dragging even when HUD is under status bar
                if (!_isOpen)
                  Container(
                    width: 120,
                    height: _grabHandleHeight,
                    color: Colors.transparent, // Invisible but touchable
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Groups data by the "/" separator in keys.
  /// Keys without "/" are placed in a special "_root" group.
  Map<String, Map<String, dynamic>> _groupData(Map<String, dynamic> data) {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (var entry in data.entries) {
      final parts = entry.key.split('/');
      if (parts.length > 1) {
        final groupName = parts[0];
        final keyName = parts.sublist(1).join('/');
        grouped.putIfAbsent(groupName, () => {});
        grouped[groupName]![keyName] = entry.value;
      } else {
        // Root level items (no group)
        grouped.putIfAbsent('_root', () => {});
        grouped['_root']![entry.key] = entry.value;
      }
    }

    return grouped;
  }

  Widget _buildGroup(
    BuildContext context,
    String groupName,
    Map<String, dynamic> items,
  ) {
    // Root items - no header
    if (groupName == '_root') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var entry in items.entries)
            _buildDataRow(context, entry.key, entry.value),
        ],
      );
    }

    // Collapsible group
    final isCollapsed = DevHudService.instance.isGroupCollapsed(groupName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        InkWell(
          onTap: () => DevHudService.instance.toggleGroup(groupName),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  isCollapsed ? Icons.chevron_right : Icons.expand_more,
                  color: Colors.white54,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  groupName,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "(${items.length})",
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ],
            ),
          ),
        ),

        // Group items
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var entry in items.entries)
                  _buildDataRow(context, entry.key, entry.value),
              ],
            ),
          ),
      ],
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
        // Try to show feedback, but don't crash if messengerKey is not set
        final messengerState = DevHudService.messengerKey.currentState;
        if (messengerState != null) {
          messengerState.showSnackBar(
            SnackBar(
              content: Text(
                "Copied '$key' to clipboard",
                style: const TextStyle(color: Colors.white),
              ),
              duration: const Duration(seconds: 1),
              backgroundColor: const Color(0xFF333333),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Fallback: print to console if messengerKey is not configured
          debugPrint(
            "DevHud: Copied '$key: $displayValue' to clipboard. "
            "(Set scaffoldMessengerKey for visual feedback)",
          );
        }
      },
      borderRadius: BorderRadius.circular(4),
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
