import 'package:archive/archive_io.dart';

extension InputStreamBaseExtension on InputStreamBase {
  /// 不能直接使用readString 需要处理小端字节序才能读取
  String readUTF8StringLE(int length) {
    StringBuffer sb = StringBuffer();
    for (int i = 0; i < length; i++) {
      int code = readUint16();
      sb.write(String.fromCharCode(code));
    }
    return sb.toString();
  }
}