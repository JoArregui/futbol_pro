import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/league_detail.dart';
import '../../domain/entities/standing.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/usecases/create_league.dart';
import '../../domain/usecases/generate_fixture.dart';
import '../../domain/usecases/get_league_detail.dart';
import '../../domain/usecases/get_league_standings.dart';
import '../../domain/usecases/get_tournaments.dart';
import '../../domain/usecases/register_team.dart';

part 'league_event.dart';
part 'league_state.dart';

class LeagueBloc extends Bloc<LeagueEvent, LeagueState> {
  final GetLeagueStandings getLeagueStandings;
  final GetTournaments? getTournaments;
  final RegisterTeam? registerTeam;
  final CreateLeague? createLeague;
  final GetLeagueDetail? getLeagueDetail;
  final GenerateFixture? generateFixture;

  LeagueBloc({
    required this.getLeagueStandings,
    this.getTournaments,
    this.registerTeam,
    this.createLeague,
    this.getLeagueDetail,
    this.generateFixture,
  }) : super(LeagueInitial()) {
    on<GetStandingsRequested>(_onGetStandingsRequested);
    on<GetTournamentsRequested>(_onGetTournaments);
    on<RegisterTeamRequested>(_onRegisterTeam);
    on<CreateLeagueRequested>(_onCreateLeague);
    on<LeagueDetailRequested>(_onDetail);
    on<GenerateFixtureRequested>(_onGenerateFixture);
  }

  Future<void> _onGetStandingsRequested(
    GetStandingsRequested event,
    Emitter<LeagueState> emit,
  ) async {
    emit(LeagueLoading());

    final failureOrStandings = await getLeagueStandings(
      StandingsParams(leagueId: event.leagueId),
    );

    failureOrStandings.fold(
      (failure) {
        emit(LeagueError(message: failure.errorMessage));
      },
      (standings) {
        emit(LeagueLoadSuccess(standings: standings));
      },
    );
  }

  Future<void> _onGetTournaments(
    GetTournamentsRequested event,
    Emitter<LeagueState> emit,
  ) async {
    if (getTournaments == null) {
      emit(const LeagueError(message: 'Torneos no disponibles.'));
      return;
    }
    emit(LeagueLoading());
    final res = await getTournaments!(NoParams());
    res.fold(
      (f) => emit(LeagueError(message: f.errorMessage)),
      (list) => emit(TournamentsLoaded(tournaments: list)),
    );
  }

  Future<void> _onRegisterTeam(
    RegisterTeamRequested event,
    Emitter<LeagueState> emit,
  ) async {
    if (registerTeam == null) {
      emit(const LeagueError(message: 'Registro no disponible.'));
      return;
    }
    emit(LeagueLoading());
    final res = await registerTeam!(
      RegisterTeamParams(leagueId: event.leagueId, teamName: event.teamName),
    );
    res.fold(
      (f) => emit(LeagueError(message: f.errorMessage)),
      (_) => emit(TeamRegistered(leagueId: event.leagueId)),
    );
  }

  Future<void> _onCreateLeague(
    CreateLeagueRequested event,
    Emitter<LeagueState> emit,
  ) async {
    if (createLeague == null) {
      emit(const LeagueError(message: 'Creación no disponible.'));
      return;
    }
    emit(LeagueLoading());
    final res = await createLeague!(
      CreateLeagueParams(
        nombre: event.nombre,
        descripcion: event.descripcion,
        maxEquipos: event.maxEquipos,
      ),
    );
    res.fold(
      (f) => emit(LeagueError(message: f.errorMessage)),
      (t) => emit(LeagueCreated(league: t)),
    );
  }

  Future<void> _onDetail(
    LeagueDetailRequested event,
    Emitter<LeagueState> emit,
  ) async {
    if (getLeagueDetail == null) {
      emit(const LeagueError(message: 'Detalle no disponible.'));
      return;
    }
    emit(LeagueLoading());
    final res = await getLeagueDetail!(
      LeagueDetailParams(leagueId: event.leagueId),
    );
    res.fold(
      (f) => emit(LeagueError(message: f.errorMessage)),
      (d) => emit(
        LeagueDetailLoaded(
          leagueId: event.leagueId,
          leagueName: event.leagueName,
          detail: d,
        ),
      ),
    );
  }

  Future<void> _onGenerateFixture(
    GenerateFixtureRequested event,
    Emitter<LeagueState> emit,
  ) async {
    if (generateFixture == null) {
      emit(const LeagueError(message: 'Fixture no disponible.'));
      return;
    }
    emit(LeagueLoading());
    final res = await generateFixture!(
      GenerateFixtureParams(leagueId: event.leagueId),
    );
    res.fold(
      (f) => emit(LeagueError(message: f.errorMessage)),
      (r) => emit(
        FixtureGenerated(
          leagueId: event.leagueId,
          jornadas: (r['jornadas'] as num?)?.toInt() ?? 0,
          partidos: (r['partidos'] as num?)?.toInt() ?? 0,
        ),
      ),
    );
  }
}
