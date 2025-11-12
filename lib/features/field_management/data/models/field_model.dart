import '../../domain/entities/field.dart';

class FieldModel extends Field {
  const FieldModel({
    required super.id,
    required super.name,
    required super.address,
    required super.hourlyRate,
    required super.type,
  });

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      type: FieldType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => FieldType.sevenVSeven,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'hourlyRate': hourlyRate,
      'type': type.toString().split('.').last,
    };
  }
}
