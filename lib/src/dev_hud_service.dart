import 'package:flutter/foundation.dart';

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

  DevHudService._();

  // Internal storage for data
  final Map<String, dynamic> _data = {};

  /// Provides read-only access to the current data map.
  Map<String, dynamic> get data => _data;

  /// Updates or adds a single key-value pair to the HUD.
  ///
  /// [key] is the label shown on the left.
  /// [value] is the data shown on the right. It can be of any type,
  /// but primitive types (int, double, bool, String) are recommended.
  ///
  /// Example:
  /// ```dart
  /// DevHudService.instance.update("FPS", 60);
  /// ```
  void update(String key, dynamic value) {
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
    _data.addAll(newValues);
    notifyListeners();
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
}
