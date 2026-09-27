import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/core/widgets/photo_preview.dart';
import 'package:smart_bill_manager/features/auth/presentation/state/auth_providers.dart';
import 'package:smart_bill_manager/features/profile/presentation/view/profile_screen.dart';
import 'package:smart_bill_manager/features/users/domain/entities/app_user.dart';

void main() {
  AppUser user({String? photo}) => AppUser(
        id: 'u1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        fullName: 'Aarati Sharma',
        email: 'aarati@example.com',
        displayName: 'Aarati',
        profilePicture: photo,
      );

  Widget wrap(AppUser u) {
    return ProviderScope(
      overrides: [
        currentAppUserProvider.overrideWith((ref) async => u),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ProfileScreen()),
      ),
    );
  }

  // Uses fixed-duration pumps instead of `pumpAndSettle`: the entrance
  // animation and the preview's loading spinner never settle on their own.
  Future<void> settleProfile(WidgetTester tester) async {
    await tester.pump(); // resolve the user future
    await tester.pump(const Duration(milliseconds: 100)); // start entrance
    await tester.pump(const Duration(milliseconds: 800)); // finish entrance
  }

  Future<void> openPreview(WidgetTester tester) async {
    await tester.tap(find.byType(Hero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('tapping the avatar opens the photo preview', (tester) async {
    await tester.pumpWidget(wrap(user(photo: 'https://example.com/a.png')));
    await settleProfile(tester);

    expect(find.byType(Hero), findsOneWidget);

    await openPreview(tester);

    expect(find.byType(PhotoPreviewScreen), findsOneWidget);
  });

  testWidgets('the avatar exposes a "view photo" semantics button',
      (tester) async {
    await tester.pumpWidget(wrap(user(photo: 'https://example.com/a.png')));
    await settleProfile(tester);

    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'View profile photo',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the preview can be dismissed with the close button',
      (tester) async {
    await tester.pumpWidget(wrap(user(photo: 'https://example.com/a.png')));
    await settleProfile(tester);

    await openPreview(tester);
    expect(find.byType(PhotoPreviewScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PhotoPreviewScreen), findsNothing);
  });

  testWidgets('the preview can be dismissed by tapping the backdrop',
      (tester) async {
    await tester.pumpWidget(wrap(user(photo: 'https://example.com/a.png')));
    await settleProfile(tester);

    await openPreview(tester);
    expect(find.byType(PhotoPreviewScreen), findsOneWidget);

    await tester.tapAt(const Offset(20, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PhotoPreviewScreen), findsNothing);
  });

  testWidgets('the avatar without a photo opens the preview with initials',
      (tester) async {
    await tester.pumpWidget(wrap(user()));
    await settleProfile(tester);

    // No photo → no Hero is registered for a flight.
    expect(find.byType(Hero), findsNothing);
    expect(find.text('AS'), findsOneWidget);

    await tester.tap(find.text('AS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PhotoPreviewScreen), findsOneWidget);
    // The avatar initials plus the preview card's initials.
    expect(find.text('AS'), findsNWidgets(2));
  });

  testWidgets('the preview shows a fallback when the photo fails to load',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PhotoPreviewScreen(
          imageUrl: 'https://example.com/missing.png',
          initials: 'AS',
          heroTag: 'test-hero',
        ),
      ),
    );
    // Let the (mocked) network request fail and the error state render.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Unable to load photo'), findsOneWidget);
  });

  testWidgets('the preview renders initials when there is no photo',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PhotoPreviewScreen(initials: 'AS')),
    );
    await tester.pump();

    expect(find.text('AS'), findsOneWidget);
  });
}
