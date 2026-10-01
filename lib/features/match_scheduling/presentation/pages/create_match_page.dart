import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/injection_container.dart';
import '../../../field_management/presentation/bloc/field_bloc.dart';
import '../../domain/entities/referee.dart';
import '../../data/datasources/referee_remote_datasource.dart';
import '../bloc/match_bloc.dart';

/// Crear amistoso: jugadores sueltos (open) o equipo completo (team),
/// con campo (disponibilidad real) y opción de solicitar árbitro.
class CreateMatchPage extends StatefulWidget {
  const CreateMatchPage({super.key});

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController(text: 'Amistoso');
  final _descCtrl = TextEditingController();
  final _teamCtrl = TextEditingController();
  final _opponentCtrl = TextEditingController();
  final _maxCtrl = TextEditingController(text: '14');
  final _costCtrl = TextEditingController();

  bool _isTeamMode = false;
  bool _needsReferee = false;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  String? _selectedFieldId;
  List<Referee> _referees = [];
  bool _loadingRefs = false;

  DateTime get _start =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
  DateTime get _end => _start.add(const Duration(hours: 2));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  void _searchFields(BuildContext fieldCtx) {
    fieldCtx.read<FieldBloc>().add(
      GetAvailableFieldsEvent(startTime: _start, endTime: _end),
    );
  }

  Future<void> _loadReferees() async {
    if (!_needsReferee) return;
    setState(() => _loadingRefs = true);
    try {
      final ds = sl<RefereeRemoteDataSource>();
      final list = await ds.getAvailable(date: _start);
      if (mounted) setState(() => _referees = list);
    } catch (_) {
      if (mounted) setState(() => _referees = []);
    } finally {
      if (mounted) setState(() => _loadingRefs = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFieldId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un campo disponible')),
      );
      return;
    }
    context.read<MatchBloc>().add(
      ScheduleFriendlyMatchEvent(
        time: _start,
        fieldId: _selectedFieldId!,
        title: _titleCtrl.text.trim(),
        mode: _isTeamMode ? 'team' : 'open',
        needsReferee: _needsReferee,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        organizerTeamName: _isTeamMode && _teamCtrl.text.trim().isNotEmpty
            ? _teamCtrl.text.trim()
            : null,
        opponentTeamName: _isTeamMode && _opponentCtrl.text.trim().isNotEmpty
            ? _opponentCtrl.text.trim()
            : null,
        maxPlayers: _isTeamMode
            ? null
            : int.tryParse(_maxCtrl.text.trim()) ?? 14,
        costeTotal: double.tryParse(_costCtrl.text.trim().replaceAll(',', '.')),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _teamCtrl.dispose();
    _opponentCtrl.dispose();
    _maxCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FieldBloc>(),
      child: Builder(
        builder: (fieldCtx) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Crear amistoso'),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            body: BlocListener<MatchBloc, MatchState>(
              listener: (context, state) {
                if (state is MatchScheduledSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Partido creado${state.match.needsReferee ? ' + árbitro solicitado' : ''}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.go('/matches');
                } else if (state is MatchError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Jugadores sueltos'),
                          icon: Icon(Icons.group),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Equipo completo'),
                          icon: Icon(Icons.shield),
                        ),
                      ],
                      selected: {_isTeamMode},
                      onSelectionChanged: (s) =>
                          setState(() => _isTeamMode = s.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    if (_isTeamMode) ...[
                      TextFormField(
                        controller: _teamCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de tu equipo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            _isTeamMode && (v == null || v.trim().isEmpty)
                            ? 'Requerido para equipo'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _opponentCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Equipo rival (vacío = abierto a retos)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      TextFormField(
                        controller: _maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Máx. jugadores',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 2 || n > 30) {
                            return 'Entre 2 y 30';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _costCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText:
                            'Coste total cancha (opcional, para dividir)',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(
                          v.trim().replaceAll(',', '.'),
                        );
                        if (n == null || n < 0) return 'Monto inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(DateFormat('dd/MM/yyyy').format(_date)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(_time.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _searchFields(fieldCtx),
                      icon: const Icon(Icons.search),
                      label: Text(
                        'Ver disponibilidad (${DateFormat('HH:mm').format(_start)}-${DateFormat('HH:mm').format(_end)})',
                      ),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<FieldBloc, FieldState>(
                      builder: (context, state) {
                        if (state is FieldLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (state is FieldLoadSuccess) {
                          if (state.fields.isEmpty) {
                            return const Text(
                              'Sin campos libres en ese horario. Prueba otra hora.',
                            );
                          }
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedFieldId,
                            decoration: const InputDecoration(
                              labelText: 'Campo disponible',
                              border: OutlineInputBorder(),
                            ),
                            items: state.fields
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f.id,
                                    child: Text(
                                      '${f.name} — \$${f.hourlyRate}/h',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedFieldId = v),
                            validator: (v) =>
                                v == null ? 'Elige un campo' : null,
                          );
                        }
                        if (state is FieldError) {
                          return Text(
                            'Error campos: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }
                        return const Text(
                          'Busca disponibilidad para elegir campo.',
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _needsReferee,
                      onChanged: (v) {
                        setState(() => _needsReferee = v);
                        if (v) _loadReferees();
                      },
                      title: const Text('Solicitar árbitro'),
                      subtitle: const Text(
                        'Un árbitro oficial para el partido',
                      ),
                      secondary: const Icon(Icons.flag),
                    ),
                    if (_needsReferee)
                      _loadingRefs
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _referees.isEmpty
                          ? const Text(
                              'No hay árbitros libres (se solicitará igualmente).',
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Árbitros disponibles:'),
                                ..._referees
                                    .take(3)
                                    .map(
                                      (r) => ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.sports_soccer,
                                        ),
                                        title: Text(r.name),
                                        subtitle: Text(
                                          'Rating ${r.rating} — \$${r.fee}',
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                    const SizedBox(height: 16),
                    BlocBuilder<MatchBloc, MatchState>(
                      builder: (context, state) {
                        final loading = state is MatchLoading;
                        return FilledButton.icon(
                          onPressed: loading ? null : _submit,
                          icon: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _isTeamMode
                                ? 'Crear reto de equipos'
                                : 'Crear amistoso abierto',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
