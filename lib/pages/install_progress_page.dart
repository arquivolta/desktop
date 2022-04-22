import 'package:arquivolta/actions.dart';
import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/widgets/page_scaffold.dart';
import 'package:arquivolta/services/job.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InProgressInstallPage extends HookWidget implements Loggable {
  const InProgressInstallPage({
    Key? key,
  }) : super(key: key);

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

    final selectedJobLogOutput = selectedIndex.value >= 0
        ? jobLogOutput.value[jobList.value[selectedIndex.value].hashCode]
        : null;

    final selectedJob =
        selectedIndex.value >= 0 ? jobList.value[selectedIndex.value] : null;

    return Flex(
      direction: Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
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
        Expanded(
          child: Flex(
            direction: Axis.vertical,
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
        )
      ],
    );
  }
}

class JobListTile extends HookWidget {
  const JobListTile({
    Key? key,
    required this.job,
    required this.onTap,
    required this.isSelected,
  }) : super(key: key);

  final JobBase job;
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

    return TappableListTile(
      key: Key(job.friendlyName),
      leading: leading,
      tileColor: isSelected ? ButtonState.all(style.accentColor) : null,
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
      onTap: onTap,
    );
  }
}

class ConsoleOutput extends StatelessWidget implements Loggable {
  const ConsoleOutput({
    Key? key,
    required this.consoleScroll,
    required this.selectedIndex,
    required this.lines,
  }) : super(key: key);

  final ScrollController consoleScroll;
  final int selectedIndex;
  final List<String>? lines;

  @override
  Widget build(BuildContext context) {
    final consoleFont = FluentTheme.of(context)
        .typography
        .body!
        .copyWith(fontFamily: 'Consolas', color: Colors.grey);

    return Container(
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