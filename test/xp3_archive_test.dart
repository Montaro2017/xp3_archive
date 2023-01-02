import 'package:xp3_archive/xp3_archive.dart';
import 'package:test/test.dart';

void main() {
  test("xp3Archive", () {
    var archive = XP3Archive.fromPath(r"D:\Projects\data.xp3");
    for (var fileInfo in archive.fileInfoList) {
      print(fileInfo.name);
    }
    print("Type = ${archive.type}");
  });
}
