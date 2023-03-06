// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'task.dart';
import 'task_runner.dart';

/// A task for deleting a File or Directory recursively.
///
/// This task is not concurrency-safe. If executed for the same directory
/// concurrently, or concurrently for both a folder and nested folder this
/// can throw an exception.
class Delete implements Task {
  final Uri uri;

  Delete(this.uri);

  @override
  Future<void> run({TaskRunner? taskRunner}) async {
    final dir = Directory.fromUri(uri);
    if (await dir.exists()) {
      taskRunner?.logger.config('Deleting `${uri.toFilePath()}`.');
      await dir.delete(recursive: true);
    }
  }

  static Task multiple(Iterable<Uri> uris) {
    final urisOrdered = uris.toSet().toList()
      ..sort((Uri a, Uri b) => a.path.compareTo(b.path));
    return Task.parallel(urisOrdered.map((uri) => Delete(uri)));
  }
}

/// Ensures a folder exists.
///
/// This is concurrency-safe.
class EnsureExists implements Task {
  final Uri target;

  EnsureExists(this.target);

  @override
  Future<void> run({TaskRunner? taskRunner}) async {
    final targetDir = Directory.fromUri(target);
    // There might be concurrent invocations trying to create a shared parent
    // folder. So, retry a couple of times.
    var retries = 0;
    while (!await targetDir.exists()) {
      try {
        await targetDir.create(recursive: true);
      } catch (e) {
        if (retries > 3) {
          rethrow;
        }
        retries++;
      }
    }
  }
}

/// Copies a file from [source] to [target] when [run].
class Copy implements Task {
  final Uri source;
  final Uri target;

  Copy._(this.source, this.target);

  /// Copies the [source] file to [target], ensuring the parent directory
  /// exists.
  static Task single(Uri source, Uri target) => Task.serial([
        EnsureExists(File.fromUri(target).parent.uri),
        Copy._(source, target),
      ]);

  /// Copies all [files] inside [source] directory to [target] directory.
  static Task multiple(Uri source, Uri target, Iterable<String> files) {
    final filesSorted = files.toSet().toList()..sort();
    return Task.serial([
      EnsureExists(target),
      Task.serial([
        for (final file in filesSorted)
          Copy._(source.resolve(file), target.resolve(file)),
      ])
    ]);
  }

  @override
  Future<void> run({TaskRunner? taskRunner}) async {
    final file = File.fromUri(source);
    if (!await file.exists()) {
      final message =
          "File not in expected location: '${source.toFilePath()}'.";
      taskRunner?.logger.severe(message);
      throw Exception(message);
    }
    taskRunner?.logger
        .info('Copying ${source.toFilePath()} to ${target.toFilePath()}.');
    await file.copy(target.toFilePath());
  }
}
