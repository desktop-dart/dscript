import "dart:async";
import "dart:io";
import 'dart:collection';

import 'args.dart';
import 'dart_sdk.dart';
import 'project_creator.dart';

/// Runs a Dart dscript
class ScriptRunner {
  final Args options;

  final UnmodifiableListView<String> pubspec;

  final String workingDir;

  final DartSdk sdk;

  final String tempProjectDir;

  ScriptRunner._(this.options, this.sdk, this.pubspec,
      {this.workingDir, this.tempProjectDir});

  Future createProject() async {
    final creator = ProjectCreator(tempProjectDir, pubspec);
    await creator.exec();

    final project = Project(tempProjectDir);
    await project.pubGet(withSdk: sdk);
  }

  /// Executes the script
  Future<int> exec() async {
    // Prepare VM arguments
    final vmArgs = <String>[];
    vmArgs.add("--checked");
    vmArgs.addAll(["--packages=$tempProjectDir/.packages"]);
    vmArgs.add(options.script);
    vmArgs.addAll(options.arguments);

    // Execute the script
    final Process process = await Process.start(Platform.executable, vmArgs,
        workingDirectory: workingDir);

    // Pipe std out and in
    final StreamSubscription stderrSub =
        process.stderr.listen((List<int> d) => stderr.add(d));
    final StreamSubscription stdoutSub =
        process.stdout.listen((List<int> d) => stdout.add(d));
    final StreamSubscription stdinSub =
        stdin.listen((List<int> d) => process.stdin.add(d));

    final int exitCode = await process.exitCode;

    final futures = <Future>[];

    futures.add(stderrSub.cancel());
    futures.add(stdoutSub.cancel());
    futures.add(stdinSub.cancel());

    await Future.wait(futures);

    return exitCode;
  }

  static Future<ScriptRunner> make(
      Args options, DartSdk sdk, UnmodifiableListView<String> pubspec,
      {String workingDir, String tempProjectDir}) async {
    workingDir ??= Directory.current.path;
    tempProjectDir ??= Directory.systemTemp.createTempSync().path;

    return ScriptRunner._(options, sdk, pubspec,
        workingDir: workingDir, tempProjectDir: tempProjectDir);
  }
}

class Project {
  final String projectDir;

  Project(this.projectDir);

  Future<PubGetResult> pubGet({DartSdk withSdk}) async =>
      withSdk.pubGet(workingDir: projectDir);
}
