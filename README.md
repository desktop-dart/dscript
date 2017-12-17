# dscript

Execute standalone Dart shell scripts

# Installation

`dscript` can be using pub:

```bash
pub global activate dscript
```

Make sure, it is installed in your path:

```bash
dscript version
```

Lookup `dscript` command documentation:

```bash
dscript help
```

# Usage

## Execute standalone Dart script

Create a Dart standalone script:

**list.dart**
```dart
import 'dart:io';

main() async {
  final dir = Directory.current;

  await for(FileSystemEntity entity in dir.list()) {
    final FileStat stat = await entity.stat();
    if(stat.type == FileSystemEntityType.FILE) {
      print(entity.uri.pathSegments.last);
    } else if (stat.type == FileSystemEntityType.DIRECTORY) {
      print(entity.uri.pathSegments.reversed.elementAt(1));
    }
  }
}
```

Execute it:

```bash
dscript list.dart
```

The following screen cast shows how to execute a Dart standalone shell script using `dscript`: 

[![asciicast](https://asciinema.org/a/153020.png?size=small)](https://asciinema.org/a/153020)

## Embedded pubspec

`dscript` allows embedding pubspec in the scripts itself.

```dart
/*
@pubspec.yaml
name: list
 */

import 'dart:io';

main() async {
  final dir = Directory.current;

  await for(FileSystemEntity entity in dir.list()) {
    final FileStat stat = await entity.stat();
    if(stat.type == FileSystemEntityType.FILE) {
      print(entity.uri.pathSegments.last);
    } else if (stat.type == FileSystemEntityType.DIRECTORY) {
      print(entity.uri.pathSegments.reversed.elementAt(1));
    }
  }
}
```

Execute it:

```bash
dscript list.dart
```

## Scripts with dependencies

We can leverage embedded pubspec to use external packages from pub.dartlang.org or github.  

**ok.dart**
```dart
/*
@pubspec.yaml
name: ok
dependencies:
  zenity:
*/

import 'package:zenity/zenity.dart';

main() async {
  final bool isOk = await Zenity.showQuestionMessage(
      title: 'Hello!', text: 'Are you feeling ok?');
  if(isOk) print(':)');
  else print(':(');
}
```

Execute it:

```bash
dscript ok.dart
```

[![asciicast](https://asciinema.org/a/153072.png?size=small)](https://asciinema.org/a/153072)

## Multi file scripts

**math.dart**
```dart
/*
@pubspec.yaml
name: calc
*/

import 'dart:io';
import 'package:calc/calc.dart';

void printUsage() {
  print('calc arg1 operator arg2');
  print('Supported operators:');
  print('  + : Addition');
  print('  - : Subtraction');
  print('  * : Multiplication');
  print('  / : Division');
}

main(List<String> arguments) {
  if(arguments.length != 3) {
    printUsage();
    exit(1);
  }

  final int a = int.parse(arguments[0]);
  final int b = int.parse(arguments[0]);

  Function op;
  switch (arguments[1]) {
    case '+':
      op = add;
      break;
    case '-':
      op = sub;
      break;
    case '*':
      op = mul;
      break;
    case '/':
      op = div;
      break;
    default:
      print('Invalid operator!\n');
      printUsage();
      exit(1);
  }

  int res = op(a, b);
  print('=> $res');
}
```

**lib/calc.dart**
```dart
int add(int a, int b) => a + b;

int sub(int a, int b) => a - b;

int mul(int a, int b) => a * b;

int div(int a, int b) => a ~/ b;
```

Execute it:

```bash
dscript math.dart 20 + 5
```

[![asciicast](https://asciinema.org/a/153074.png?size=small)](https://asciinema.org/a/153074)

## Shebang

Shebangs can be used to execute a Dart script directly.

**say_hello.dart**
```dart
#! /usr/bin/env dscript

main() {
  print('Hello!');
}

``` 

Make it executable:
```bash
chmod ug+x say_hello.dart
```

Execute it:
```bash
./say_hello.dart
```

Put it in system `PATH` and use it like any other shell script!