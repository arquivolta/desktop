import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PagedViewController {
  final ValueNotifier<int> page = ValueNotifier(0);
  final int pageLimit;

  PagedViewController(this.pageLimit);

  void next() {
    page.value = min(pageLimit - 1, page.value + 1);
  }

  void prev() {
    page.value = max(0, page.value - 1);
  }
}

PagedViewController usePagedViewController(int pageCount) {
  final pageController =
      useMemoized(() => PagedViewController(pageCount), [pageCount]);

  // NB: This is a Hack, make sure that the calling widget will rebuild whenever
  // the page changes
  useValueListenable(pageController.page);

  return pageController;
}

class PagedViewWidget extends HookWidget {
  final PagedViewController controller;
  final Widget Function(BuildContext ctx, PagedViewController controller)
      builder;

  const PagedViewWidget(this.controller, this.builder, {super.key});

  @override
  Widget build(BuildContext context) {
    return builder(context, controller);
  }
}
