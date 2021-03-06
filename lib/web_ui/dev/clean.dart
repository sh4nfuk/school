// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import 'environment.dart';
import 'utils.dart';

class CleanCommand extends Command<bool> with ArgUtils<bool> {
  CleanCommand() {
    argParser
      ..addFlag(
        'flutter',
        defaultsTo: true,
        help: 'Cleans up the .dart_tool directory under engine/src/flutter. Enabled by default.',
      )
      ..addFlag(
        'ninja',
        defaultsTo: false,
        help: 'Also clean up the engine out directory with ninja output. Disabled by default.',
      );
  }

  @override
  String get name => 'clean';

  bool get _alsoCleanNinja => boolArg('ninja');

  bool get _alsoCleanFlutterRepo => boolArg('flutter');

  @override
  String get description => 'Deletes build caches and artifacts.';

  @override
  FutureOr<bool> run() async {
    final io.Directory assetsDir = io.Directory(path.join(
      environment.webUiRootDir.path, 'lib', 'assets'
    ));
    final Iterable<io.File> fontFiles = assetsDir
      .listSync()
      .whereType<io.File>()
      .where((io.File file) => file.path.endsWith('.ttf'));

    final List<io.FileSystemEntity> thingsToBeCleaned = <io.FileSystemEntity>[
      environment.webUiDartToolDir,
      environment.webUiBuildDir,
      io.File(path.join(environment.webUiRootDir.path, '.packages')),
      io.File(path.join(environment.webUiRootDir.path, 'pubspec.lock')),
      ...fontFiles,
      if (_alsoCleanNinja)
        environment.outDir,
      if(_alsoCleanFlutterRepo)
        environment.engineDartToolDir,
    ];

    await Future.wait(
      thingsToBeCleaned
        .where((io.FileSystemEntity entity) => entity.existsSync())
        .map((io.FileSystemEntity entity) => entity.delete(recursive: true))
    );
    return true;
  }
}
