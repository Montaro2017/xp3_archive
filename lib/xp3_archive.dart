import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:xp3_archive/xp3_constant.dart';
import 'package:xp3_archive/extension/uint8_list_extension.dart';
import 'package:xp3_archive/extension/input_stream_base_extension.dart';

class XP3Archive {
  final InputFileStream _is;
  final List<XP3FileInfo> fileInfoList = [];
  final Map<String, XP3FileInfo> _fileInfoMap = {};

  late XP3ArchiveType type;
  int offset = -1;

  XP3Archive(this._is) {
    _initOffset();
    _initFileInfoList();
  }

  XP3Archive.fromPath(String path) : this(InputFileStream(path));

  void saveTo(String pathInArchive, String savePath) {
    bool isDirectory = savePath.endsWith("/") || savePath.endsWith("\\");
    String fullPath = isDirectory ? savePath + pathInArchive : savePath;
    OutputFileStream ofs = OutputFileStream(fullPath);

    if (!_fileInfoMap.containsKey(pathInArchive)) {
      throw "'$pathInArchive' not exist";
    }
    XP3FileInfo fileInfo = _fileInfoMap[pathInArchive]!;
    for (var segment in fileInfo.segments) {
      _writeSegment(segment, ofs);
    }
    ofs.flush();
  }

  void extractTo(Directory directory,
      [void Function(XP3FileInfo fileInfo)? callback]) {
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    String savePath = "${directory.absolute.path}\\";
    for (XP3FileInfo fileInfo in fileInfoList) {
      saveTo(fileInfo.name, savePath);
      callback?.call(fileInfo);
    }
  }

  void _writeSegment(Segment segment, OutputStreamBase osb) {
    _is.position = segment.start;
    InputStreamBase isb = _is.readBytes(segment.archiveSize);
    if (segment.isCompressed) {
      osb.writeBytes(zlib.decode(isb.toUint8List()));
    } else {
      osb.writeInputStream(isb);
    }
    osb.flush();
  }

  void _initOffset() {
    Uint8List header = _is.readBytes(11).toUint8List();
    if (xp3Mark.eq(header)) {
      type = XP3ArchiveType.XP3;
      offset = 0;
      return;
    }
    if (win32Mark[0] == header[0] && win32Mark[1] == header[1]) {
      offset = _findOffsetInExe();
      type = XP3ArchiveType.EXE;
      return;
    }
    throw "Unknown XP3 Archive";
  }

  int _findOffsetInExe() {
    _is.position = 16;
    int readLength = 256 * 1024;
    int offset = 16;
    bool found = false;
    while (!_is.isEOS) {
      InputStreamBase isb = _is.readBytes(readLength);
      int pos = 0;
      while (pos < readLength) {
        isb.position = pos;
        if (xp3Mark.eq(isb.readBytes(11).toUint8List())) {
          offset += pos;
          found = true;
          break;
        }
        pos += 16;
      }
      if (found) {
        return offset;
      }
      offset += readLength;
    }
    throw "Can not find XP3 mark in file";
  }

  void _initFileInfoList() {
    _is.position = xp3Mark.length + offset;
    while (true) {
      _IndexData indexData = _readIndexData();
      _readFileInfoList(indexData.indexData);
      if ((indexData.indexFlag & tvpXP3IndexContinue) == 0) {
        break;
      }
    }
  }

  _IndexData _readIndexData() {
    int indexOffset = _is.readUint64();
    _is.position = offset + indexOffset;
    int indexFlag = _is.readByte();
    indexFlag = indexFlag & tvpXP3IndexEncodeMethodMask;

    int indexSize;
    InputStreamBase indexData;
    if (indexFlag == tvpXP3IndexEncodeMethodZlib) {
      int compressedSize = _is.readUint64();
      indexSize = _is.readUint64();
      indexData = _is.readBytes(compressedSize);
      indexData = InputStream(zlib.decode(indexData.toUint8List()));
      if (indexData.length != indexSize) {
        throw "Read compressed size does not match data length.";
      }
    } else if (indexFlag == tvpXP3IndexEncodeMethodRaw) {
      indexSize = _is.readUint64();
      indexData = _is.readBytes(indexSize);
    } else {
      throw "Unknown index flag value $indexFlag";
    }
    return _IndexData(
      indexOffset: indexOffset,
      indexFlag: indexFlag,
      indexSize: indexSize,
      indexData: indexData,
    );
  }

