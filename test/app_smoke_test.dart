import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/features/auth/role_select_screen.dart';

/// Boots the entry screen to force compilation of the widget tree and confirm
/// it renders without throwing. The risk engine has its own focused unit suite.
void main() {
  testWidgets('role selection renders both interfaces', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoleSelectScreen()));

    expect(find.text('OralCare'), findsOneWidget);
    expect(find.text('Patient login'), findsOneWidget);
    expect(find.text('Doctor login'), findsOneWidget);
    // The no-diagnosis safety notice must always be present on entry.
    expect(find.textContaining('does not diagnose cancer'), findsOneWidget);
  });
}
