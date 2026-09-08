import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare_website/main.dart' as entry;
import 'package:oralcare_website/oralcare_website.dart';

void main() {
  testWidgets('public website communicates the pilot and safety boundary', (
    tester,
  ) async {
    await tester.pumpWidget(const OralCareWebsite());

    expect(find.text('OralCare'), findsAtLeastNWidgets(1));
    expect(find.text('Make room for an earlier conversation.'), findsOneWidget);
    expect(find.textContaining('not a cancer diagnosis'), findsOneWidget);
    expect(find.text('Explore the pilot'), findsOneWidget);
  });

  test('website entry point is available', () {
    expect(entry.main, isA<Function>());
  });
}
