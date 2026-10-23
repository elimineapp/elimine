import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion/motion.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import 'pin_entry.dart';

/// Covers the whole app, dialogs and sheets included, with the lock screen
/// while it is locked. The app stays mounted below, so unlocking returns to
/// the same screen, tab and scroll position, but while locked it is neither
/// painted, animated, focusable nor read by screen readers.
class LockLayer extends ConsumerStatefulWidget {
  const LockLayer({
    super.key,
    required this.backButtonDispatcher,
    required this.onErased,
    required this.child,
  });

  /// The router's, so system back can be taken away from the app below.
  final BackButtonDispatcher? backButtonDispatcher;

  /// After erasing all data, to show Home.
  final VoidCallback onErased;
  final Widget child;

  @override
  ConsumerState<LockLayer> createState() => _LockLayerState();
}

class _LockLayerState extends ConsumerState<LockLayer>
    with SingleTickerProviderStateMixin {
  final _navigator = GlobalKey<NavigatorState>();
  ChildBackButtonDispatcher? _back;

  /// 1 while the lock screen covers the app; it fades out on unlock.
  late final _cover = AnimationController(vsync: this, duration: Motion.short);

  /// What the app below last told the platform about handling back.
  bool _appCanPop = false;

  @override
  void initState() {
    super.initState();
    _back = widget.backButtonDispatcher?.createChildBackButtonDispatcher();
    _back?.addCallback(_handleBack);
    if (ref.read(appLockProvider).locked) _lock();
  }

  @override
  void dispose() {
    _back?.removeCallback(_handleBack);
    _cover.dispose();
    super.dispose();
  }

  void _lock() {
    _cover.value = 1;
    FocusManager.instance.primaryFocus?.unfocus();
    // After the frame: at start the router below has not registered with
    // the dispatcher yet, and taking priority needs it to.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(appLockProvider).locked) _back?.takePriority();
    });
    // Back then leaves the app, instead of going back in the app below.
    SystemNavigator.setFrameworkHandlesBack(false);
  }

  void _unlock() {
    SystemNavigator.setFrameworkHandlesBack(_appCanPop);
    if (Motion.reducedOf(context)) {
      _cover.value = 0;
    } else {
      _cover.reverse();
    }
  }

  /// While locked, back closes the lock screen's own dialog or leaves the
  /// app; the app below never sees it.
  Future<bool> _handleBack() async {
    if (!ref.read(appLockProvider).locked) return false;
    if (!await (_navigator.currentState?.maybePop() ?? Future.value(false))) {
      await SystemNavigator.pop();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appLockProvider.select((s) => s.locked), (was, locked) {
      if (locked) {
        _lock();
      } else {
        _unlock();
      }
    });
    final locked = ref.watch(appLockProvider.select((s) => s.locked));
    return Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<NavigationNotification>(
          onNotification: (notification) {
            _appCanPop = notification.canHandlePop;
            return locked;
          },
          child: Offstage(
            offstage: locked,
            child: TickerMode(
              enabled: !locked,
              child: ExcludeSemantics(
                excluding: locked,
                child: ExcludeFocus(excluding: locked, child: widget.child),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _cover,
          builder: (context, child) => _cover.value == 0
              ? const SizedBox.shrink()
              : IgnorePointer(
                  ignoring: !locked,
                  child: FadeTransition(opacity: _cover, child: child),
                ),
          child: HeroControllerScope.none(
            child: Navigator(
              key: _navigator,
              onGenerateRoute: (_) => PageRouteBuilder(
                pageBuilder: (context, _, _) =>
                    LockScreen(onErased: widget.onErased),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LockScreen extends ConsumerWidget {
  const LockScreen({super.key, required this.onErased});

  final VoidCallback onErased;

  Future<void> _forgot(BuildContext context, WidgetRef ref) async {
    final erase = await showDialog<bool>(
      context: context,
      builder: (context) => const EraseDialog(),
    );
    if (erase != true) return;
    await ref.read(appLockProvider.notifier).eraseAll();
    onErased();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: PinEntry(
              unlock: true,
              title: l.enterPin,
              onRight: () {},
              header: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 64,
                    height: 64,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              footer: TextButton(
                key: const Key('forgotPin'),
                onPressed: () => _forgot(context, ref),
                child: Text(l.forgotPin),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Typed confirmations match whatever the case, the spaces at the ends or
/// between words, and "е" for "ё".
String normalizePhrase(String text) => text
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ')
    .toUpperCase()
    .replaceAll('Ё', 'Е');

/// Erasing all data after a forgotten PIN, confirmed by typing a phrase so a
/// tap cannot do it by accident. Returns true to erase.
class EraseDialog extends StatefulWidget {
  const EraseDialog({super.key});

  @override
  State<EraseDialog> createState() => _EraseDialogState();
}

class _EraseDialogState extends State<EraseDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final phrase = l.eraseConfirmPhrase;
    return AlertDialog(
      title: Text(l.forgotPinTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.forgotPinBody(phrase)),
            const SizedBox(height: 16),
            TextField(
              key: const Key('erasePhrase'),
              controller: _text,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: phrase,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        ListenableBuilder(
          listenable: _text,
          builder: (context, _) => TextButton(
            key: const Key('eraseAll'),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            onPressed: normalizePhrase(_text.text) == normalizePhrase(phrase)
                ? () => Navigator.pop(context, true)
                : null,
            child: Text(l.eraseAll),
          ),
        ),
      ],
    );
  }
}
