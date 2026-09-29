import 'package:http/http.dart' as http;
import 'dart:convert'; // Necesario para jsonEncode y jsonDecode
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/booking.dart';
import '../models/field_model.dart';

import '../../../../core/consts.dart';
final String _kBaseUrl = '${AppConsts.effectiveBaseUrl}/fields';

abstract class FieldRemoteDataSource {
  Future<List<FieldModel>> getAvailableFields({
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Reserva y devuelve la economía (total servidor + seña + pago).
  Future<BookingInfo> reserveField({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
  });

  /// Captura y verifica la orden PayPal en el servidor.
  Future<bool> confirmPago({required String pagoId, required String orderId});

  Future<List<BookingInfo>> misReservas();
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
  // El coste lo calcula el servidor; aquí solo viaja el rango horario.
  // ==================================================
  @override
  Future<BookingInfo> reserveField({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
  }) async {
    final url = Uri.parse('$_kBaseUrl/$fieldId/reserve');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
          'userId': userId,
        }),
      );

      if (response.statusCode == 201) {
        return BookingInfo.fromJson(
            Map<String, dynamic>.from(jsonDecode(response.body) as Map));
      } else if (response.statusCode == 409) {
        throw const ServerException(
            message: 'El campo ya está reservado en ese horario.');
      } else if (response.statusCode == 403) {
        throw const ServerException(message: 'No tienes permiso.');
      } else {
        throw ServerException(
            message: 'Error al reservar campo: ${response.statusCode}');
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }

  @override
  Future<bool> confirmPago({required String pagoId, required String orderId}) async {
    try {
      final response = await client.post(
        Uri.parse('$_kBaseUrl/pagos/$pagoId/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId}),
      );
      if (response.statusCode == 200) return true;
      throw ServerException(
          message: 'Error al confirmar pago: ${response.statusCode}');
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }

  @override
  Future<List<BookingInfo>> misReservas() async {
    try {
      final response = await client.get(
          Uri.parse('$_kBaseUrl/mis-reservas'),
          headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list
            .map((j) =>
                BookingInfo.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
      }
      throw ServerException(
          message: 'Error al obtener reservas: ${response.statusCode}');
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }
}
