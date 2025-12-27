// Performance optimization utilities
import 'dart:async';
import 'package:flutter/foundation.dart';

// Simple in-memory cache with expiration
class SimpleCache<T> {
  final Map<String, _CacheEntry<T>> _cache = {};
  final int? _maxSize;
  final Duration _defaultExpiry;

  SimpleCache({int? maxSize, Duration defaultExpiry = const Duration(hours: 1)}) : _maxSize = maxSize, _defaultExpiry = defaultExpiry;

  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }

    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  void put(String key, T value, {Duration? expiry}) {
    final expiration = expiry != null ? DateTime.now().add(expiry) : DateTime.now().add(_defaultExpiry);

    _cache[key] = _CacheEntry(value, expiration);

    // Remove oldest entries if cache is too large
    if (_maxSize != null && _cache.length > _maxSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiry;

  _CacheEntry(this.value, this.expiry);
}

// Debouncer utility to prevent too frequent calls
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

// Throttler utility to limit call frequency
class Throttler {
  final Duration duration;
  DateTime? _lastCall;

  Throttler({required this.duration});

  bool shouldExecute() {
    final now = DateTime.now();
    if (_lastCall == null || now.difference(_lastCall!) >= duration) {
      _lastCall = now;
      return true;
    }
    return false;
  }
}

// Lazy loading list item
class LazyLoadListItem<T> {
  final Future<T> Function() _loader;
  T? _value;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  LazyLoadListItem(this._loader);

  bool get isLoaded => _value != null;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  T? get value => _value;
  String? get errorMessage => _errorMessage;

  Future<T> load() async {
    if (_value != null) return _value!;

    if (_isLoading) {
      // Wait for loading to complete if already in progress
      await Future.delayed(const Duration(milliseconds: 100));
      return load();
    }

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;

    try {
      _value = await _loader();
      return _value!;
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
}

// Image optimization utility
class ImageOptimizationUtils {
  // Get optimized image URL based on device capabilities
  static String getOptimizedImageUrl(String originalUrl, {int quality = 80, int width = 800}) {
    // This is a placeholder - in a real app you'd use a service like Cloudinary
    // For now, just return the original URL
    return originalUrl;
  }

  // Calculate appropriate image size based on screen density and display size
  static Size calculateOptimalImageSize(double originalWidth, double originalHeight, double screenWidth, double screenHeight, {double scale = 1.0}) {
    // Calculate aspect ratio
    final aspectRatio = originalWidth / originalHeight;

    // Calculate optimal dimensions
    final optimalWidth = (screenWidth * scale).clamp(100.0, 1200.0);
    final optimalHeight = optimalWidth / aspectRatio;

    return Size(optimalWidth, optimalHeight);
  }
}

// Size utility
class Size {
  final double width;
  final double height;

  Size(this.width, this.height);

  Size clamp(double minWidth, double minHeight, double maxWidth, double maxHeight) {
    return Size(width.clamp(minWidth, maxWidth), height.clamp(minHeight, maxHeight));
  }
}

// Firestore query optimization helper
class FirestoreQueryOptimizer {
  // Batch operations for better performance
  static const int batchSize = 10; // Firestore batch limit is 500, but we use a smaller number for better UX

  // Pagination with limit and offset
  static Map<String, dynamic> buildPaginationQuery({
    int limit = 20,
    dynamic lastDocument,
    String orderByField = 'createdAt',
    bool descending = true,
  }) {
    return {'limit': limit, 'orderBy': orderByField, 'descending': descending, if (lastDocument != null) 'startAfter': lastDocument};
  }

  // Optimize queries by using specific field filters instead of array-contains when possible
  static String buildOptimizedQueryPath(String collection, List<String> filters) {
    // This would build an optimized query path based on the filters
    // In a real implementation, this would create compound queries
    return collection;
  }
}

// Memory management utilities
class MemoryUtils {
  // Clear image cache
  static void clearImageCache() {
    // This would clear Flutter's image cache
    // In a real implementation: PaintingBinding.instance.imageCache.clear();
  }

  // Clear image cache with specific parameters
  static void clearImageCacheWithParameters() {
    // In a real implementation:
    // PaintingBinding.instance.imageCache.clearLiveImages();
  }

  // Get memory usage information (platform specific)
  static Map<String, dynamic> getMemoryUsage() {
    // Placeholder implementation
    return {'used': 0, 'total': 0, 'free': 0};
  }
}
