import 'package:flutter/material.dart';

/// Makes a unit draggable in whatever way suits the pointer dragging it.
///
/// With a mouse, a press is unambiguous: desktop and web do not scroll by
/// dragging, so a drag can start immediately. With a finger it is not — an
/// immediate drag inside a scrolling bench would fight the scroll — so touch
/// gets the long press instead. Both hand the same payload to the same
/// [DragTarget]s, so nothing downstream knows which one happened.
class UnitDragSource extends StatelessWidget {
  const UnitDragSource({
    required this.unitId,
    required this.feedback,
    required this.child,
    this.childWhenDragging,
    this.onDragCompleted,
    super.key,
  });

  /// What the drag carries: the id of the unit being moved.
  final String unitId;

  /// Drawn under the pointer for the length of the drag.
  final Widget feedback;

  final Widget child;

  /// Left in the child's place while it is being dragged. Defaults to a
  /// faded copy of [child].
  final Widget? childWhenDragging;

  final VoidCallback? onDragCompleted;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder =
        childWhenDragging ?? Opacity(opacity: 0.3, child: child);
    // Rendered in an overlay, outside this subtree, so it brings its own
    // Material for the text and ink inside it to resolve against.
    final Widget floating = Material(
      color: Colors.transparent,
      child: Opacity(opacity: 0.9, child: feedback),
    );

    return switch (Theme.of(context).platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia =>
        LongPressDraggable<String>(
          data: unitId,
          feedback: floating,
          childWhenDragging: placeholder,
          onDragCompleted: onDragCompleted,
          hapticFeedbackOnStart: true,
          child: child,
        ),
      _ => Draggable<String>(
          data: unitId,
          feedback: floating,
          childWhenDragging: placeholder,
          onDragCompleted: onDragCompleted,
          child: child,
        ),
    };
  }
}
