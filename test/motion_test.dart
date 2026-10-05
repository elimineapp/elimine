import 'package:elimine/app/motion/container_transform.dart';
import 'package:elimine/app/motion/motion.dart';
import 'package:elimine/app/motion/shared_axis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('motion tokens', () {
    test('every duration finishes within 500 ms', () {
      for (final d in [Motion.short, Motion.medium, Motion.long]) {
        expect(d, lessThanOrEqualTo(const Duration(milliseconds: 500)));
      }
    });

    testWidgets('reduced motion follows the system setting', (tester) async {
      late bool normal;
      late bool removed;
      await tester.pumpWidget(
        Column(
          children: [
            MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) {
                  normal = Motion.reducedOf(context);
                  return const SizedBox();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  removed = Motion.reducedOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      );

      expect(normal, isFalse);
      expect(removed, isTrue);
    });
  });

  group('container transform', () {
    late GlobalKey originKey;
    late ValueNotifier<double> originTop;
    late GlobalKey<NavigatorState> navigator;

    setUp(() {
      originKey = GlobalKey();
      originTop = ValueNotifier(100);
      navigator = GlobalKey();
    });

    /// A screen with a 200 x 80 box at [originTop], under an 800 x 600
    /// screen.
    Future<void> pumpOrigin(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: originTop,
              builder: (context, top, _) => Stack(
                children: [
                  Positioned(
                    left: 50,
                    top: top,
                    width: 200,
                    height: 80,
                    child: ColoredBox(key: originKey, color: Colors.teal),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    void push(WidgetTester tester) => navigator.currentState!.push(
      ContainerTransformRoute<void>(
        origin: TransitionOrigin(key: originKey, radius: 20),
        builder: (_) => const Scaffold(body: Text('screen')),
      ),
    );

    Rect surface(WidgetTester tester) => tester.getRect(
      find.ancestor(of: find.text('screen'), matching: find.byType(ClipRRect)),
    );

    testWidgets('grows from the origin to the full screen', (tester) async {
      await pumpOrigin(tester);
      push(tester);
      await tester.pump();
      await tester.pump(Motion.long * 0.5);

      final mid = surface(tester);
      const origin = Rect.fromLTWH(50, 100, 200, 80);
      const full = Rect.fromLTWH(0, 0, 800, 600);
      expect(mid.width, inExclusiveRange(origin.width, full.width));
      expect(mid.top, inExclusiveRange(full.top, origin.top));
      expect(mid.bottom, inExclusiveRange(origin.bottom, full.bottom));

      await tester.pumpAndSettle();
      expect(surface(tester), full);
    });

    testWidgets('shrinks back into where the origin is now', (tester) async {
      await pumpOrigin(tester);
      push(tester);
      await tester.pumpAndSettle();

      originTop.value = 400;
      await tester.pump();
      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(Motion.long * 0.97);

      final end = surface(tester);
      expect(end.top, closeTo(400, 20));

      await tester.pumpAndSettle();
      expect(find.text('screen'), findsNothing);
    });

    testWidgets('without an origin comes forward on the depth axis', (
      tester,
    ) async {
      await pumpOrigin(tester);
      final context = tester.element(find.byType(Scaffold));
      final route = const ContainerTransformPage<void>(child: SizedBox())
          .createRoute(context);

      expect(route, isA<SharedAxisRoute<void>>());
    });
  });
}
