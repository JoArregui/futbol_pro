import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:futbol_pro/features/match_scheduling/domain/repositories/match_repository.dart';
import 'package:futbol_pro/features/match_scheduling/presentation/bloc/match_bloc.dart';
import 'package:futbol_pro/features/match_scheduling/domain/usecases/schedule_friendly_match.dart';
import 'package:futbol_pro/features/match_scheduling/domain/usecases/join_match.dart';
import 'package:futbol_pro/features/match_scheduling/domain/usecases/generate_balanced_teams.dart';
import 'package:futbol_pro/features/match_scheduling/domain/usecases/get_match_details.dart';
import 'package:futbol_pro/features/match_scheduling/domain/usecases/update_match_with_teams.dart';
import 'package:futbol_pro/features/match_scheduling/domain/usecases/get_upcoming_matches.dart';

class MockMatchRepo extends Mock implements MatchRepository {}

void main() {
  test('MatchBloc initial state is MatchInitial', () {
    final repo = MockMatchRepo();
    final bloc = MatchBloc(
      scheduleFriendlyMatch: ScheduleFriendlyMatch(repo),
      joinMatch: JoinMatch(repo),
      generateBalancedTeams: GenerateBalancedTeams(),
      getMatchDetails: GetMatchDetails(repo),
      updateMatchWithTeams: UpdateMatchWithTeams(repo),
      getUpcomingMatches: GetUpcomingMatches(repo),
    );
    expect(bloc.state, isA<MatchInitial>());
    bloc.close();
  });
}
