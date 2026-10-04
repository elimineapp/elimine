import 'package:flutter/material.dart';

/// A page shown as a modal bottom sheet over the page below it. The child
/// draws its own surface and handle, usually through a
/// [DraggableScrollableSheet], which also closes the sheet when dragged to
/// its minimum size.
class SheetPage<T> extends Page<T> {
  const SheetPage({required this.child, super.key, super.name});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    builder: (context) => child,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(),
    showDragHandle: false,
    barrierLabel: MaterialLocalizations.of(context).scrimLabel,
  );
}
