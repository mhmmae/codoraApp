// string_extensions.dart
extension StringTruncateExtension on String {
  String truncate({int maxLength = 50, String omission = "..."}) {
    if (length <= maxLength) {
      return this;
    }
    // تأكد من أن maxLength أكبر من طول omission
    if (maxLength <= omission.length) {
      return substring(0, maxLength); // أو أرجع omission مباشرة
    }
    return '${substring(0, maxLength - omission.length)}$omission';
  }
}