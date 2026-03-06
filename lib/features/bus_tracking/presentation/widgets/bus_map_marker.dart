import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/bus_tracking.dart';

/// A map marker widget representing a bus location.
/// Shows heading direction, online/offline status, and speed.
class BusMapMarker extends StatelessWidget {
  final BusLatestLocation location;
  final bool isSelected;
  final VoidCallback? onTap;

  const BusMapMarker({
    super.key,
    required this.location,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = !location.isStale;
    final color = isOnline ? AppColors.success : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed label
          if (isOnline && location.speedKmh > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: AppColors.info,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                location.speedFormatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Bus icon with heading
          Container(
            padding: EdgeInsets.all(isSelected ? 6 : 4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : color,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? AppColors.primary : color)
                      .withValues(alpha: 0.3),
                  blurRadius: isSelected ? 8 : 4,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Transform.rotate(
              angle: location.heading * math.pi / 180,
              child: Icon(
                Icons.navigation,
                color: color,
                size: isSelected ? 20 : 16,
              ),
            ),
          ),

          // Pulse effect for online vehicles
          if (isOnline)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
