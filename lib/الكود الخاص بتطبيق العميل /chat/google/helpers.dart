import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago; // Add timeago dependency

class Helpers {
  /// Formats duration into HH:MM:SS or MM:SS string.
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (hours > 0) hours, minutes, seconds].join(':');
  }

  /// Converts DateTime to human-readable text (e.g., "10:30 AM", "Yesterday", "5 minutes ago").
  static String dateTimeToText(DateTime? dt, {bool short = false}) {
    if (dt == null) return "";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(dt.year, dt.month, dt.day);

    if (messageDate == today) {
      return DateFormat.jm().format(dt); // e.g., 10:30 AM
    } else if (messageDate == yesterday) {
      return "Yesterday${short ? '' : ' at ${DateFormat.jm().format(dt)}'}";
    } else if (now.difference(dt) < const Duration(days: 7)) {
      // Use timeago for recent dates like "5 minutes ago", "2 hours ago"
      // You might need to configure timeago locales
      timeago.setLocaleMessages('en_short', timeago.EnShortMessages()); // Example short format
      return timeago.format(dt, locale: short ? 'en_short' : 'en'); // Default locale or short
    } else {
      return DateFormat('dd/MM/yyyy${short ? '' : ' hh:mm a'}').format(dt); // Older dates
    }
  }
}