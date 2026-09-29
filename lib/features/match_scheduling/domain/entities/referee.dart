import 'package:equatable/equatable.dart';

class Referee extends Equatable {
  final String id;
  final String name;
  final double rating;
  final double fee;

  const Referee(
      {required this.id,
      required this.name,
      required this.rating,
      required this.fee});

  @override
  List<Object> get props => [id, name, rating, fee];

  factory Referee.fromJson(Map<String, dynamic> json) => Referee(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Árbitro').toString(),
        rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
        fee: (json['fee'] as num?)?.toDouble() ?? 20.0,
      );
}
