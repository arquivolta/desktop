import 'dart:ffi';
import 'dart:io';

import 'package:arquivolta/interfaces.dart';
import 'package:dcache/dcache.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;

enum OperatingSystemType { amd64, aarch64, dunnoButItsNotGonnaWork }

OperatingSystemType getOSArchitecture() {
  final sysInfo = calloc<win32.SYSTEM_INFO>();
  try {
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
  } finally {
    calloc.free(sysInfo);
  }
}

void openFileViaShell(String path) {
  using((arena) {
    final lpPath = path.toNativeUtf16(allocator: arena);

    win32.ShellExecute(
      null,
      null,
      win32.PCWSTR(lpPath),
      null,
      null,
      win32.SW_SHOW,
    );
  });
}

void openAppXByModelId(String appModelId) {
  final aam = win32.createInstance<win32.IApplicationActivationManager>(
    win32.ApplicationActivationManager,
  );

  try {
    using((arena) {
      aam.activateApplication(
        win32.PCWSTR('$appModelId!App'.toNativeUtf16(allocator: arena)),
        win32.PCWSTR(''.toNativeUtf16(allocator: arena)),
        win32.AO_NONE,
      );
    });
  } finally {
    aam.release();
  }
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

String getLocalAppDataPath() => getKnownFolder(win32.FOLDERID_LocalAppData);
String getHomeDirectory() => getKnownFolder(win32.FOLDERID_Profile);
String getUsername() => getHomeDirectory().split(r'\').last;

final _kfCache = SimpleCache<String, String>(storage: InMemoryStorage(32))
  ..loader = (key, oldValue) => _getKnownFolder(key);

String getKnownFolder(win32.GUID folderId) =>
    _kfCache.get(folderId.toString())!;

String _getKnownFolder(String folderId) {
  final knownFolderId = win32.GUID(folderId);

  return using((arena) {
    final path = win32.SHGetKnownFolderPath(
      knownFolderId.toNative(allocator: arena),
      win32.KF_FLAG_DEFAULT,
      null,
    );

    try {
      return path.toDartString();
    } finally {
      win32.CoTaskMemFree(path);
    }
  });
}

final re = RegExp('[a-zA-Z0-9,._+:@%/-]');
String escapeStringForBash(String str) {
  final ret = StringBuffer();

  // NB: Yes I know this is incredibly inefficient
  for (int i = 0; i < str.length; i++) {
    if (re.hasMatch(str[i])) {
      ret.write(str[i]);
    } else {
      ret.write('\\${str[i]}');
    }
  }

  return ret.toString();
}

String win32PathToWslPath(String path) {
  final driveLetter = path[0].toLowerCase();
  final rest = path.substring(2).replaceAll(r'\', '/');

  return '/mnt/$driveLetter$rest';
}

ProcessOutput processResultToOutput(ProcessResult pr) {
  final ret = ProcessOutput(
    pr.pid,
    pr.exitCode,
    pr.stdout,
    pr.stderr,
  );

  return ret;
}
