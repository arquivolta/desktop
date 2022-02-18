import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart';
import 'package:win32/win32.dart' as win32;

enum OperatingSystemType { amd64, aarch64, dunnoButItsNotGonnaWork }

final RegExp _devModePath = RegExp('runner.Debug');
bool isDevMode() {
  return _devModePath.hasMatch(Platform.resolvedExecutable);
}

String rootAppDir() {
  if (isDevMode()) {
    // C:\Users\ani\code\arquivolta\desktop\build\windows\runner\Debug\desktop.exe
    return absolute(
      dirname(Platform.resolvedExecutable),
      '..',
      '..',
      '..',
      '..',
    );
  } else {
    return dirname(Platform.resolvedExecutable);
  }
}

OperatingSystemType getOSArchitecture() {
  final sysInfo = calloc<win32.SYSTEM_INFO>();
  win32.GetSystemInfo(sysInfo);

  if (sysInfo.ref.wProcessorArchitecture ==
      win32.PROCESSOR_ARCHITECTURE_AMD64) {
    return OperatingSystemType.amd64;
  }

  if (sysInfo.ref.wProcessorArchitecture ==
      win32.PROCESSOR_ARCHITECTURE_ARM64) {
    return OperatingSystemType.aarch64;
  }

  return OperatingSystemType.dunnoButItsNotGonnaWork;
}

extension ThrowOnProcessErrorExtension on Future<ProcessResult> {
  Future<void> throwOnError([String? message]) async {
    final pr = await this;
    if (pr.exitCode == 0) {
      return;
    }

    throw Exception(
      '${message ?? 'Process exited with code ${pr.exitCode}'}:\n'
      '${pr.stdout}\n'
      '${pr.stderr}',
    );
  }
}
