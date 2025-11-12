import 'package:equatable/equatable.dart';

class Field extends Equatable {
  final String id;
  final String name;
  final String address;
  final double hourlyRate; 
  final FieldType type; 

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