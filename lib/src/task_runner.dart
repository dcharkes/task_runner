// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import 'task.dart';

/// The task runner provides a context for running [Task]s.
///
/// A task runner provides access to a [logger] so that tasks can write logs
/// without having to worry about where the logs go.
///
/// A task runner provices access to the [dartExecutable] so that tasks needing
/// to spawn a new dart [Process] can rely on using the right dart executable.
class TaskRunner {
  final Logger logger;
  final Uri? dartExecutable;

  TaskRunner._({
    required this.logger,
    this.dartExecutable,
  });

  factory TaskRunner({
    Logger? logger,
    Level? logLevel,
    Uri? dartExecutable,
  }) =>
      TaskRunner._(
        logger: logger ?? _defaultLogger(logLevel),
        dartExecutable: dartExecutable,
      );

  static Logger _defaultLogger(Level? logLevel) {
    hierarchicalLoggingEnabled = true;
    final logger = Logger('TaskRunner');
    if (logLevel != null) {
      logger.level = logLevel;
    }
    logger.onRecord.listen((record) {
      var message = record.message;
      if (!message.endsWith('\n')) message += '\n';
      if (record.level.value < Level.SEVERE.value) {
        stdout.write(message);
      } else {
        stderr.write(message);
      }
    });
    return logger;
  }

  /// Run a [task] within the context of this task runner.
  Future<void> run(Task task) async {
    try {
      await task.run(taskRunner: this);
    } on Exception {
      logger.severe('One or more tasks failed, check logs.');
      rethrow;
    }
  }
}
