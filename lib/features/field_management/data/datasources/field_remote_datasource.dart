import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';
import '../models/field_model.dart';

const String baseUrlFieldManagement =
    'https://tu-api-backend.com/api/v1/fields';

abstract class FieldRemoteDataSource {
  Future<List<FieldModel>> getAvailableFields({
    required DateTime startTime,
    required DateTime endTime,
  });

  Future<bool> reserveField({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
    required double totalCost,
  });
}

class FieldRemoteDataSourceImpl implements FieldRemoteDataSource {
  final http.Client client;

  FieldRemoteDataSourceImpl({required this.client});

  @override
  Future<List<FieldModel>> getAvailableFields({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final mockData = [
      {
        "id": "field-A",
        "name": "Cancha Estelar A",
        "hourlyRate": 35.0,
        "capacity": 10
      },
      {
        "id": "field-B",
        "name": "Cancha Rápida B",
        "hourlyRate": 25.0,
        "capacity": 8
      }
    ];

    // Nota: Aquí en un entorno real usarías el cliente HTTP:
    // final uri = Uri.parse('$baseUrlFieldManagement/available?start=${startTime.toIso8601String()}&end=${endTime.toIso8601String()}');
    // final response = await client.get(uri, headers: {'Content-Type': 'application/json'});
    // ... manejo de la respuesta ...

    return mockData.map((json) => FieldModel.fromJson(json)).toList();
  }

  @override
  Future<bool> reserveField({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
    required double totalCost,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (fieldId.isEmpty) {
      throw const ServerException(
          message: 'El ID del campo no puede estar vacío.');
    }

    return true;
  }
}
