this project is a windows app written in flutter. it uses a vendored copy of flutter to manage consistent flutter versions. to do this, the normal main flutter sdk executable `flutter` is a wrapper, `./flutterw` / `./flutterw.cmd`, just like `gradlew` for android/java. always use the wrapper rather than trying to find the sdk.

for dart commands, use `./dartw` / `./dartw.cmd` instead of a global `dart`. this keeps formatting, analysis helpers, and other dart tooling pinned to the vendored flutter sdk too.
