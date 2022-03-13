import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/services/job.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';
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

String getLocalAppDataPath() {
  final appsFolder = win32.GUIDFromString(win32.FOLDERID_LocalAppData);
  final ppszPath = calloc<win32.PWSTR>();

  try {
    final hr = win32.SHGetKnownFolderPath(
      appsFolder,
      win32.KF_FLAG_DEFAULT,
      win32.NULL,
      ppszPath,
    );

    if (win32.FAILED(hr)) {
      throw win32.WindowsException(hr);
    }

    final path = ppszPath.value.toDartString();
    return path;
  } finally {
    win32.free(appsFolder);
    win32.free(ppszPath);
  }
}

Future<void> downloadUrlToFile(
  Uri url,
  String target,
  StreamSink<double> progress,
) async {
  final client = HttpClient();
  final rq = await client.getUrl(url);
  final resp = await rq.close();
  final bytes = PublishSubject<int>();

  bytes.stream
      .scan<double>((acc, x, _) => acc + (x / resp.contentLength * 100), 0)
      .listen(progress.add);

  await resp
      .doOnData((buf) => bytes.add(buf.length))
      .pipe(File(target).openWrite());
}

JobBase<void> downloadUrlToFileJob(
  String friendlyName,
  Uri uri,
  String target,
) {
  return JobBase.fromBlock<void>(
    friendlyName,
    'Downloading ${uri.toString()} to $target',
    (job) async {
      final progressSubj = PublishSubject<double>();
      job.i(job.friendlyDescription);

      progressSubj
          .sampleTime(const Duration(seconds: 2))
          .listen((x) => job.i('Progress: ${x.toStringAsFixed(2)}%'));

      try {
        await downloadUrlToFile(uri, target, progressSubj.sink);
      } catch (ex, st) {
        job.e('Failed to download file', ex, st);
        rethrow;
      }
    },
  );
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

extension ProcessOutputMixin on ProcessResult {
  ProcessOutput toProcessOutput() {
    return ProcessOutput(
      pid,
      exitCode,
      stdout,
      stderr,
    );
  }
}
