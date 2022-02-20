import 'dart:async';

import 'package:arquivolta/actions.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

class FutureWidget extends HookWidget {
  final Future<String> Function() future;
  final String? dep;
  const FutureWidget({Key? key, this.dep, required this.future})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = useFutureEffect(future, dep != null ? [dep] : []);
    if (p.connectionState == ConnectionState.waiting) {
      return const Text('Pending!');
    }

    if (p.hasError) {
      return Text('Error! ${p.error}');
    }

    return Text(p.data!);
  }
}

class ActionWidget extends HookWidget {
  final Future<String> Function() future;
  final String? dep;
  const ActionWidget({Key? key, this.dep, required this.future})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ar = useAction(future, dep != null ? [dep] : []);

    var content = Text(ar.result.data ?? '(null)');

    if (ar.result.connectionState == ConnectionState.waiting) {
      content = const Text('Pending!');
    }

    if (ar.result.hasError) {
      content = Text('Error! ${ar.result.error}');
    }

    return Flex(
      direction: Axis.horizontal,
      children: [
        TextButton(
          onPressed: ar.invoke,
          key: const Key('invoke'),
          child: const Text('button'),
        ),
        TextButton(
          onPressed: ar.reset,
          key: const Key('reset'),
          child: const Text('button2'),
        ),
        content,
      ],
    );
  }
}

Future<T> firstNoCancel<T>(Stream<T> stream) {
  final completer = Completer<T>();
  var hasValue = false;

  stream.take(1).listen(
        (e) {
          completer.complete(e);
          hasValue = true;
        },
        onError: completer.completeError,
        onDone: () {
          if (!hasValue) {
            completer.completeError('done');
          }
        },
      );

  return completer.future;
}

void main() {
  /*
   * useFutureEffect
   */

  testWidgets('useFutureEffect smoke test', (tester) async {
    final inp = StreamController<String>(sync: true);
    final widget = WidgetsApp(
      builder: (context, child) => FutureWidget(future: () => inp.stream.first),
      color: const Color.fromARGB(0, 0, 0, 0),
    );

    await tester.pumpWidget(widget);
    expect(find.text('Pending!'), findsOneWidget);

    inp.add('Hello');
    await tester.pumpWidget(widget);
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('useFutureEffect error', (tester) async {
    final inp = StreamController<String>(sync: true);
    final widget = WidgetsApp(
      builder: (context, child) => FutureWidget(future: () => inp.stream.first),
      color: const Color.fromARGB(0, 0, 0, 0),
    );

    await tester.pumpWidget(widget);
    expect(find.text('Pending!'), findsOneWidget);

    inp.addError(Exception('Dead!'));
    await tester.pumpWidget(widget);

    expect(find.text('Error! Exception: Dead!'), findsOneWidget);
  });

  testWidgets('useFutureEffect should refresh on deps change', (tester) async {
    final box = ['First'];

    // ignore: prefer_function_declarations_over_variables
    final widgeter = (String dep) => FluentApp(
          builder: (context, child) =>
              FutureWidget(future: () => Future.value(box[0]), dep: dep),
          color: const Color.fromARGB(0, 0, 0, 0),
        );

    await tester.pumpWidget(widgeter('foo'));
    expect(find.text('Pending!'), findsOneWidget);

    await tester.pumpWidget(widgeter('foo'));
    expect(find.text('First'), findsOneWidget);

    // We should *not* update here - we have not changed deps, so we should
    // expect that we're still listening to the previous Future
    box[0] = 'Second';
    await tester.pumpWidget(widgeter('foo'));
    expect(find.text('First'), findsOneWidget);

    // Changing deps should cause a refresh
    await tester.pumpWidget(widgeter('bar'));
    expect(find.text('Second'), findsOneWidget);
  });

  /*
   * useAction
   */

  testWidgets('useAction smoke test', (tester) async {
    final box = ['First'];

    // ignore: prefer_function_declarations_over_variables
    final widgeter = (String dep) => FluentApp(
          builder: (context, child) =>
              ActionWidget(future: () => Future.value(box[0]), dep: dep),
          color: Colors.grey,
        );

    await tester.pumpWidget(widgeter('foo'));
    expect(find.text('Pending!'), findsOneWidget);

    await tester.tap(find.byKey(const Key('invoke')));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reset')));
    await tester.pumpAndSettle();
    expect(find.text('Pending!'), findsOneWidget);

    box[0] = 'Second';
    await tester.tap(find.byKey(const Key('invoke')));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('useAction should ignore dupes', (tester) async {
    var callCount = 0;
    final gate = [StreamController<String>()];

    // ignore: prefer_function_declarations_over_variables
    final widgeter = (String dep) => FluentApp(
          builder: (context, child) => ActionWidget(
            future: () async {
              callCount++;
              await gate[0].stream.first;
              return callCount.toString();
            },
            dep: dep,
          ),
          color: Colors.grey,
        );

    await tester.pumpWidget(widgeter('foo'));

    await tester.tap(find.byKey(const Key('invoke')));
    await tester.pumpAndSettle();
    expect(callCount, 1);
    expect(find.text('Pending!'), findsOneWidget);

    await tester.tap(find.byKey(const Key('invoke')));
    await tester.pumpAndSettle();
    expect(callCount, 1);
    expect(find.text('Pending!'), findsOneWidget);

    gate[0].add('bar');
    await tester.pumpWidget(widgeter('foo'));
    expect(find.text('1'), findsOneWidget);

    gate[0] = StreamController<String>();
    await tester.tap(find.byKey(const Key('invoke')));
    await tester.pumpAndSettle();
    expect(callCount, 2);
    expect(find.text('1'), findsOneWidget);

    gate[0].add('bar');
    await tester.pumpWidget(widgeter('foo'));
    expect(callCount, 2);
    expect(find.text('2'), findsOneWidget);
  });
}
