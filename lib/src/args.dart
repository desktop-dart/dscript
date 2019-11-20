import 'dart:collection';

class OptionsException implements Exception {}

class DuplicateOptionsException implements OptionsException {
  final String optionName;

  DuplicateOptionsException(this.optionName);

  String toString() => 'Option $optionName used twice!';
}

class UnknownOption implements OptionsException {
  final String optionName;

  UnknownOption(this.optionName);

  String toString() => 'The option $optionName is unknown!';
}

class Args {
  /// Main script name
  final String script;

  /// Arguments
  final UnmodifiableListView<String> arguments;

  /// Execute in verbose mode
  final bool verbose;

  final bool deleteProject;

  Args(this.script, this.arguments,
      {this.verbose = false, this.deleteProject = true});

  factory Args.parse(List<String> arguments) {
    final isRedundant = <String, bool>{};
    bool verbose = false;
    bool deleteProject = true;
    String script;
    UnmodifiableListView<String> args = UnmodifiableListView<String>([]);

    for (int i = 0; i < arguments.length; i++) {
      final String argument = arguments[i];

      if (argument.startsWith('-')) {
        if (argument == '-v' || argument == '--verbose') {
          if (isRedundant.containsKey('-v')) {
            throw DuplicateOptionsException('--verbose');
          }
          verbose = true;
          isRedundant['-v'] = true;
        } else if (argument == '-k' || argument == '--keep-project') {
          if (isRedundant.containsKey('-k')) {
            throw DuplicateOptionsException('--keep-project');
          }
          deleteProject = false;
          isRedundant['-k'] = true;
        } else {
          throw UnknownOption(argument);
        }
        continue;
      }

      script = argument;
      if (i != (arguments.length - 1)) {
        args = UnmodifiableListView<String>(arguments.sublist(i + 1));
      }
      break;
    }

    if (script == null) throw Exception('Script not provided!');

    return Args(script, args, verbose: verbose, deleteProject: deleteProject);
  }
}
