import 'package:flutter/material.dart';

class SlidePageRoute extends PageRouteBuilder {
  final Widget page;
  final AxisDirection direction;

  SlidePageRoute({required this.page, this.direction = AxisDirection.right})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset beginOffset;

            switch (direction) {
              case AxisDirection.up:
                beginOffset = Offset(0.0, 1.0);
                break;
              case AxisDirection.down:
                beginOffset = Offset(0.0, -1.0);
                break;
              case AxisDirection.left:
                beginOffset = Offset(1.0, 0.0);
                break;
              case AxisDirection.right:
              default:
                beginOffset = Offset(-1.0, 0.0);
                break;
            }

            return SlideTransition(
              position: animation.drive(
                Tween(begin: beginOffset, end: Offset.zero).chain(
                  CurveTween(curve: Curves.ease),
                ),
              ),
              child: child,
            );
          },
        );
}
