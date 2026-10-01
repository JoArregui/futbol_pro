import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_event_listener.dart';
import '../../core/widgets/app_states.dart';
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
      context.go(shellRoutes[index]);
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = shellRoutes.indexWhere((path) => location.startsWith(path));
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: AppEventListener(
        child: Stack(
          children: [
            Column(
              children: [
                const OfflineBar(),
                const OutboxBanner(),
                Expanded(child: child),
              ],
            ),
            const DraggableFloatingChatButton(),
          ],
        ),
      ),
      bottomNavigationBar: hideBottomBar
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF121814).withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: NavigationBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      height: 68,
                      selectedIndex: _calculateSelectedIndex(context),
                      onDestinationSelected: (i) => _onItemTapped(context, i),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.calendar_month_outlined),
                          selectedIcon: Icon(Icons.calendar_month),
                          label: 'Partidos',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.emoji_events_outlined),
                          selectedIcon: Icon(Icons.emoji_events),
                          label: 'Ligas',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.stadium_outlined),
                          selectedIcon: Icon(Icons.stadium),
                          label: 'Canchas',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.chat_bubble_outline_rounded),
                          selectedIcon: Icon(Icons.chat_bubble_rounded),
                          label: 'Chat',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline_rounded),
                          selectedIcon: Icon(Icons.person_rounded),
                          label: 'Perfil',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
