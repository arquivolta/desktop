import 'dart:async';

import 'package:arquivolta/app.dart';
import 'package:arquivolta/services/job.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/subjects.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  /*
   * JobBase Tests
   */
  test('executeInferior should scale percents', () {
    return setupForTest(
      block: () async {
        final inferiorJob = JobBase.fromBlock('', '', (progress, job) async {
          progress.add(10);

          await Future<void>.delayed(const Duration(milliseconds: 100));
          progress.add(50);

          await Future<void>.delayed(const Duration(milliseconds: 100));
          progress.add(40);

          return true;
        });

        final job = JobBase.fromBlock('', '', (progress, job) async {
          progress.add(10);

          await JobBase.executeInferiorJob(inferiorJob, progress, 50);

          progress.add(40);
        });

        final progress = BehaviorSubject<double>.seeded(0)
          ..listen((value) => App.find<Logger>().i('Progress: $value'));

        await JobBase.executeTopLevelJob(job, progress.sink);

        // NB: Streams don't synchronously execute even when they probably
        // should - despite our event being finished, the stream is still
        // pumping our progress events through the task queue. This sucks, I
        // want Rx back.
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(progress.value, equals(100));
      },
    );
  });
}
