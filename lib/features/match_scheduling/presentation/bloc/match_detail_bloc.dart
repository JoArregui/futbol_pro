import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_acta.dart';
import '../../domain/entities/match_split.dart';
import '../../domain/usecases/get_match_acta.dart';
import '../../domain/usecases/get_match_details.dart';
import '../../domain/usecases/get_match_split.dart';
import '../../domain/usecases/submit_match_result.dart';
import '../../domain/usecases/confirm_match_result.dart';
import '../../domain/usecases/report_no_show.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

part 'match_detail_event.dart';
part 'match_detail_state.dart';

class MatchDetailBloc extends Bloc<MatchDetailEvent, MatchDetailState> {
  final GetMatchDetails getMatchDetails;
  final SubmitMatchResult submitMatchResult;
  final ConfirmMatchResult confirmMatchResult;
  final ReportNoShow reportNoShow;
  final GetMatchSplit getMatchSplit;
  final GetMatchActa getMatchActa;
  final AuthRepository authRepository;

  String get currentUserId => authRepository.getCurrentUserId();

  MatchDetailBloc({
    required this.getMatchDetails,
    required this.submitMatchResult,
    required this.confirmMatchResult,
    required this.reportNoShow,
    required this.getMatchSplit,
    required this.getMatchActa,
    required this.authRepository,
  }) : super(MatchDetailInitial()) {
    on<MatchDetailLoadRequested>(_onLoad);
    on<MatchResultProposeRequested>(_onPropose);
    on<MatchResultConfirmRequested>(_onConfirm);
    on<MatchNoShowReported>(_onNoShow);
    on<MatchSplitRequested>(_onSplit);
    on<MatchActaRequested>(_onActa);
  }

  Future<void> _reload(String matchId, Emitter<MatchDetailState> emit,
      {String? notice}) async {
    final res = await getMatchDetails(GetMatchDetailsParams(matchId: matchId));
    res.fold(
      (failure) => emit(MatchDetailError(failure.errorMessage)),
      (match) => emit(MatchDetailLoaded(match: match, notice: notice)),
    );
  }

  Future<void> _onLoad(
    MatchDetailLoadRequested event,
    Emitter<MatchDetailState> emit,
  ) async {
    emit(MatchDetailLoading());
    await _reload(event.matchId, emit);
  }

  Future<void> _onPropose(
    MatchResultProposeRequested event,
    Emitter<MatchDetailState> emit,
  ) async {
    final current = state;
    if (current is! MatchDetailLoaded) return;
    emit(MatchDetailActionRunning(match: current.match));
    final res = await submitMatchResult(event.params);
    await res.fold(
      (failure) async => emit(
          MatchDetailLoaded(match: current.match, error: failure.errorMessage)),
      (_) async => _reload(event.params.matchId, emit,
          notice:
              'Resultado propuesto. Falta que lo confirme otro participante.'),
    );
  }

  Future<void> _onConfirm(
    MatchResultConfirmRequested event,
    Emitter<MatchDetailState> emit,
  ) async {
    final current = state;
    if (current is! MatchDetailLoaded) return;
    emit(MatchDetailActionRunning(match: current.match));
    final res =
        await confirmMatchResult(ConfirmResultParams(matchId: event.matchId));
    await res.fold(
      (failure) async => emit(
          MatchDetailLoaded(match: current.match, error: failure.errorMessage)),
      (_) async => _reload(event.matchId, emit,
          notice: 'Resultado confirmado. Reputación actualizada.'),
    );
  }

  Future<void> _onNoShow(
    MatchNoShowReported event,
    Emitter<MatchDetailState> emit,
  ) async {
    final current = state;
    if (current is! MatchDetailLoaded) return;
    emit(MatchDetailActionRunning(match: current.match));
    final res = await reportNoShow(
        ReportNoShowParams(matchId: event.matchId, playerId: event.playerId));
    await res.fold(
      (failure) async => emit(
          MatchDetailLoaded(match: current.match, error: failure.errorMessage)),
      (count) async => _reload(event.matchId, emit,
          notice: 'No-show reportado ($count acumulados).'),
    );
  }

  Future<void> _onSplit(
    MatchSplitRequested event,
    Emitter<MatchDetailState> emit,
  ) async {
    final current = state;
    if (current is! MatchDetailLoaded) return;
    final res = await getMatchSplit(MatchSplitParams(matchId: event.matchId));
    res.fold(
      (failure) => emit(current.copyWith(error: failure.errorMessage)),
      (split) => emit(current.copyWith(split: split, error: null)),
    );
  }

  Future<void> _onActa(
    MatchActaRequested event,
    Emitter<MatchDetailState> emit,
  ) async {
    final current = state;
    if (current is! MatchDetailLoaded) return;
    final res = await getMatchActa(MatchActaParams(matchId: event.matchId));
    res.fold(
      (failure) => emit(current.copyWith(error: failure.errorMessage)),
      (acta) => emit(current.copyWith(acta: acta, error: null)),
    );
  }
}
