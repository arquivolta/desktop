import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tar/tar.dart';

/// Converts an Arch Linux image downloaded from the web into a format that
/// wsl --import can handle
///
/// Arch Linux bootstrap images can nearly be imported directly into WSL2 via
/// its --import command, except that:
///
/// * The Tarball is compressed, and WSL2 wants them uncompressed
/// * Arch prepends a useless ``` root.ARCH`  folder at the root.
///
/// So, decompress the image, and remove the folder in-line. We do this directly
/// in Dart rather than shelling out, because if we try to unzip it and re-zip
/// it on Windows, we will corrupt the permissions
Future<void> convertArchBootstrapToWSLRootFs(
  String archImage,
  String targetRootfsFile,
) async {
  final inputStream = File(archImage).openRead().transform(gzip.decoder);

  await _getTarEntryStream(inputStream)
      .transform(tarWriter)
      .pipe(File(targetRootfsFile).openWrite());

  debugPrint('We Did It!');
}

Stream<TarEntry> _getTarEntryStream(Stream<List<int>> inputFile) async* {
  final reader = TarReader(inputFile);

  final initialFolder = RegExp(r'^root\.(x86_64|aarch64)\/');
  while (await reader.moveNext()) {
    final h = reader.current.header;
    final header = TarHeader(
      name: h.name.replaceFirst(initialFolder, ''),
      format: h.format,
      typeFlag: h.typeFlag,
      modified: h.modified,
      linkName: h.linkName,
      mode: h.mode,
      size: h.size,
      userId: h.userId,
      groupId: h.groupId,
      accessed: h.accessed,
      changed: h.changed,
      devMajor: h.devMajor,
      devMinor: h.devMinor,
    );

    final buffers = await reader.current.contents.toList();
    yield TarEntry(header, Stream.fromIterable(buffers));
  }
}
