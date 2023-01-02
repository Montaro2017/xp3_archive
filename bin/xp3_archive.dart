import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:progress_bar/progress_bar.dart';
import 'package:xp3_archive/extension/file_extension.dart';
import 'package:xp3_archive/xp3_archive.dart';

void main(List<String> args) {
  CommandRunner("xp3_archive", "A tool to extract xp3 archive.")
    ..addCommand(ExtractCommand())
    /// ..addCommand(ListCommand())
    ..run(args);
}

class ExtractCommand extends Command {
  @override
  final name = "extract";
  @override
  final description = "Extract xp3 archive to directory.";

  ExtractCommand() {
    argParser
      ..addFlag(
        "print",
        abbr: "p",
        help: "Set should print extract file name",
      )
      // ..addFlag(
      //   "force",
      //   abbr: "f",
      //   help: "Set override write file",
      // )
      ..addOption(
        "input",
        abbr: "i",
        valueHelp: "file",
        help: "Set input file of xp3 or exe",
      )
      ..addOption(
        "output",
        abbr: "o",
        valueHelp: "dir",
        help: "Set output directory",
      );
  }

  @override
  void run() {
    String? input = argResults?["input"];
    String? output = argResults?["output"];
    bool shouldPrint = argResults?["print"] ?? false;
    bool force = false;
    if (input == null) {
      printUsage();
      return;
    }
    extract(
      input: input,
      output: output,
      shouldPrint: shouldPrint,
      force: force,
    );
  }

  void extract({
    required String input,
    String? output,
    required bool shouldPrint,
    required bool force,
  }) {
    File inputFile = File(input);
    Directory outputDir;
    output ??= inputFile.shortName;
    outputDir = Directory(output);
    print("Input file: ${inputFile.absolute.path}");
    print("Output dir: ${outputDir.absolute.path}");
    print("Print : $shouldPrint");
    /// print("Force : $force");
    print("");

    if (!inputFile.existsSync()) {
      print("Error: input file '${inputFile.absolute.path}' not exist.");
      return;
    }
    if (outputDir.existsSync() && outputDir.listSync().isNotEmpty && !force) {
      print("Directory '${outputDir.absolute.path}' exists.");
      return;
    }

    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
    print("Start extract file to output dir:\n");

    XP3Archive archive = XP3Archive.fromPath(inputFile.absolute.path);
    int total = archive.fileInfoList.length;
    int current = 0;
    var bar = ProgressBar("[:bar] :percent :etas", total: total, width: 50);
    archive.extractTo(outputDir.absolute, (fileInfo) {
      current++;
      if (shouldPrint) {
        print("($current/$total) ${fileInfo.name}");
      } else {
        bar.tick();
      }
    });
    print("Extract successfully!");
  }
}

class ListCommand extends Command {
  @override
  final name = "list";
  @override
  final description = "List filename in archive.";

  ListCommand() {
    argParser.addOption(
      "filter",
      abbr: "f",
      help: "such as *.png,*.jpg, use comma to separate multiple regex filters",
      valueHelp: "regex",
    );
  }

  @override
  void run() {}
}
