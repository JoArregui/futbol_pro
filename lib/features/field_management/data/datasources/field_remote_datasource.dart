import 'package:http/http.dart' as http;
import 'dart:convert'; // Necesario para jsonEncode y jsonDecode
import '../../../../core/errors/exceptions.dart';
import '../models/field_model.dart';

// 🟢 URL BASE REAL: Apuntando a tu servidor Node.js (Puerto 3000)
const String _kBaseUrl = 'http://10.0.2.2:3000/api/v1/fields'; 

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

  // ==================================================
  // OBTENER CAMPOS DISPONIBLES (GET a la API)
  // ==================================================
  @override
  Future<List<FieldModel>> getAvailableFields({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // 1. Convertir las fechas a formato ISO 8601 (UTC recomendado)
    final startIso = startTime.toUtc().toIso8601String();
    final endIso = endTime.toUtc().toIso8601String();
    
    // 2. Construir la URL con los parámetros de consulta
    final url = Uri.parse('$_kBaseUrl/available?start=$startIso&end=$endIso');

    try {
      final response = await client.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        // 3. Decodificar la respuesta y mapear a FieldModel
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => FieldModel.fromJson(json)).toList();
        
      } else if (response.statusCode == 404) {
        // La API devuelve 404 si no hay campos disponibles (según la lógica del backend)
        return []; 
      } else {
        // Manejar otros errores del servidor
        throw ServerException(message: 'Error al obtener campos: ${response.statusCode}');
      }
    } on Exception catch (e) {
      // Manejar errores de conexión de red
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }

  // ==================================================
  // RESERVAR CAMPO (POST a la API)
  // ==================================================
  @override
  Future<bool> reserveField({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
    required double totalCost,
  }) async {
    final url = Uri.parse('$_kBaseUrl/$fieldId/reserve');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // 1. Codificar el cuerpo de la petición con los detalles de la reserva
        body: jsonEncode({
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
          'userId': userId,
          'totalCost': totalCost,
        }),
      );

      if (response.statusCode == 201) { // 201 Created (Reserva exitosa)
        return true;
      } else if (response.statusCode == 409) {
        // 409 Conflict (El backend ya verificó que el campo está ocupado)
        throw const ServerException(message: 'El campo ya está reservado en ese horario.');
      } else {
        // Otros errores, como 400 Bad Request o 500 Internal Server Error
        throw ServerException(message: 'Error al reservar campo: ${response.statusCode}');
      }
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }
}