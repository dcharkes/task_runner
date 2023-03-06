// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:task_runner/task_runner.dart';
import 'package:test/test.dart';

void main() {
  test('Task.function', () async {
    final runner = TaskRunner();
    int counter = 0;
    await runner.run(
      Task.function(({taskRunner}) async {
        counter++;
      }),
    );
    expect(counter, 1);
  });

  test('Task.serial', () async {
    final runner = TaskRunner();
    int counter = 0;
    await runner.run(
      Task.serial([
        Task.function(({taskRunner}) async {
          counter++;
        }),
        Task.function(({taskRunner}) async {
          expect(counter, 1);
        }),
        Task.function(({taskRunner}) async {
          counter++;
        }),
      ]),
    );
    expect(counter, 2);
  });

  test('Task.parallel', () async {
    final runner = TaskRunner();
    int counter = 0;
    await runner.run(
      Task.parallel([
        Task.function(({taskRunner}) async {
          counter++;
        }),
        Task.function(({taskRunner}) async {
          counter++;
        }),
      ]),
    );
    expect(counter, 2);
  });

  test('Task.async', () async {
    final runner = TaskRunner();
    int counter = 0;
    await runner.run(
      Task.async(
        () async => Task.function(({taskRunner}) async {
          counter++;
        }),
      ),
    );
    expect(counter, 1);
  });
}
