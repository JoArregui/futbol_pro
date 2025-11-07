import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';

/// Widget auxiliar para manejar el Scaffold principal (BottomNavBar)
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.standings);
        break;
      case 2:
        context.go(AppRoutes.fields);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    // Usamos GoRouterState.of(context).matchedLocation para obtener la ruta actual.
    final location = GoRouterState.of(context).matchedLocation;

    // Calcula el índice basado en la ruta actual
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.standings)) return 1;
    if (location.startsWith(AppRoutes.fields)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0; // Default a la pestaña de Partidos
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(context, index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Mantiene los iconos fijos
        // Los ítems de la barra de navegación.
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Partidos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'Clasificación'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer), label: 'Canchas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
