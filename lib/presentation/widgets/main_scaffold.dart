import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart'; 

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Encuentra el índice de la ruta actual
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = _calculateSelectedIndex(context, location);

    return Scaffold(
      body: child, // Muestra el contenido de la ruta actual (StandingsPage, MatchListPage, etc.)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (int index) => _onItemTapped(index, context),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Partidos'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Clasificación'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Canchas'),
        ],
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.schedule);
        break;
      case 1:
        context.go(AppRoutes.standings);
        break;
      case 2:
        context.go(AppRoutes.fields);
        break;
    }
  }

  int _calculateSelectedIndex(BuildContext context, String location) {
    if (location.startsWith(AppRoutes.schedule) || location.startsWith(AppRoutes.home)) {
      return 0;
    }
    if (location.startsWith(AppRoutes.standings)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.fields)) {
      return 2;
    }
    return 0;
  }
}