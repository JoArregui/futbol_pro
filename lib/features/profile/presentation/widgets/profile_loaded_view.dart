import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';

class ProfileLoadedView extends StatefulWidget {
  final UserProfile profile;
  final bool isUpdating;

  const ProfileLoadedView({
    super.key,
    required this.profile,
    required this.isUpdating,
  });

  @override
  State<ProfileLoadedView> createState() => _ProfileLoadedViewState();
}

class _ProfileLoadedViewState extends State<ProfileLoadedView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con los valores actuales
    _nicknameController = TextEditingController(text: widget.profile.nickname);
    _nameController = TextEditingController(text: widget.profile.name ?? '');
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  // Función de envío
  void _submitUpdate() {
    if (_formKey.currentState!.validate()) {
      final bloc = context.read<ProfileBloc>();
      
      // Disparar el evento de actualización con los nuevos valores
      bloc.add(ProfileUpdated(
        uid: widget.profile.uid,
        nickname: _nicknameController.text.trim(),
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        // avatarUrl se podría manejar con un widget de selección de imagen
        avatarUrl: widget.profile.avatarUrl, 
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Sección de Avatar y Nickname
            _buildHeader(context),
            const Divider(height: 32),

            // Campos de Edición
            _buildEditableFields(),
            const SizedBox(height: 24),
            
            // Sección de Estadísticas
            _buildStatsSection(),
            const SizedBox(height: 32),

            // Botón de Guardar
            ElevatedButton(
              onPressed: widget.isUpdating ? null : _submitUpdate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: widget.isUpdating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: widget.profile.avatarUrl != null && widget.profile.avatarUrl!.isNotEmpty
              ? NetworkImage(widget.profile.avatarUrl!)
              : null,
          child: widget.profile.avatarUrl == null || widget.profile.avatarUrl!.isEmpty
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          '@${widget.profile.nickname}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          widget.profile.email,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Información Básica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nicknameController,
          decoration: const InputDecoration(
            labelText: 'Nickname *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.alternate_email),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nickname es obligatorio.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Biografía',
            hintText: 'Cuéntanos algo sobre ti...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Estadísticas (FutbolPro)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  value: widget.profile.gamesPlayed.toString(),
                  label: 'Jugados',
                ),
                _StatItem(
                  value: widget.profile.wins.toString(),
                  label: 'Victorias',
                ),
                _StatItem(
                  value: widget.profile.rating.toStringAsFixed(2),
                  label: 'Rating',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Sub-Widget para mostrar una estadística individual
class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}