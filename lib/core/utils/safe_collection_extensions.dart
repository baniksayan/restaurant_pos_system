// lib/core/utils/safe_collection_extensions.dart

extension SafeIterable<T> on Iterable<T> {
  /// Safely gets the first element, returns null if empty
  T? get safeFirst => isEmpty ? null : first;
  
  /// Safely gets the last element, returns null if empty
  T? get safeLast => isEmpty ? null : last;
  
  /// Safely gets the first element where condition matches
  T? safeFirstWhere(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
  
  /// Gets first element or default value
  T firstOrDefault(T defaultValue) => isEmpty ? defaultValue : first;
  
  /// Gets last element or default value  
  T lastOrDefault(T defaultValue) => isEmpty ? defaultValue : last;
}

extension SafeList<T> on List<T> {
  /// Safely gets element at index, returns null if out of bounds
  T? safeElementAt(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
  
  /// Gets element at index or default value
  T elementAtOrDefault(int index, T defaultValue) {
    if (index < 0 || index >= length) return defaultValue;
    return this[index];
  }
}
