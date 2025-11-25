import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';
import 'draggable_floating_chat_button.dart';

const List<String> shellRoutes = [
  AppRoutes.matches,
  AppRoutes.standings,
  AppRoutes.fields,
  AppRoutes.chat,
  AppRoutes.profile,
];

class MainScaffold extends StatelessWidget {
  final Widget child;
  final bool hideBottomBar;

  const MainScaffold({
    super.key,
    required this.child,
    this.hideBottomBar = false,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index >= 0 && index < shellRoutes.length) {
      final path = shellRoutes[index];

      context.go(path);
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    int index = shellRoutes.indexWhere((path) => location.startsWith(path));

    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          const DraggableFloatingChatButton(),
        ],
      ),
      bottomNavigationBar: hideBottomBar
          ? null
          : BottomNavigationBar(
              currentIndex: _calculateSelectedIndex(context),
              onTap: (index) => _onItemTapped(context, index),
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month), label: 'Partidos'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt), label: 'Clasificación'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.sports_soccer), label: 'Canchas'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Perfil'),
              ],
            ),
    );
  }
}
