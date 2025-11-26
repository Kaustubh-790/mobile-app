import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusUtils {
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.success;
      case 'confirmed':
        return AppTheme.primaryDefault;
      case 'pending':
        return AppTheme.warning;
      case 'cancelled':
        return AppTheme.error;
      case 'rescheduled':
        return AppTheme.brown300;
      default:
        return AppTheme.brown200;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'confirmed':
        return Icons.verified;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      case 'rescheduled':
        return Icons.update;
      default:
        return Icons.info;
    }
  }

  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'rescheduled':
        return 'Rescheduled';
      default:
        return status;
    }
  }
}
