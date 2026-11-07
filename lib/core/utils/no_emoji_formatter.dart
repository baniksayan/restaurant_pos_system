import 'package:flutter/services.dart';

/// Comprehensive RegExp matching all Unicode emoji blocks, pictographs,
/// emoticons, symbols, flags, dingbats, and variation selectors.
final RegExp emojiRegex = RegExp(
  r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff]|[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{FE00}-\u{FE0F}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA70}-\u{1FAFF}])',
  unicode: true,
);

/// TextInputFormatter that denies all emoji and symbol characters
final TextInputFormatter noEmojiFormatter = FilteringTextInputFormatter.deny(
  emojiRegex,
);

/// Sanitizes a string by stripping any emojis or unsupported symbols
String removeEmojis(String text) {
  if (text.isEmpty) return '';
  return text.replaceAll(emojiRegex, '');
}
