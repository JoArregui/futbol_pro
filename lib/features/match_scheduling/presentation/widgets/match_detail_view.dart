import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/consts.dart';
import '../../../../core/injection_container.dart';
import '../../../../core/services/file_download_service.dart';
import '../../data/models/match_model.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/usecases/submit_match_result.dart';
import '../bloc/match_detail_bloc.dart';

class MatchDetailView extends StatelessWidget {
  final Match match;

  const MatchDetailView({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final MatchModel? matchModel = match is MatchModel
        ? match as MatchModel
        : null;

    final String timeFormatted = DateFormat(
      'dd MMM yyyy - HH:mm',
    ).format(match.scheduledTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            icon: Icons.sports_soccer,
            title: match.title,
            subtitle: 'ID: ${match.id}',
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Hora Programada',
            value: timeFormatted,
          ),
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Campo de Juego',
            value: match.fieldId,
          ),
          _buildDetailRow(
            icon: Icons.info_outline,
            label: 'Tipo de Partido',
            value: match.type == MatchType.league ? 'Liga' : 'Amistoso',
          ),
          _buildDetailRow(
            icon: Icons.group,
            label: 'Jugadores Inscritos',
            value: '${match.playerIds.length} jugadores',
          ),
          const Divider(height: 30),
          _ResultSection(matchModel: matchModel),
          const Divider(height: 30),
          Text(
            'Participantes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 15),
          _ParticipantsCard(matchModel: matchModel),
          const Divider(height: 30),
          const _SplitSection(),
          const Divider(height: 30),
          const _ActaSection(),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.deepPurple.shade700),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple.shade400),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de resultado: marcador confirmado/propuesto o formulario.
class _ResultSection extends StatelessWidget {
  final MatchModel? matchModel;
  const _ResultSection({required this.matchModel});

