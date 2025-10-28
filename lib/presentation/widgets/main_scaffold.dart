import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart'; // Importación corregida de AppRoutes

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
        type: BottomNavigationBarType.fixed, // Usar fixed para que los 4 ítems no cambien de tamaño
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Partidos'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Clasificación'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Canchas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'), // Añadido
        ],
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home); // Navegación a Partidos (Home)
        break;
      case 1:
        context.go(AppRoutes.standings); // Navegación a Clasificación
        break;
      case 2:
        context.go(AppRoutes.fields); // Navegación a Canchas
        break;
      case 3:
        context.go(AppRoutes.profile); // Navegación al Perfil
        break;
    }
  }

  int _calculateSelectedIndex(BuildContext context, String location) {
    if (location.startsWith(AppRoutes.home)) {
      return 0;
    }
    if (location.startsWith(AppRoutes.standings)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.fields)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.profile)) {
      return 3;
    }
    return 0;
  }
}
