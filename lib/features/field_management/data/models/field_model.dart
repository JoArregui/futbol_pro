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
    // Tolerante al shape del backend (id_campo/nombre/tarifa_horaria/capacidad)
    final rawType = (json['type'] ?? json['tipo'] ?? 'sevenVSeven').toString();
    return FieldModel(
      id: (json['id'] ?? json['id_campo'] ?? '').toString(),
      name: (json['name'] ?? json['nombre'] ?? 'Campo').toString(),
      address:
          (json['address'] ?? json['direccion'] ?? json['ubicacion'] ?? '')
              .toString(),
      hourlyRate: ((json['hourlyRate'] ?? json['tarifa_horaria'] ?? 0) as num)
          .toDouble(),
      type: FieldType.values.firstWhere(
        (e) => e.toString().split('.').last == rawType,
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