  @override
  Widget build(BuildContext context) {
    final model = matchModel;
    final result = model?.result;
    final myId = context.read<MatchDetailBloc>().currentUserId;
    final isParticipant = model?.participants.any((p) => p.id == myId) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marcador final',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 12),
        if (result != null)
          _ResultCard(result: result, participants: model!.participants)
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aún no hay marcador registrado.'),
            ),
          ),
        const SizedBox(height: 12),
        if (result != null && !result.isConfirmed)
          if (result.propuestoPor == myId)
            const Card(
              color: Color(0xFFFFF8E1),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Marcador pendiente de validación. Debe validarlo otro participante del partido.',
                ),
              ),
            )
          else if (isParticipant)
            FilledButton.icon(
              onPressed: () => context.read<MatchDetailBloc>().add(
                MatchResultConfirmRequested(model!.id),
              ),
              icon: const Icon(Icons.verified),
              label: const Text('Validar marcador'),
            ),
        if (result == null && isParticipant)
          _ProposeForm(matchId: model!.id, participants: model.participants),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final MatchResult result;
  final List<MatchParticipant> participants;
  const _ResultCard({required this.result, required this.participants});

  String _name(String id) {
    final p = participants.where((e) => e.id == id);
    if (p.isEmpty) return id;
    final v = p.first;
    return v.nickname.isNotEmpty ? v.nickname : v.name;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: result.isConfirmed
          ? const Color(0xFFE8F5E9)
          : const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  result.scoreLine(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 12),
                Chip(
                  label: Text(
                    result.isConfirmed ? 'Validado' : 'Pendiente de validación',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            if (result.mvpId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(
                    'MVP: ${_name(result.mvpId!)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            if (result.goleadores.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Goleadores:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              ...result.goleadores.map(
                (g) => Text('• ${_name(g.playerId)} (${g.goles})'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Formulario de propuesta: marcador + ganador + MVP + goleadores.
class _ProposeForm extends StatefulWidget {
  final String matchId;
  final List<MatchParticipant> participants;
  const _ProposeForm({required this.matchId, required this.participants});

  @override
  State<_ProposeForm> createState() => _ProposeFormState();
}

class _ProposeFormState extends State<_ProposeForm> {
  int _golesA = 0;
  int _golesB = 0;
  String _ganador = 'empate';
  String? _mvpId;
  final List<_ScorerRow> _scorers = [];

  void _submit() {
    context.read<MatchDetailBloc>().add(
      MatchResultProposeRequested(
        SubmitResultParams(
          matchId: widget.matchId,
          golesA: _golesA,
          golesB: _golesB,
          ganador: _ganador,
          mvpId: _mvpId,
          goleadores: _scorers
              .where((s) => s.playerId != null)
              .map((s) => ScorerEntry(playerId: s.playerId!, goles: s.goles))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrar marcador final',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ScoreStepper(
                    label: 'Equipo A',
                    value: _golesA,
                    onChanged: (v) => setState(() => _golesA = v),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '-',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _ScoreStepper(
                    label: 'Equipo B',
                    value: _golesB,
                    onChanged: (v) => setState(() => _golesB = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LabeledDropdown<String>(
              label: 'Ganador',
              value: _ganador,
              items: const [
                DropdownMenuItem(value: 'empate', child: Text('Empate')),
                DropdownMenuItem(value: 'A', child: Text('Equipo A')),
                DropdownMenuItem(value: 'B', child: Text('Equipo B')),
              ],
              onChanged: (v) => setState(() => _ganador = v ?? 'empate'),
            ),
            const SizedBox(height: 12),
            _LabeledDropdown<String>(
              label: 'MVP (opcional)',
              value: _mvpId,
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin MVP')),
                ...widget.participants.map(
                  (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.nickname.isNotEmpty ? p.nickname : p.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _mvpId = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Goleadores',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _scorers.add(_ScorerRow())),
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                ),
              ],
            ),
            ..._scorers.asMap().entries.map(
              (e) => _ScorerRowWidget(
                key: ValueKey(e.key),
                row: e.value,
                participants: widget.participants,
                onRemove: () => setState(() => _scorers.removeAt(e.key)),
                onChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send),
                label: const Text('Guardar marcador'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorerRow {
  String? playerId;
  int goles = 1;
}

class _ScorerRowWidget extends StatelessWidget {
  final _ScorerRow row;
  final List<MatchParticipant> participants;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _ScorerRowWidget({
    super.key,
    required this.row,
    required this.participants,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _LabeledDropdown<String>(
              label: 'Jugador',
              value: row.playerId,
              items: participants
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        p.nickname.isNotEmpty ? p.nickname : p.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                row.playerId = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _LabeledDropdown<int>(
              label: 'Goles',
              value: row.goles,
              items: List.generate(9, (i) => i + 1)
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) {
                row.goles = v ?? 1;
                onChanged();
              },
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

/// Dropdown con etiqueta y borde (DropdownButtonFormField.value está
/// deprecado: se usa DropdownButton dentro de un InputDecorator).
class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          isExpanded: true,
          isDense: true,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ScoreStepper extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _ScoreStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$value',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: value < 99 ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}

/// División de cuenta entre participantes (carga bajo demanda).
class _SplitSection extends StatelessWidget {
  const _SplitSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchDetailBloc, MatchDetailState>(
      builder: (context, state) {
        final loaded = state is MatchDetailLoaded ? state : null;
        final split = loaded?.split;
        final model = loaded?.match is MatchModel
            ? loaded!.match as MatchModel
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dividir cuenta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            if (model?.costeTotal != null)
              Text(
                'Coste total: \$${model!.costeTotal!.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 8),
            if (split == null)
              OutlinedButton.icon(
                onPressed: loaded == null
                    ? null
                    : () => context.read<MatchDetailBloc>().add(
                        MatchSplitRequested(loaded.match.id),
                      ),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Calcular por persona'),
              )
            else if (!split.hasCost)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Este partido no tiene coste registrado. Al crearlo puedes indicar el total.',
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${split.perPerson.toStringAsFixed(2)} por persona '
                        '(${split.participants} jugadores)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...split.detail.map(
                        (d) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(child: Text(d.name)),
                              Text(
                                '\$${d.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Acta oficial del partido: se carga bajo demanda y se puede exportar a CSV.
class _ActaSection extends StatelessWidget {
  const _ActaSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchDetailBloc, MatchDetailState>(
      builder: (context, state) {
        final loaded = state is MatchDetailLoaded ? state : null;
        final acta = loaded?.acta;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acta del partido',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            if (acta == null)
              OutlinedButton.icon(
                onPressed: loaded == null
                    ? null
                    : () => context.read<MatchDetailBloc>().add(
                        MatchActaRequested(loaded.match.id),
                      ),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Ver acta oficial'),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${acta.golesA ?? '-'} - ${acta.golesB ?? '-'} · ${acta.estado}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text('${acta.field} · ${acta.time}'),
                      if (acta.mvp != null)
                        Text(
                          'MVP: ${acta.mvp}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      if (acta.scorers.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Goleadores:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        ...acta.scorers.map(
                          (g) => Text('• ${g.name} (${g.goles})'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Participantes (${acta.participants.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ...acta.participants.map(
                        (p) => Text(
                          '• ${p.name}${p.noShows > 0 ? ' (${p.noShows} ausencias)' : ''}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _exportActa(context, acta.matchId),
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Exportar CSV'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _exportActa(BuildContext context, String matchId) async {
    try {
      final path = await sl<FileDownloadService>().downloadText(
        apiPath: '${AppConsts.effectiveBaseUrl}/matches/$matchId/acta.csv',
        filename: 'acta-$matchId.csv',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Acta guardada: $path')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error export: $e')));
      }
    }
  }
}

class _ParticipantsCard extends StatelessWidget {
  final MatchModel? matchModel;
  const _ParticipantsCard({required this.matchModel});

  @override
  Widget build(BuildContext context) {
    final participants = matchModel?.participants ?? const [];
    if (participants.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sin participantes todavía.'),
        ),
      );
    }
    final myId = context.read<MatchDetailBloc>().currentUserId;
    return Card(
      child: Column(
        children: participants
            .map(
              (p) => ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (p.nickname.isNotEmpty ? p.nickname : p.name)
                            .characters
                            .firstOrNull
                            ?.toUpperCase() ??
                        '?',
                  ),
                ),
                title: Text(p.nickname.isNotEmpty ? p.nickname : p.name),
                subtitle: Text(
                  '${p.played} PJ • ${p.wins} V • ${p.mvpCount} MVP${p.noShows > 0 ? ' • ${p.noShows} ausencias' : ''}',
                ),
                trailing: p.id == myId
                    ? null
                    : IconButton(
                        tooltip: 'Reportar no-show',
                        icon: const Icon(
                          Icons.flag_outlined,
                          color: Colors.orange,
                        ),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Reportar no-show'),
                            content: Text(
                              '¿Confirmas que ${p.nickname} no asistió?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.read<MatchDetailBloc>().add(
                                    MatchNoShowReported(
                                      matchId: matchModel!.id,
                                      playerId: p.id,
                                    ),
                                  );
                                },
                                child: const Text('Reportar'),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            )
            .toList(),
      ),
    );
  }
}
