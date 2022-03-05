import 'dart:async';

import 'package:arquivolta/app.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/services/util.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

abstract class JobBase<T> extends CustomLoggable implements Loggable {
  late final Stream logOutput;
  late final Logger _logger;

  final String friendlyName;
  final String friendlyDescription;

  @override
  Logger get logger => _logger;

  JobBase(this.friendlyName, this.friendlyDescription) {
    final so = StreamOutput();
    logOutput = so.stream;

    _logger = Logger(
      output: so,
      level: App.find<ApplicationMode>() == ApplicationMode.production
          ? Level.info
          : Level.debug,
    );
  }

  Future<T> execute(StreamSink<double> progress);

  static Future<TRet> executeTopLevelJob<TRet>(
    JobBase<TRet> job,
    StreamSink<double> totalProgress,
  ) {
    final subj = PublishSubject<double>();
    subj
        .scan<double>((acc, x, _) => acc + x, 0)
        .sampleTime(const Duration(milliseconds: 250))
        .map<double>((x) {
      if (x > 100 || x < 0) {
        job.wtf('Progress is out of bounds! $x');
      }

      return x.clamp(0, 100);
    }).listen(totalProgress.add);

    return job.execute(subj);
  }

  static Future<TRet> executeInferiorJob<TRet>(
    JobBase<TRet> job,
    StreamSink<double> progress,
    int range,
  ) {
    final scale = range / 100.0;
    final scaledProgress = PublishSubject<double>();

    scaledProgress.map((x) => x * scale).listen(progress.add);
    return job.execute(scaledProgress.sink);
  }

  static Future<void> executeInSequence(
    List<JobBase<dynamic>> jobs,
    StreamSink<double> progress, [
    int totalPercentage = 100,
  ]) async {
    final scale = totalPercentage / 100.0 / jobs.length;

    for (final job in jobs) {
      final progressController = StreamController<double>();

      progressController.stream.map((x) => x * scale).listen(progress.add);

      await job.execute(progressController.sink);
    }
  }

  static JobBase<T> fromBlock<T>(
    String friendlyName,
    String friendlyDescription,
    Future<T> Function(StreamSink<double> progress, JobBase<T> job) block,
  ) {
    return FuncJob<T>(friendlyName, friendlyDescription, block);
  }
}

class FuncJob<T> extends JobBase<T> {
  final Future<T> Function(StreamSink<double> progress, JobBase<T> job) block;

  FuncJob(String friendlyName, String friendlyDescription, this.block)
      : super(
          friendlyName,
          friendlyDescription,
        );

  @override
  Future<T> execute(StreamSink<double> progress) {
    return block(progress, this);
  }
}

JobBase<void> downloadUrlToFileJob(
  String friendlyName,
  Uri uri,
  String target,
) {
  return JobBase.fromBlock<void>(
    friendlyName,
    'Downloading ${uri.toString()} to $target',
    (progress, job) async {
      job.i(job.friendlyDescription);

      try {
        await downloadUrlToFile(uri, target, progress);
      } catch (ex, st) {
        job.e('Failed to download file', ex, st);
        rethrow;
      }
    },
  );
}
