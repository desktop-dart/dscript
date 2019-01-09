import "dart:async";
import "dart:io";
import 'dart:convert';
import 'dart:collection';

enum _State {
  notFound,
  findHeader,
  data,
  closed,
}

/// Extracts pubspec embedded in dscript
Future<UnmodifiableListView<String>> extractPubspec(
    String scriptFilename) async {
  final file = File(scriptFilename);

  if (!file.existsSync()) {
    throw Exception('Script file $scriptFilename not found!');
  }

  // Read script file as lines
  final Stream<String> lines =
      await file.openRead().transform(utf8.decoder).transform(LineSplitter());

  List<String> pubspec;
  _State state = _State.notFound;

  await for (String line in lines) {
    switch (state) {
      case _State.notFound:
        final String trimmed = line.trim();
        if (trimmed == r'/*') {
          state = _State.findHeader;
        } else if (trimmed == r'/* @pubspec.yaml') {
          state = _State.data;
          pubspec = <String>[];
        }
        break;
      case _State.findHeader:
        final String trimmed = line.trim();
        if (trimmed == r'@pubspec.yaml') {
          state = _State.data;
          pubspec = <String>[];
        } else {
          state = _State.notFound;
        }
        break;
      case _State.data:
        final String trimmed = line.trim();
        if (trimmed == r'*/') {
          state = _State.closed;
        } else {
          pubspec.add(line);
        }
        break;
      case _State.closed:
        break;
    }

    if (state == _State.closed) {
      break;
    }
  }

  if (pubspec == null) return null;

  return UnmodifiableListView<String>(pubspec);
}
