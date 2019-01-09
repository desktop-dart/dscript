import "dart:io";
import 'dart:async';
import 'package:path/path.dart' as p;
import 'dart:convert';

abstract class DartSdk {
  factory DartSdk.detect() => DetectedDartSdk.detect();

  FutureOr<PubGetResult> pubGet({String workingDir});

  Future<String> get versionString;

  Future<String> get version;
}

class DartSdkInPath {}

/// The [DartSdk] implementation where the Dart sdk directory is detected.
class DetectedDartSdk implements DartSdk {
  /// Path of Dart SDK
  final String sdkPath;

  DetectedDartSdk(this.sdkPath);

  factory DetectedDartSdk.detect() {
    String executable = Platform.executable;
    final String s = Platform.pathSeparator;

    if (!executable.contains(s)) {
      if (Platform.isLinux) {
        executable = Link("/proc/$pid/exe").resolveSymbolicLinksSync();
      }
    }

    final file = File(executable);
    if (!file.existsSync()) {
      throw dartSdkNotFound;
    }

    Directory parent = file.absolute.parent;
    parent = parent.parent; // TODO What if this does not exist?

    final String sdkPath = parent.path;
    final String dartApi = "$sdkPath${s}include${s}dart_api.h";
    if (!File(dartApi).existsSync()) {
      throw Exception('Cannot find Dart SDK!');
    }

    return DetectedDartSdk(sdkPath);
  }

  String get dartPath => p.join(sdkPath, 'bin', 'dart');

  // TODO create it during construction
  String get pubPath => p.join(sdkPath, 'bin', 'pub');

  Future<ProcessResult> pub(List<String> arguments, {String workingDir}) =>
      Process.run(pubPath, arguments, workingDirectory: workingDir);

  Future<PubGetResult> pubGet({String workingDir}) async {
    final ProcessResult res =
        await pub(<String>['get'], workingDir: workingDir);
    if (res.exitCode == 0) {
      return PubGetResult(res.stdout);
    } else {
      throw PubGetException(res.exitCode, res.stdout, res.stderr);
    }
  }

  Future<String> get versionString async {
    final ProcessResult res =
        await Process.run(dartPath, <String>['--version']);
    if (res.exitCode != 0) {
      throw Exception('Failed!');
    }
    return res.stderr;
  }

  Future<String> get version async {
    return (await versionString)
        .substring('Dart VM version: '.length)
        .split(' ')
        .first;
  }
}

final Exception dartSdkNotFound = Exception('Dart SDK not found!');

class DepInfo {
  final String name;

  final String version;

  const DepInfo(this.name, this.version);
}

class PubGetResult {
  final String outlog;

  PubGetResult(this.outlog);

  List<DepInfo> get added => LineSplitter()
      .convert(outlog)
      .where((String line) => line.startsWith('+ '))
      .map((String line) => line.split(' '))
      .where((List<String> parts) => parts.length == 3)
      .map((List<String> parts) => DepInfo(parts[1], parts[2]))
      .toList();

  List<DepInfo> get removed => LineSplitter()
      .convert(outlog)
      .where((String line) => line.startsWith('- '))
      .map((String line) => line.split(' '))
      .where((List<String> parts) => parts.length == 3)
      .map((List<String> parts) => DepInfo(parts[1], parts[2]))
      .toList();
}

class PubGetException {
  final int exitCode;

  final String stdout;

  final String stderr;

  PubGetException(this.exitCode, this.stdout, this.stderr);
}
