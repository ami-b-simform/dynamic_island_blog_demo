import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class LiveActivityChannel {
  static const MethodChannel _channel = MethodChannel('com.example.dynamicIslandFlutter/live_activity',);


  /// Start a Live Activity — returns activityId
  static Future<String?> startRide({
    required String driverName,
    required String carModel,
    required String plateNumber,
    required String driverImagePath,
    required double distanceKm,
    required int etaMinutes,
    required String stage, // 'preparing' | 'pickedup' | 'arriving'
  }) async {
    try {
      final String? id = await _channel.invokeMethod('startActivity', {
        'driverName': driverName,
        'carModel': carModel,
        'plateNumber': plateNumber,
        'driverImagePath': driverImagePath,
        'distanceKm': distanceKm,
        'etaMinutes': etaMinutes,
        'stage': stage,
      });
      return id;
    } on PlatformException catch (e) {
      debugPrint('startActivity failed: ${e.message}');
      return null;
    }
  }

  /// Update live ride state
  static Future<void> updateRide({
    required String activityId,
    required double distanceKm,
    required int etaMinutes,
    required String stage,
    required String status,
  }) async {
    try {
      await _channel.invokeMethod('updateActivity', {
        'activityId': activityId,
        'distanceKm': distanceKm,
        'etaMinutes': etaMinutes,
        'stage': stage,
        'status': status,
      });
    } on PlatformException catch (e) {
      debugPrint('updateActivity failed: ${e.message}');
    }
  }

  /// End with a dismissal message
  static Future<void> endRide({
    required String activityId,
    required String finalMessage,
  }) async {
    try {
      await _channel.invokeMethod('endActivity', {
        'activityId': activityId,
        'finalMessage': finalMessage,
      });
    } on PlatformException catch (e) {
      debugPrint('endActivity failed: ${e.message}');
    }
  }

  /// Save driver image to App Group for Dynamic Island to read
  static Future<String?> saveImageToAppGroup({
    required String assetPath,
    required String fileName,
  }) async {
    try {
      final String? savedPath = await _channel.invokeMethod(
        'saveImageToAppGroup',
        {
          'assetPath': assetPath,
          'fileName': fileName,
        },
      );
      return savedPath;
    } on PlatformException catch (e) {
      debugPrint('saveImageToAppGroup failed: ${e.message}');
      return null;
    }
  }
}