import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/app_section.dart';

// Lista estática de secciones
final List<AppSection> _sections = [
  const AppSection(
    title: 'Partidos/Agenda',
    icon: Icons.calendar_today_rounded,
    routePath: AppRoutes.home,
  ),
  const AppSection(
    title: 'Gestión de Ligas',
    icon: Icons.format_list_numbered,
    routePath: AppRoutes.standings,
  ),
  const AppSection(
    title: 'Gestión de Campos',
    icon: Icons.map_outlined,
    routePath: AppRoutes.fields,
  ),
  const AppSection(
    title: 'Chat / Mensajes',
    icon: Icons.chat_bubble_outline_rounded,
    routePath: AppRoutes.chat,
  ),
  const AppSection(
    title: 'Mi Perfil',
    icon: Icons.person_outline_rounded,
    routePath: AppRoutes.profile,
  ),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columnas
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,

        childAspectRatio: 1.1,
      ),
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        return _SectionCard(section: section);
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final AppSection section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          context.go(section.routePath);
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(section.icon,
                  size: 36, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
