import 'dart:async';

import 'package:arquivolta/app.dart';
import 'package:arquivolta/logging.dart';
import 'package:logger/logger.dart';

abstract class JobBase extends CustomLoggable with LoggableMixin {
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

  Future<void> execute(StreamSink<int> progress);

  Future<void> executeInSequence(
    List<JobBase> jobs,
    StreamSink<int> progress, [
    int totalPercentage = 100,
  ]) async {
    final scale = totalPercentage / 100.0 / jobs.length;

    for (final job in jobs) {
      final progressController = StreamController<int>();

      progressController.stream
          .map((x) => x * scale)
          .listen((x) => progress.add(x.toInt()));

      await job.execute(progressController.sink);
      await progressController.close();
    }
  }
}
