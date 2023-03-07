// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:task_runner/task_runner.dart';
import 'package:test/test.dart';

void main() {
  test('Copy.single', () async {
    final temp = await Directory.systemTemp.createTemp();
    final source = File.fromUri(temp.uri.resolve('source.txt'));
    const contents = 'contents';
    await source.writeAsString(contents);
    final target = File.fromUri(temp.uri.resolve('target.txt'));
    final task = Copy.single(source.uri, target.uri);
    await task.run();
    expect(await target.exists(), true);
    expect(await target.readAsString(), contents);
  });

  test('Copy.multipe', () async {
    final temp = await Directory.systemTemp.createTemp();
    final source = Directory.fromUri(temp.uri.resolve('source/'));
    await source.create();
    final sourceFile1 = File.fromUri(source.uri.resolve('file1.txt'));
    final sourceFile2 = File.fromUri(source.uri.resolve('file2.txt'));
    final sourceFile3 = File.fromUri(source.uri.resolve('file3.txt'));
    const contents = 'contents';
    await sourceFile1.writeAsString(contents);
    await sourceFile2.writeAsString(contents);
    await sourceFile3.writeAsString(contents);
    final target = Directory.fromUri(temp.uri.resolve('target/'));
    final task =
        Copy.multiple(source.uri, target.uri, ['file1.txt', 'file2.txt']);
    await task.run();
    final targetFile1 = File.fromUri(target.uri.resolve('file1.txt'));
    final targetFile2 = File.fromUri(target.uri.resolve('file2.txt'));
    final targetFile3 = File.fromUri(target.uri.resolve('file3.txt'));
    expect(await targetFile1.exists(), true);
    expect(await targetFile1.readAsString(), contents);
    expect(await targetFile2.exists(), true);
    expect(await targetFile2.readAsString(), contents);
    expect(await targetFile3.exists(), false);
  });
}
