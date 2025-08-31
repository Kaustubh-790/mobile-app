class DateFormatter {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatDateTime(DateTime date, String? time) {
    final formattedDate = formatDate(date);

    if (time != null && time.isNotEmpty) {
      return '$formattedDate | $time';
    }
    return formattedDate;
  }

  static String formatDate(DateTime date) {
    final month = _months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year;
    return '$month $day, $year';
  }

  static String formatTime(String time) {
    if (time.isEmpty) return '';

    // Handle 24-hour format and convert to 12-hour if needed
    try {
      final timeParts = time.split(':');
      if (timeParts.length == 2) {
        final hour = int.parse(timeParts[0]);
        final minute = timeParts[1];

        if (hour >= 12) {
          final displayHour = hour == 12 ? 12 : hour - 12;
          return '${displayHour.toString().padLeft(2, '0')}:$minute PM';
        } else {
          final displayHour = hour == 0 ? 12 : hour;
          return '${displayHour.toString().padLeft(2, '0')}:$minute AM';
        }
      }
    } catch (e) {
      // If parsing fails, return the original time
    }

    return time;
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(date);
    }
  }
}
