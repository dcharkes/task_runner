// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';

import 'task.dart';
import 'task_runner.dart';

/// A task printing a log message.
class Log implements Task {
  final Level logLevel;
  final String message;

  Log.info(this.message) : logLevel = Level.INFO;

  @override
  Future<void> run({TaskRunner? taskRunner}) async =>
      taskRunner?.logger.log(logLevel, message);
}
