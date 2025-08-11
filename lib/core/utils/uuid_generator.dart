import 'dart:math';

class UuidGenerator {
  static String generate() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(999999).toString().padLeft(6, '0');
    return 'table_${timestamp}_$randomSuffix';
  }
}
