import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/match_model.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/match.dart';

class MatchDetailView extends StatelessWidget {
  final Match match;

  const MatchDetailView({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final MatchModel? matchModel =
        match is MatchModel ? match as MatchModel : null;

    final String timeFormatted =
        DateFormat('dd MMM yyyy - HH:mm').format(match.scheduledTime);

    // Obtener la información de los jugadores de los equipos
    String getPlayerList(Team? team) {
      if (team == null || team.players.isEmpty) return 'No asignado';
      // Muestra los apodos de los jugadores
      return team.players.map((p) => p.nickname).join(', ');
    }

    final String teamAPlayers = getPlayerList(matchModel?.teamA);
    final String teamBPlayers = getPlayerList(matchModel?.teamB);

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
          Text(
            'Asignación de Equipos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 15),
          _buildTeamCard(
            context,
            teamName: 'Equipo A',
            rating: matchModel?.teamA?.combinedRating,
            players: teamAPlayers,
            color: Colors.blue.shade50,
            iconColor: Colors.blue.shade700,
          ),
          const SizedBox(height: 10),
          _buildTeamCard(
            context,
            teamName: 'Equipo B',
            rating: matchModel?.teamB?.combinedRating,
            players: teamBPlayers,
            color: Colors.red.shade50,
            iconColor: Colors.red.shade700,
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
                'Las acciones de Unirse/Generar Equipos se gestionan con MatchBloc en otros widgets.',
                style: TextStyle(
                    color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required IconData icon,
      required String title,
      required String subtitle}) {
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
                        fontSize: 24, fontWeight: FontWeight.w800),
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

  Widget _buildDetailRow(
      {required IconData icon, required String label, required String value}) {
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
                  fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w400, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context,
      {required String teamName,
      double? rating,
      required String players,
      required Color color,
      required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: iconColor, size: 28),
              const SizedBox(width: 8),
              Text(
                teamName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              const Spacer(),
              if (rating != null)
                Text(
                  'Rating: ${rating.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: iconColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Jugadores:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: iconColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            players,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}