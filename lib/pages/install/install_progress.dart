import 'package:arquivolta/logging.dart';
import 'package:arquivolta/services/job.dart';
import 'package:arquivolta/util.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InProgressInstall extends HookWidget implements Loggable {
  final bool finished;
  final VoidCallback onPressedFinish;
  final Object? error;

  const InProgressInstall({
    required this.finished,
    required this.onPressedFinish,
    this.error,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final style = FluentTheme.of(context);
    final jobList = useState(<JobBase<dynamic>>[]);
    final selectedIndex = useState(-1);
    final jobLogOutput = useRef(<int, List<String>>{});
    final redraw = useState(0);
    final listScroll = useScrollController();
    final consoleScroll = useRef(<int, ScrollController>{});

    useEffect(
      () {
        consoleScroll.value[-1] = ScrollController();

        final sub = JobBase.jobStream.listen((job) {
          jobList.value = [...jobList.value, job];
          final idx = jobList.value.length - 1;
          consoleScroll.value[idx] = ScrollController();

          job.logOutput.listen((lines) {
            jobLogOutput.value[job.hashCode] ??= [];
            jobLogOutput.value[job.hashCode]!.addAll(lines);

            if (selectedIndex.value == idx) {
              redraw.value++;
            }
          });
        });

        return sub.cancel;
      },
      [],
    );

    useEffect(
      () {
        // ignore: avoid_function_literals_in_foreach_calls
        return () => consoleScroll.value.values.forEach((sc) => sc.dispose());
      },
      [],
    );

    useEffect(
      () {
        if (jobList.value.isNotEmpty && selectedIndex.value == -1) {
          selectedIndex.value = 0;
        }

        return null;
      },
      [jobList.value.length, selectedIndex.value],
    );

    final selectedJobLogOutput = selectedIndex.value >= 0
        ? jobLogOutput.value[jobList.value[selectedIndex.value].hashCode]
        : null;

    final selectedJob =
        selectedIndex.value >= 0 ? jobList.value[selectedIndex.value] : null;

    final jobListWidget = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Card(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: 350,
              height: 200,
              child: ListView.builder(
                itemCount: jobList.value.length,
                controller: listScroll,
                itemBuilder: (ctx, i) => JobListTile(
                  job: jobList.value[i],
                  isSelected: selectedIndex.value == i,
                  onTap: () => selectedIndex.value = i,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedJob?.friendlyName ?? '',
                style: style.typography.bodyStrong,
              ),
              Flexible(
                flex: 0,
                fit: FlexFit.tight,
                child: Text(
                  selectedJob?.friendlyDescription ?? '',
                  style: style.typography.body,
                ),
              ),
              Expanded(
                child: ConsoleOutput(
                  consoleScroll: consoleScroll.value[selectedIndex.value]!,
                  selectedIndex: selectedIndex.value,
                  lines: selectedJobLogOutput,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: jobListWidget),
        if (error == null)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton(
                onPressed: finished ? onPressedFinish : null,
                child: const Text('Finish'),
              ),
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                // XXX Fix Me
                Expanded(
                  child: Text(
                    'Failed to install: $error',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                  child: const FilledButton(
                    onPressed: openLogFileInDefaultEditor,
                    child: Text('Open Log File'),
                  ),
                )
              ],
            ),
          )
      ],
    );
  }
}

class JobListTile extends HookWidget {
  const JobListTile({
    required this.job,
    required this.onTap,
    required this.isSelected,
    super.key,
  });

  final JobBase<dynamic> job;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final style = FluentTheme.of(context);
    final jobStatus = useValueListenable(job.jobStatus);

    const double s = 16;
    Widget? leading = SizedBox(width: s, height: s, child: Container());

    if (jobStatus == JobStatus.running) {
      leading = const SizedBox(width: s, height: s, child: ProgressRing());
    }
    if (jobStatus == JobStatus.error) {
      leading = const Icon(FluentIcons.error_badge, size: s);
    }
    if (jobStatus == JobStatus.success) {
      leading = const Icon(FluentIcons.check_mark, size: s);
    }

    return ListTile(
      key: Key(job.friendlyName),
      leading: leading,
      tileColor: isSelected ? ButtonState.all(style.menuColor) : null,
      title: Text(
        job.friendlyName,
        style: style.typography.bodyStrong,
        maxLines: 1,
        overflow: TextOverflow.fade,
      ),
      subtitle: Text(
        job.friendlyDescription,
        style: style.typography.body,
        maxLines: 1,
        overflow: TextOverflow.fade,
      ),
      onPressed: onTap,
    );
  }
}

class ConsoleOutput extends StatelessWidget implements Loggable {
  const ConsoleOutput({
    required this.consoleScroll,
    required this.selectedIndex,
    required this.lines,
    super.key,
  });

  final ScrollController consoleScroll;
  final int selectedIndex;
  final List<String>? lines;

  @override
  Widget build(BuildContext context) {
    final consoleFont = FluentTheme.of(context)
        .typography
        .body!
        .copyWith(fontFamily: 'Consolas', color: Colors.grey);

    return ColoredBox(
      color: Colors.grey[40],
      child: ListView.builder(
        controller: consoleScroll,
        itemCount: lines?.length ?? 0,
        itemBuilder: (ctx, i) {
          return Text(
            lines![i],
            style: consoleFont,
          );
        },
      ),
    );
  }
}
