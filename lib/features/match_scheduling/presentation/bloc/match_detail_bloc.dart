import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/match.dart';
import '../../domain/usecases/get_match_details.dart';

part 'match_detail_event.dart';
part 'match_detail_state.dart';

class MatchDetailBloc extends Bloc<MatchDetailEvent, MatchDetailState> {
  final GetMatchDetails getMatchDetails;

  MatchDetailBloc({required this.getMatchDetails})
      : super(MatchDetailInitial()) {
    on<MatchDetailLoadRequested>(_onMatchDetailLoadRequested);
  }

  Future<void> _onMatchDetailLoadRequested(
    MatchDetailLoadRequested event,
    Emitter<MatchDetailState> emit,
  ) async {
    emit(MatchDetailLoading());

    final failureOrMatch = await getMatchDetails(
      GetMatchDetailsParams(matchId: event.matchId),
    );

    failureOrMatch.fold(
      (failure) => emit(MatchDetailError(failure.errorMessage)),
      (match) => emit(MatchDetailLoaded(match: match)),
    );
  }
}