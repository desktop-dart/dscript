import "dart:async";
import "dart:io";
import 'dart:collection';
import 'package:path/path.dart' as p;

/// Creates project directory structure
class ProjectCreator {
  final String projectDir;

  final UnmodifiableListView<String> pubspec;

  ProjectCreator(this.projectDir, this.pubspec);

  Future exec() async {
    await createProjectDir();

    final futures = <Future>[];

    futures.add(createLibDir());
    futures.add(createPubspec());

    await Future.wait(futures);
  }

  /// If directory named [projectDir] does not exist, create it.
  Future createProjectDir() async {
    final directory = new Directory(projectDir);

    if (await directory.exists()) {
      return;
    }

    await directory.create(recursive: true);
  }

  Future createLibDir() async {
    final directory = new Directory("lib");

    if (!await directory.exists()) {
      return;
    }

    final String libDirPath = p.join(projectDir, 'lib');
    final link = new Link(libDirPath);
    await link.create(directory.absolute.path);
  }

  Future createPubspec() async {
    final String filePath = p.join(projectDir, "pubspec.yaml");
    final file = new File(filePath);
    await file.writeAsString(pubspec.join('\n'));
  }
}
