import 'package:flutter/material.dart';
import 'match_detail_page.dart';

class MockMatch {
  final String id;
  final String title;
  final DateTime time;

  MockMatch({required this.id, required this.title, required this.time});
}

final List<MockMatch> mockMatches = [
  MockMatch(
      id: 'match-001',
      title: 'Amistoso de Martes',
      time: DateTime.now().add(const Duration(days: 2, hours: 1))),
  MockMatch(
      id: 'match-002',
      title: 'Partido por la Liga',
      time: DateTime.now().add(const Duration(days: 5, hours: 10))),
  MockMatch(
      id: 'match-003',
      title: 'Encuentro Casual',
      time: DateTime.now().add(const Duration(days: 1, hours: 5))),
];

class MatchListPage extends StatelessWidget {
  const MatchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidos Programados'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: mockMatches.length,
        itemBuilder: (context, index) {
          final match = mockMatches[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.sports_soccer, color: Colors.teal),
              title: Text(
                match.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Fecha: ${match.time.day}/${match.time.month} ${match.time.hour}:${match.time.minute.toString().padLeft(2, '0')} - ID: ${match.id}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchDetailPage(matchId: match.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
