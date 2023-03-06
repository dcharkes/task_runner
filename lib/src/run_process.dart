// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'task.dart';
import 'task_runner.dart';

/// A task that when run executes a process.
///
/// When Running the process, and streams the stdout and stderr to the
/// [TaskRunner.logger]. This task does not provide programmatic access to
/// stdout and stderr.
///
/// If [throwOnFailure], throws an [Exception] if the exitCode is non-zero.
///
/// If [executable] equals 'dart', tries to use [TaskRunner.dartExecutable].
class RunProcess implements Task {
  final String executable;
  final List<String> arguments;
  final Uri? workingDirectory;
  final Map<String, String>? environment;
  final bool includeParentEnvironment;
  final bool throwOnFailure;

  RunProcess({
    required this.executable,
    this.arguments = const [],
    this.workingDirectory,
    this.environment,
    this.includeParentEnvironment = true,
    this.throwOnFailure = true,
  });

  /// Prefers running executables in x64 mode on MacOS arm64 machines.
  ///
  /// This can be used to avoid "... is implemented in both ..." error messages.
  static Task useRosetta({
    required String executable,
    required List<String> arguments,
    Uri? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool throwOnFailure = true,
  }) {
    if (Abi.current() == Abi.macosArm64) {
      return Task.async(() async {
        final executableUri = Uri.file(
            ((await Process.run('which', [executable])).stdout as String)
                .trim());
        final fileStdout =
            ((await Process.run('file', [executableUri.toFilePath()])).stdout
                as String);
        final containsX64 = fileStdout.contains('executable x86_64');
        if (containsX64) {
          return RunProcess(
            executable: 'arch',
            arguments: [
              '-x86_64',
              executable,
              ...arguments,
            ],
            workingDirectory: workingDirectory,
            environment: environment,
            includeParentEnvironment: includeParentEnvironment,
            throwOnFailure: throwOnFailure,
          );
        }
        return RunProcess(
          executable: executable,
          arguments: arguments,
          workingDirectory: workingDirectory,
          environment: environment,
          includeParentEnvironment: includeParentEnvironment,
          throwOnFailure: throwOnFailure,
        );
      });
    }
    return RunProcess(
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      throwOnFailure: throwOnFailure,
    );
  }

  String get commandString {
    final printWorkingDir =
        workingDirectory != null && workingDirectory != Directory.current.uri;
    return [
      if (printWorkingDir) '(cd ${workingDirectory!.path};',
      ...?environment?.entries.map((entry) => '${entry.key}=${entry.value}'),
      executable,
      ...arguments.map((a) => a.contains(' ') ? "'$a'" : a),
      if (printWorkingDir) ')',
    ].join(' ');
  }

  @override
  Future<void> run({TaskRunner? taskRunner}) async {
    final workingDirectoryString = workingDirectory?.toFilePath();

    taskRunner?.logger.info('Running `$commandString`.');
    final executable2 = executable == 'dart'
        ? taskRunner?.dartExecutable?.toFilePath() ?? executable
        : executable;
    final process = await Process.start(
      executable2,
      arguments,
      runInShell: true,
      workingDirectory: workingDirectoryString,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
    ).then((process) {
      process.stdout
          .transform(utf8.decoder)
          .forEach((s) => taskRunner?.logger.fine('  $s'));
      process.stderr
          .transform(utf8.decoder)
          .forEach((s) => taskRunner?.logger.severe('  $s'));
      return process;
    });
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final message =
          'Command `$commandString` failed with exit code $exitCode.';
      taskRunner?.logger.severe(message);
      if (throwOnFailure) {
        throw Exception(message);
      }
    }
    taskRunner?.logger.fine('Command `$commandString` done.');
  }
}
