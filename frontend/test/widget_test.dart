import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TaskSyncApp());

    // Verify that the title 'TaskSync' appears in the UI (e.g. Sidebar logo)
    expect(find.text('TaskSync'), findsWidgets);
  });
}
