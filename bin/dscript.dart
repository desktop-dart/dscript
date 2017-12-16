import "dart:io";
import 'package:dscript/dscript.dart';

main(List<String> arguments) async {
  final options = new Args.parse(arguments);

  final DetectedDartSdk sdk = new DartSdk.detect();

  if (options.verbose) {
    stderr.writeln(
        'dscript: Dart SDK found at ${sdk.sdkPath} with version ${await sdk.version}');
  }

  final Iterable<String> pubspec = await extractPubspec(options.script);

  final ScriptRunner runner = await ScriptRunner.make(options, sdk, pubspec);

  if (options.verbose) {
    stderr.writeln('dscript: Temporary project path at ${runner.tempProjectDir}');
  }

  await runner.createProject();

  final int exitCode = await runner.exec();

  if (options.deleteProject) {
    if (options.verbose) {
      stderr.writeln('dscript: Deleting project');
    }
    try {
      await new Directory(runner.tempProjectDir).delete(recursive: true);
    } finally {

    }
  }

  if (options.verbose) {
    stderr.writeln('dscript: Exiting with code $exitCode');
  }

  await stderr.flush();

  exit(exitCode);
}
