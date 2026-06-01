import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance/main.dart';
import 'package:attendance/providers/app_state.dart';

void main() {
  testWidgets('Attendance tracker main app smoke test', (WidgetTester tester) async {
    // Setup SharedPreferences mock
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState()..init(),
        child: const AttendanceTrackerApp(),
      ),
    );

    // Initial load frame should display loader spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the async state loading settle
    await tester.pumpAndSettle();

    // After loading completes, dashboard should render
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Total Subjects'), findsOneWidget);
  });
}
