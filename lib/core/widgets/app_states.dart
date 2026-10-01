import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../injection_container.dart';
import '../sync/outbox_drain.dart';
import '../sync/outbox_service.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Estado vacío estándar: icono + título + subtítulo + acción opcional.
class AppEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: AppColors.lime, size: 36),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: actionLabel!,
                expanded: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de error estándar con reintentar.
class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.danger, size: 36),
            ),
            const SizedBox(height: 14),
            const Text('Algo falló',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
            const SizedBox(height: 16),
            AppButton(
              label: 'Reintentar',
              icon: Icons.refresh_rounded,
              expanded: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton de carga tipo card (sin dependencias extra).
class AppSkeletonList extends StatelessWidget {
  final int count;
  const AppSkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => AppCard(
        child: Row(
          children: [
            _pulse(isDark, 48, 48, 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pulse(isDark, double.infinity, 14, 7),
                  const SizedBox(height: 8),
                  _pulse(isDark, 160, 12, 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pulse(bool isDark, double w, double h, double r) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}

/// Banner de cola offline: muestra pendientes y reintenta.
/// Se drena solo al recuperar conexión.
class OutboxBanner extends StatefulWidget {
  const OutboxBanner({super.key});

  @override
  State<OutboxBanner> createState() => _OutboxBannerState();
}

class _OutboxBannerState extends State<OutboxBanner> {
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Drenaje automático al volver la red.
    Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!online || _sending || !mounted) return;
      try {
        if (sl.isRegistered<OutboxService>() &&
            sl<OutboxService>().pendingCount.value > 0) {
          await _retry(silent: true);
        }
      } catch (_) {}
    });
  }

  Future<void> _retry({bool silent = false}) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final r = await drainOutbox();
      if (!mounted) return;
      if (!silent || r.failed > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(r.failed == 0
                ? '✅ ${r.ok} acciones enviadas.'
                : '⚠️ ${r.ok} enviadas, ${r.failed} siguen pendientes.'),
          ),
        );
      }
    } catch (_) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Aún sin conexión.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    OutboxService? outbox;
    try {
      outbox = sl<OutboxService>();
    } catch (_) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<int>(
      valueListenable: outbox!.pendingCount,
      builder: (context, count, _) {
        if (count == 0) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.lime.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lime.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              if (_sending)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.outbox_rounded,
                    color: AppColors.lime, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    '$count ${count == 1 ? 'acción pendiente' : 'acciones pendientes'} de envío.',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: _sending ? null : () => _retry(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Barra offline global (usa connectivity_plus, ya dependencia).
/// Mostrar arriba del contenido cuando no hay red.
class OfflineBar extends StatelessWidget {
  const OfflineBar({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snap) {
        final results = snap.data;
        final offline = results != null &&
            (results.isEmpty ||
                results.every((r) => r == ConnectivityResult.none));
        if (!offline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('Sin conexión: verás datos guardados.',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }
}
