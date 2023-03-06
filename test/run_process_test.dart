// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:task_runner/task_runner.dart';
import 'package:test/test.dart';

void main() {
  test('RunProcess dart', () async {
    final temp = await Directory.systemTemp.createTemp();
    final mainDart = File.fromUri(temp.uri.resolve('main.dart'));
    final contents = '''
void main(){
  print('hello world!');
}''';
    await mainDart.writeAsString(contents);

    final runner = TaskRunner(
      dartExecutable: Uri.parse(Platform.executable),
    );
    final task = RunProcess(
      executable: 'dart',
      arguments: ['main.dart'],
      workingDirectory: temp.uri,
    );
    await runner.run(task);

    await mainDart.writeAsString('''
import 'dart:io';

void main(){
  exit(1);
}''');
    expect(runner.run(task), throwsException);

    final task2 = RunProcess(
      executable: 'dart',
      arguments: ['main.dart'],
      workingDirectory: temp.uri,
      throwOnFailure: false,
    );
    await runner.run(task2);
  });
}
