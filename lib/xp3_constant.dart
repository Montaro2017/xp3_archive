import 'dart:typed_data';

final Uint8List xp3Mark = Uint8List.fromList(
  [0x58, 0x50, 0x33, 0x0D, 0x0A, 0x20, 0x0A, 0x1A, 0x8B, 0x67, 0x01],
);

final Uint8List win32Mark = Uint8List.fromList(
  [0x4D, 0x5A],
);

final Uint8List cnFile = Uint8List.fromList(
  [0x46, 0x69, 0x6c, 0x65],
);
final Uint8List cnInfo = Uint8List.fromList(
  [0x69, 0x6e, 0x66, 0x6f],
);

final Uint8List cnSegment = Uint8List.fromList(
  [0x73, 0x65, 0x67, 0x6d],
);
final Uint8List cnAdlr = Uint8List.fromList(
  [0x61, 0x64, 0x6c, 0x72],
);

const int tvpXP3IndexEncodeMethodMask = 0x07;
const int tvpXP3IndexEncodeMethodZlib = 1;
const int tvpXP3IndexEncodeMethodRaw = 0;

const int tvpXP3IndexContinue = 0x80;

const int tvpXP3SegmentEncodeMethodMask = 0x07;
const int tvpXP3SegmentEncodeZlib = 1;
const int tvpXP3SegmentEncodeRaw = 0;