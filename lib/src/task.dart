// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'task_runner.dart';

/// A task that can be [run].
///
/// Tasks are usually run in the context of a [TaskRunner].
abstract class Task {
  /// Runs this task.
  Future<void> run({TaskRunner? taskRunner});

  /// Runs [tasks] in parallel.
  // TODO(dacoharkes): Add a maximum concurrency to the task runner.
  factory Task.parallel(Iterable<Task> tasks) => _ParallelTask(tasks);

  /// Runs [tasks] in sequence.
  factory Task.serial(Iterable<Task> tasks) => _SerialTask(tasks);

  /// Evaluates an async function that results in a task that can be run, then
  /// runs the task.
  ///
  /// Useful for when construction of a task itself is async.
  factory Task.async(Future<Task> Function() f) => _FutureTask(Future(f));

  /// Evaluates a function.
  factory Task.function(Future<void> Function({TaskRunner? taskRunner}) f) =>
      _FunctionTask(f);
}

class _ParallelTask implements Task {
  final Iterable<Task> tasks;

  _ParallelTask(this.tasks);

  @override
  Future<void> run({TaskRunner? taskRunner}) =>
      Future.wait(tasks.map((e) => e.run(taskRunner: taskRunner)));
}

class _SerialTask implements Task {
  final Iterable<Task> tasks;

  _SerialTask(this.tasks);

  @override
  Future<void> run({TaskRunner? taskRunner}) async {
    for (final task in tasks) {
      await task.run(taskRunner: taskRunner);
    }
  }
}

class _FutureTask implements Task {
  final Future<Task> future;

  _FutureTask(this.future);

  @override
  Future<void> run({TaskRunner? taskRunner}) async =>
      (await future).run(taskRunner: taskRunner);
}

class _FunctionTask implements Task {
  final Future<void> Function({TaskRunner? taskRunner}) f;

  _FunctionTask(this.f);

  @override
  Future<void> run({TaskRunner? taskRunner}) => f(taskRunner: taskRunner);
}
