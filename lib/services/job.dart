import 'dart:async';

import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

enum JobStatus {
  idle,
  running,
  success,
  error,
}

abstract class JobBase<T> extends CustomLoggable implements Loggable {
  late final Stream<List<String>> logOutput;
  late final Logger _logger;

  final String friendlyName;
  final String friendlyDescription;
  final ValueNotifier<JobStatus> jobStatus =
      ValueNotifier<JobStatus>(JobStatus.idle);

  @override
  Logger get logger => _logger;

  JobBase(this.friendlyName, this.friendlyDescription) {
    final so = StreamOutput();
    logOutput = so.stream;

    _logger = Logger(
      filter: ProductionFilter(),
      output: so,
      printer: ZeroAnnotationPrinter(),
      level: App.find<ApplicationMode>() == ApplicationMode.production
          ? Level.info
          : Level.debug,
    );

    App.find<PublishSubject<JobBase<dynamic>>>(instanceName: 'jobSubject')
        .add(this);
  }

  static GetIt setupRegistration(GetIt locator) {
    locator.registerSingleton(
      PublishSubject<JobBase<dynamic>>(),
      instanceName: 'jobSubject',
    );

    return locator;
  }

  static Stream<JobBase<dynamic>> get jobStream =>
      App.find<PublishSubject<JobBase<dynamic>>>(instanceName: 'jobSubject')
          .stream;

  Future<T> execute();

  static JobBase<T> fromBlock<T>(
    String friendlyName,
    String friendlyDescription,
    Future<T> Function(JobBase<T> job) block,
  ) {
    return FuncJob<T>(friendlyName, friendlyDescription, block);
  }
}

class FuncJob<T> extends JobBase<T> {
  final Future<T> Function(JobBase<T> job) block;

  FuncJob(String friendlyName, String friendlyDescription, this.block)
      : super(
          friendlyName,
          friendlyDescription,
        );

  @override
  Future<T> execute() {
    jobStatus.value = JobStatus.running;

    try {
      final ret = block(this);

      jobStatus.value = JobStatus.success;
      return ret;
    } catch (ex, st) {
      e('Failed to run job $friendlyName', ex, st);
      jobStatus.value = JobStatus.error;
      rethrow;
    }
  }
}

class ZeroAnnotationPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final errorStr = event.error != null ? '  ERROR: ${event.error}' : '';
    return ['${event.message}$errorStr'];
  }
}
