import "dart:io";
import 'dart:async';
import 'package:path/path.dart' as p;

abstract class DartSdk {
  factory DartSdk.detect() => new DetectedDartSdk.detect();

  ProcessResult pubGet({String workingDir});

  Future<String> get versionString;
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
        executable = new Link("/proc/$pid/exe").resolveSymbolicLinksSync();
      }
    }

    final file = new File(executable);
    if (!file.existsSync()) {
      throw dartSdkNotFound;
    }

    Directory parent = file.absolute.parent;
    parent = parent.parent; // TODO What if this does not exist?

    final String sdkPath = parent.path;
    final String dartApi = "$sdkPath${s}include${s}dart_api.h";
    if (!new File(dartApi).existsSync()) {
      throw new Exception('Cannot find Dart SDK!');
    }

    return new DetectedDartSdk(sdkPath);
  }

  String get dartPath => p.join(sdkPath, 'bin', 'dart');

  // TODO create it during construction
  String get pubPath => p.join(sdkPath, 'bin', 'pub');

  ProcessResult pub(List<String> arguments, {String workingDir}) =>
      Process.runSync(pubPath, arguments, workingDirectory: workingDir);

  ProcessResult pubGet({String workingDir}) =>
      pub(<String>['get'], workingDir: workingDir);

  Future<String> get versionString async {
    final ProcessResult res =
        await Process.run(dartPath, <String>['--version']);
    if (res.exitCode != 0) {
      throw new Exception('Failed!');
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

final Exception dartSdkNotFound = new Exception('Dart SDK not found!');
