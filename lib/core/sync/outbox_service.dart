import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart'
    show ValueNotifier, kIsWeb, visibleForTesting;
import 'package:path_provider/path_provider.dart';

/// Acciones que sí funcionan sin conexión: se guardan y se reenvían solas.
/// Tipos: join_match, submit_result, confirm_result, report_no_show.
class OutboxAction {
  final String id;
  final String kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;

  const OutboxAction({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'attempts': attempts,
  };

  factory OutboxAction.fromJson(Map<String, dynamic> j) => OutboxAction(
    id: (j['id'] ?? '').toString(),
    kind: (j['kind'] ?? '').toString(),
    payload: Map<String, dynamic>.from(j['payload'] as Map? ?? {}),
    createdAt:
        DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
    attempts: (j['attempts'] as num?)?.toInt() ?? 0,
  );

  OutboxAction bumped() => OutboxAction(
    id: id,
    kind: kind,
    payload: payload,
    createdAt: createdAt,
    attempts: attempts + 1,
  );
}

/// Detecta errores de red (los que sí tiene sentido reintentar).
/// Se basa en el tipo y el texto porque http lanza ClientException
/// envolviendo el SocketException original.
bool isNetworkError(Object e) {
  final type = e.runtimeType.toString();
  final s = '$type: ${e.toString()}';
  return type.contains('SocketException') ||
      (type.contains('ClientException') && s.contains('SocketException')) ||
      type.contains('TimeoutException') ||
      s.contains('SocketException') ||
      s.contains('Connection refused') ||
      s.contains('Connection reset') ||
      s.contains('Network is unreachable') ||
      s.contains('Failed host lookup') ||
      s.contains('TimeoutException');
}

/// Cola persistente de acciones offline (fichero en móvil/desktop,
/// memoria en web). Máx 50 acciones, se descartan tras 5 intentos.
class OutboxService {
  static const _fileName = 'outbox.json';
  static const _maxItems = 50;
  static const _maxAttempts = 5;

  final ValueNotifier<int> pendingCount = ValueNotifier(0);
  final List<OutboxAction> _items = [];
  bool _ready = false;

  @visibleForTesting
  List<OutboxAction> get items => List.unmodifiable(_items);

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    await _load();
  }

  static int _seq = 0;

  Future<void> enqueue(String kind, Map<String, dynamic> payload) async {
    await init();
    // Dedup por hash del payload completo: dos resultados distintos del
    // mismo partido NO son duplicados (antes se descartaban).
    final fingerprint = '$kind:${jsonEncode(payload)}';
    final dup = _items.any(
      (a) => '$a.kind:${jsonEncode(a.payload)}' == fingerprint,
    );
    if (dup) {
      pendingCount.value = _items.length;
      return;
    }
    _items.add(
      OutboxAction(
        id: 'o${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
        kind: kind,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
    while (_items.length > _maxItems) {
      _items.removeAt(0);
    }
    pendingCount.value = _items.length;
    await _save();
  }

  /// Ejecuta todas las pendientes con [executor]. Devuelve (ok, fallos).
  /// Sin red NO hace bump: solo cuenta intentos ante errores de servidor.
  Future<({int ok, int failed})> drain(
    Future<void> Function(OutboxAction action) executor,
  ) async {
    await init();
    var ok = 0;
    var failed = 0;
    for (final action in List<OutboxAction>.from(_items)) {
      try {
        await executor(action).timeout(const Duration(seconds: 15));
        _items.removeWhere((a) => a.id == action.id);
        ok++;
      } catch (e) {
        failed++;
        if (isNetworkError(e)) {
          continue; // aún offline: reintentar luego sin bump
        }
        final i = _items.indexWhere((a) => a.id == action.id);
        if (i >= 0) {
          final bumped = _items[i].bumped();
          if (bumped.attempts >= _maxAttempts) {
            _items.removeAt(i);
          } else {
            _items[i] = bumped;
          }
        }
      }
    }
    pendingCount.value = _items.length;
    await _save();
    return (ok: ok, failed: failed);
  }

  Future<void> clear() async {
    _items.clear();
    pendingCount.value = 0;
    await _save();
  }

  Future<void> _load() async {
    if (kIsWeb) return;
    try {
      final dir = (await getApplicationDocumentsDirectory()).path;
      final file = File('$dir/$_fileName');
      if (!await file.exists()) return;
      final List<dynamic> list = jsonDecode(await file.readAsString());
      _items
        ..clear()
        ..addAll(
          list.map(
            (e) => OutboxAction.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        );
      pendingCount.value = _items.length;
    } catch (_) {
      // Cola corrupta: empezar vacía antes que romper el arranque.
      _items.clear();
      pendingCount.value = 0;
    }
  }

  Future<void> _save() async {
    if (kIsWeb) return;
    try {
      final dir = (await getApplicationDocumentsDirectory()).path;
      final file = File('$dir/$_fileName');
      await file.writeAsString(
        jsonEncode(_items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }
}
