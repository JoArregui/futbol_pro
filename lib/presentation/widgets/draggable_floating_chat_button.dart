import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';

class DraggableFloatingChatButton extends StatefulWidget {
  const DraggableFloatingChatButton({super.key});

  @override
  State<DraggableFloatingChatButton> createState() =>
      _DraggableFloatingChatButtonState();
}

class _DraggableFloatingChatButtonState
    extends State<DraggableFloatingChatButton> {
  double _xPosition = 0;
  double _yPosition = 0;

  static const double _buttonSize = 64.0;
  static const double _margin = 16.0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialPosition(context);
    });
  }

  void _setInitialPosition(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;

    const bottomBarHeight = kBottomNavigationBarHeight;

    setState(() {
      _xPosition = width - _buttonSize - _margin;

      _yPosition = height - bottomBarHeight - _buttonSize - _margin;
    });
  }

  void _navigateToChat(BuildContext context) {
    context.go(AppRoutes.chat);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _xPosition,
      top: _yPosition,
      child: Draggable(
        feedback: FloatingActionButton(
          onPressed: () {},
          mini: true,
          child: const Icon(Icons.chat_bubble_outline_rounded, size: 28),
        ),
        childWhenDragging: Container(),
        child: FloatingActionButton(
          heroTag: 'chat_fab',
          onPressed: () => _navigateToChat(context),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: const Icon(Icons.chat_bubble_outline_rounded,
              color: Colors.white, size: 28),
        ),
        onDragEnd: (details) {
          final renderBox = context.findRenderObject() as RenderBox;
          final offset = renderBox.localToGlobal(Offset.zero);
          final size = MediaQuery.of(context).size;

          setState(() {
            _xPosition = details.offset.dx - offset.dx;
            _yPosition = details.offset.dy - offset.dy;

            _xPosition =
                _xPosition.clamp(_margin, size.width - _buttonSize - _margin);

            _yPosition = _yPosition.clamp(
                _margin,
                size.height -
                    kBottomNavigationBarHeight -
                    _buttonSize -
                    _margin);
          });
        },
      ),
    );
  }
}
