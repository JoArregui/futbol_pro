import 'package:equatable/equatable.dart';

class Field extends Equatable {
  final String id;
  final String name;
  final String address;
  final double hourlyRate; // Tarifa por hora
  final FieldType type; // 7v7, 11v11, etc.

  const Field({
    required this.id,
    required this.name,
    required this.address,
    required this.hourlyRate,
    required this.type,
  });

  @override
  List<Object> get props => [id, name, address, hourlyRate, type];
}

enum FieldType { sevenVSeven, elevenVEleven, fiveVSix }