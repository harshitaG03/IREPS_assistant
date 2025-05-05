import 'package:flutter/material.dart';

class SlidePageRoute extends PageRouteBuilder {
  final Widget page;
  final AxisDirection direction;

  SlidePageRoute({required this.page, this.direction = AxisDirection.right})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const offsetMap = {
        AxisDirection.up: Offset(0, 1),
        AxisDirection.down: Offset(0, -1),
        AxisDirection.left: Offset(1, 0),
        AxisDirection.right: Offset(-1, 0),
      };
      final begin = offsetMap[direction]!;
      final end = Offset.zero;
      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: Curves.ease));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
