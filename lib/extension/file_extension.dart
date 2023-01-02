import 'dart:io';

extension FileExtension on File {
  String get shortName {
    int dot = path.lastIndexOf(".");
    if (dot == -1) {
      return path;
    }
    return path.substring(0, dot);
  }
}
