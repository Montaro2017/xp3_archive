import 'dart:typed_data';

extension Uint8ListExtension on Uint8List {
  bool eq(Uint8List? other) {
    if (other == null) return false;
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) {
        return false;
      }
    }
    return true;
  }
}
