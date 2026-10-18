import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receiptocr/screens/review_screen.dart';

void main() {
  testWidgets('Test clicking date picker opens DatePicker dialog', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('vi', 'VN'),
            Locale('en', 'US'),
          ],
          locale: Locale('vi', 'VN'),
          home: ReviewScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the date picker box and tap it
    final calendarIcon = find.byIcon(Icons.calendar_month_outlined);
    expect(calendarIcon, findsOneWidget);

    await tester.tap(calendarIcon);
    await tester.pumpAndSettle();

    // Verify date picker dialog is shown
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Tap OK or cancel to close dialog
    final okButton = find.text('OK');
    expect(okButton, findsOneWidget);
    await tester.tap(okButton);
    await tester.pumpAndSettle();

    // Verify dialog is closed
    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('Test clicking "Ngày giao dịch" text opens DatePicker dialog', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('vi', 'VN'),
            Locale('en', 'US'),
          ],
          locale: Locale('vi', 'VN'),
          home: ReviewScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the label "Ngày giao dịch" and tap it
    final labelText = find.text('Ngày giao dịch');
    expect(labelText, findsOneWidget);

    await tester.tap(labelText);
    await tester.pumpAndSettle();

    // Verify date picker dialog is shown
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