  void _readFileInfoList(InputStreamBase isb) {
    int start = 0;
    int size = isb.length;
    while (!isb.isEOS) {
      _XP3Chunk? fileChunk = _findChunk(isb, cnFile, start, size);
      if (fileChunk == null) {
        break;
      }
      start = fileChunk.start;
      size = fileChunk.start;

      XP3FileInfo fileInfo = _readFileInfo(isb, fileChunk);
      fileInfo.segments.addAll(_readSegments(isb, fileChunk));
      fileInfo.fileHash = _readFileHash(isb, fileChunk);

      fileInfoList.add(fileInfo);
      _fileInfoMap[fileInfo.name] = fileInfo;
      start += fileChunk.size;
      size = isb.length;
    }
  }

  XP3FileInfo _readFileInfo(InputStreamBase isb, _XP3Chunk fileChunk) {
    _XP3Chunk infoChunk =
        _findChunk(isb, cnInfo, fileChunk.start, fileChunk.size)!;
    isb.position = infoChunk.start;
    int flag = isb.readUint32();
    int originSize = isb.readUint64();
    int archiveSize = isb.readUint64();
    int nameLength = isb.readUint16();
    String name = isb.readUTF8StringLE(nameLength);
    return XP3FileInfo(name, originSize, archiveSize);
  }

  List<Segment> _readSegments(InputStreamBase isb, _XP3Chunk fileChunk) {
    List<Segment> segmentList = [];
    _XP3Chunk segmentChunk =
        _findChunk(isb, cnSegment, fileChunk.start, fileChunk.size)!;
    int segmentCount = segmentChunk.size ~/ 28;
    int offsetInArchive = 0;
    for (int i = 0; i < segmentCount; i++) {
      int basePos = i * 28 + segmentChunk.start;
      isb.position = basePos;
      int flags = isb.readUint32();
      flags = flags & tvpXP3SegmentEncodeMethodMask;
      bool isCompressed;
      if (flags == tvpXP3SegmentEncodeRaw) {
        isCompressed = false;
      } else if (flags == tvpXP3SegmentEncodeZlib) {
        isCompressed = true;
      } else {
        throw "Unknown segment flag $flags";
      }
      int start = isb.readUint64();
      int originSize = isb.readUint64();
      int archiveSize = isb.readUint64();
      segmentList.add(
        Segment(
          start: start,
          offset: offsetInArchive,
          originSize: originSize,
          archiveSize: archiveSize,
          isCompressed: isCompressed,
        ),
      );
      offsetInArchive += archiveSize;
    }
    return segmentList;
  }

  int _readFileHash(InputStreamBase isb, _XP3Chunk fileChunk) {
    _XP3Chunk adlrChunk =
        _findChunk(isb, cnAdlr, fileChunk.start, fileChunk.size)!;
    isb.position = adlrChunk.start;
    return isb.readUint32();
  }

  _XP3Chunk? _findChunk(
    InputStreamBase isb,
    Uint8List find,
    int start,
    int size,
  ) {
    isb.position = start;
    while (!isb.isEOS) {
      var read = isb.readBytes(4).toUint8List();
      bool found = read.eq(find);
      int chunkSize = isb.readUint64();
      if (found) {
        return _XP3Chunk(isb.position, chunkSize);
      }
      isb.skip(chunkSize);
    }
    return null;
  }
}

class _XP3Chunk {
  int start;
  int size;

  _XP3Chunk(this.start, this.size);
}

class _IndexData {
  int indexOffset;
  int indexFlag;
  int indexSize;
  InputStreamBase indexData;

  _IndexData({
    required this.indexOffset,
    required this.indexFlag,
    required this.indexSize,
    required this.indexData,
  });
}

class Segment {
  int start;
  int offset;
  int originSize;
  int archiveSize;
  bool isCompressed;

  Segment({
    required this.start,
    required this.offset,
    required this.originSize,
    required this.archiveSize,
    required this.isCompressed,
  });
}

class XP3FileInfo {
  String name;
  late int fileHash;
  int originSize;
  int archiveSize;
  List<Segment> segments = [];

  XP3FileInfo(this.name, this.originSize, this.archiveSize);

  addSegment(Segment segment) {
    segments.add(segment);
  }

  @override
  String toString() {
    return name;
  }
}

enum XP3ArchiveType { XP3, EXE }

