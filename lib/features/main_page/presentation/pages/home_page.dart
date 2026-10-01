import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/app_section.dart';

final List<AppSection> _sections = [
  const AppSection(
    title: 'Partidos',
    icon: Icons.calendar_month_rounded,
    routePath: AppRoutes.matches,
  ),
  const AppSection(
    title: 'Ligas',
    icon: Icons.emoji_events_rounded,
    routePath: AppRoutes.standings,
  ),
  const AppSection(
    title: 'Torneos',
    icon: Icons.military_tech_rounded,
    routePath: AppRoutes.tournaments,
  ),
  const AppSection(
    title: 'Canchas',
    icon: Icons.stadium_rounded,
    routePath: AppRoutes.fields,
  ),
  const AppSection(
    title: 'Chat',
    icon: Icons.chat_bubble_rounded,
    routePath: AppRoutes.chat,
  ),
  const AppSection(
    title: 'Mi Perfil',
    icon: Icons.person_rounded,
    routePath: AppRoutes.profile,
  ),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isSuperAdmin =
        authState is AuthAuthenticated && authState.isSuperAdmin;
    final name = authState is AuthAuthenticated
        ? (authState.userId.isEmpty ? ' crack' : '')
        : '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = [
      ..._sections,
      if (isSuperAdmin)
        const AppSection(
          title: 'Panel Admin',
          icon: Icons.admin_panel_settings_rounded,
          routePath: AppRoutes.admin,
        ),
    ];

    return HeroBackground(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientLime,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.lime.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FUTBOL PRO',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Juega. Compite. Gana.',
                              style: TextStyle(
                                color: AppColors.textDim,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt, size: 15, color: AppColors.lime),
                            SizedBox(width: 4),
                            Text(
                              'PRO',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Hero card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2A3F10),
                          Color(0xFF141E0C),
                          Color(0xFF0E150A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.lime.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TEMPORADA 2026',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Hola$name 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Tienes 3 partidos esta semana. Arma tu equipo y reserva cancha.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _HeroBtn(
                                label: 'Jugar ahora',
                                icon: Icons.play_arrow_rounded,
                                filled: true,
                                onTap: () => context.go(AppRoutes.matches),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HeroBtn(
                                label: 'Reservar',
                                icon: Icons.stadium_rounded,
                                filled: false,
                                onTap: () => context.go(AppRoutes.fields),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.02,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _SectionCard(
                  section: sections[i],
                  highlight: sections[i].title == 'Panel Admin',
                ),
                childCount: sections.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _HeroBtn({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.lime : Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: filled ? Colors.black : Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final AppSection section;
  final bool highlight;
  const _SectionCard({required this.section, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go(section.routePath),
      gradientColors: highlight
          ? [const Color(0xFF3A4D0E), const Color(0xFF1A220C)]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: highlight
                  ? AppColors.gradientLime
                  : LinearGradient(
                      colors: [
                        AppColors.lime.withValues(alpha: 0.22),
                        AppColors.field.withValues(alpha: 0.14),
                      ],
                    ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              section.icon,
              size: 26,
              color: highlight ? Colors.black : AppColors.lime,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Row(
                children: [
                  Text(
                    'Entrar',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.lime,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
