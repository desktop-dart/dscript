import "dart:io";
import 'package:dscript/dscript.dart';
import 'dart:collection';

main(List<String> arguments) async {
  if (probeSubCommands(arguments)) {
    exit(0);
  }

  final options = new Args.parse(arguments);

  final DetectedDartSdk sdk = new DartSdk.detect();

  if (options.verbose) {
    stderr.writeln(
        'dscript: Dart SDK found at ${sdk.sdkPath} with version ${await sdk.version}');
  }

  UnmodifiableListView<String> pubspec = await extractPubspec(options.script);

  if (pubspec == null || pubspec.length == 0) {
    if (options.verbose) {
      stderr.writeln(
          'dscript: Embedded pubspec not found in script. Providing defualt pubspec');
    }
    pubspec = new UnmodifiableListView<String>(<String>['name: a_dart_script']);
  } else {
    if (options.verbose) {
      stderr.writeln('dscript: Embedded pubspec found in script');
    }
  }

  final ScriptRunner runner = await ScriptRunner.make(options, sdk, pubspec);

  if (options.verbose) {
    stderr
        .writeln('dscript: Temporary project path at ${runner.tempProjectDir}');
  }

  try {
    await runner.createProject();
  } on PubGetException catch (e) {
    stderr.writeln(
        'dscript: Running "pub get" failed with exit code ${e.exitCode}!');
    if (options.verbose) {
      stderr.writeln(e.stderr);
    }
    exit(1);
  }

  final int exitCode = await runner.exec();

  if (options.deleteProject) {
    if (options.verbose) {
      stderr.writeln('dscript: Deleting project');
    }
    try {
      await new Directory(runner.tempProjectDir).delete(recursive: true);
    } finally {}
  }

  if (options.verbose) {
    stderr.writeln('dscript: Exiting with code $exitCode');
  }

  await stderr.flush();

  exit(exitCode);
}

void printHelp() {
  print('dscript: Executes standalone Dart shell scripts.');
  print('');
  print('Usage: dscript [-v] [-k] [script-filename] [arguments...]');
  print('Example: -v calc.dart 20 + 5');
  print('');
  print('Options:');
  print('-v: Verbose');
  print('-k: Keep temporary project files');
  print('');
  print('');
  print('Sub-commands:');
  print('help: Prints help text');
  print('version: Prints version');
}

bool probeSubCommands(List<String> args) {
  if (args.length == 0) {
    print('Version: 1.0.0');
    print('');
    printHelp();
    return true;
  }

  switch (args[0]) {
    case 'version':
      print('1.0.0');
      return true;
    case 'help':
      printHelp();
      return true;
  }

  return false;
}
