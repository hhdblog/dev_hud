import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A singleton service that manages the key-value data displayed on the [DevHud] overlay.
///
/// You can access this service from anywhere in your application to update, remove,
/// or clear the debug data.
///
/// Example:
/// ```dart
/// DevHudService.instance.update("Player HP", 100);
/// ```
class DevHudService extends ChangeNotifier {
  // Singleton pattern
  static final DevHudService _instance = DevHudService._();

  /// Returns the singleton instance of [DevHudService].
  static DevHudService get instance => _instance;

  /// The key to the Flutter's [ScaffoldMessenger] widget.
  /// This is required for the clipboard copy feature to show SnackBar feedback.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  DevHudService._();

  // Internal storage for data
  final Map<String, dynamic> _data = {};

  // Collapsed state for groups
  final Set<String> _collapsedGroups = {};

  /// Provides read-only access to the current data map.
  Map<String, dynamic> get data => _data;

  /// Provides read-only access to collapsed groups.
  Set<String> get collapsedGroups => _collapsedGroups;

  // Position persistence keys
  static const String _posXKey = 'dev_hud_pos_x';
  static const String _posYKey = 'dev_hud_pos_y';

  /// Updates or adds a single key-value pair to the HUD.
  ///
  /// [key] is the label shown on the left. Use `/` to create groups.
  /// For example: `"Player/Health"`, `"Player/Score"` will be grouped under "Player".
  ///
  /// [value] is the data shown on the right. It can be of any type,
  /// but primitive types (int, double, bool, String) are recommended.
  ///
  /// Example:
  /// ```dart
  /// DevHudService.instance.update("FPS", 60);
  /// DevHudService.instance.update("Player/Health", 100);
  /// ```
  void update(String key, dynamic value) {
    // Skip if value hasn't changed (optimization)
    if (_data[key] == value) return;
    _data[key] = value;
    notifyListeners();
  }

  /// Updates multiple entries at once.
  ///
  /// This is more efficient than calling [update] multiple times
  /// if you have a batch of data changes.
  ///
  /// Example:
  /// ```dart
  /// DevHudService.instance.updateBatch({
  ///   "Speed": 120,
  ///   "Altitude": 5000,
  /// });
  /// ```
  void updateBatch(Map<String, dynamic> newValues) {
    bool hasChanges = false;
    for (final entry in newValues.entries) {
      if (_data[entry.key] != entry.value) {
        _data[entry.key] = entry.value;
        hasChanges = true;
      }
    }
    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Removes a specific entry from the HUD by its [key].
  void remove(String key) {
    if (_data.containsKey(key)) {
      _data.remove(key);
      notifyListeners();
    }
  }

  /// Clears all data from the HUD.
  ///
  /// Useful when resetting game state or logging out.
  void clear() {
    _data.clear();
    notifyListeners();
  }

  /// Toggles the collapsed state of a group.
  void toggleGroup(String groupName) {
    if (_collapsedGroups.contains(groupName)) {
      _collapsedGroups.remove(groupName);
    } else {
      _collapsedGroups.add(groupName);
    }
    notifyListeners();
  }

  /// Checks if a group is collapsed.
  bool isGroupCollapsed(String groupName) =>
      _collapsedGroups.contains(groupName);

  /// Saves the HUD position to persistent storage.
  Future<void> savePosition(Offset position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_posXKey, position.dx);
      await prefs.setDouble(_posYKey, position.dy);
    } catch (e) {
      debugPrint('DevHud: Failed to save position: $e');
    }
  }

  /// Loads the HUD position from persistent storage.
  Future<Offset?> loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble(_posXKey);
      final y = prefs.getDouble(_posYKey);
      if (x != null && y != null) {
        return Offset(x, y);
      }
    } catch (e) {
      debugPrint('DevHud: Failed to load position: $e');
    }
    return null;
  }

  /// Gets the current memory usage in MB.
  /// Returns null on platforms that don't support ProcessInfo (e.g., web).
  double? getMemoryUsageMB() {
    try {
      // ProcessInfo.currentRss returns bytes
      final bytes = ProcessInfo.currentRss;
      return bytes / (1024 * 1024);
    } catch (e) {
      return null;
    }
  }
}
