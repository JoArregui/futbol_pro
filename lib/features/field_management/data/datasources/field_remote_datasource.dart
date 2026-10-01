import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/consts.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/booking.dart';
import '../models/field_model.dart';

String get _kBaseUrl => '${AppConsts.effectiveBaseUrl}/fields';

abstract class FieldRemoteDataSource {
  Future<List<FieldModel>> getAvailableFields(
      {required DateTime startTime, required DateTime endTime});
  Future<BookingInfo> reserveField({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
    String? paymentMethod,
  });
  Future<bool> confirmPago({required String pagoId, required String orderId});
  Future<List<BookingInfo>> misReservas();
}

class FieldRemoteDataSourceImpl implements FieldRemoteDataSource {
  final http.Client client;
  FieldRemoteDataSourceImpl({required this.client});

  @override
  Future<List<FieldModel>> getAvailableFields(
      {required DateTime startTime, required DateTime endTime}) async {
    final uri = Uri.parse('$_kBaseUrl/available').replace(queryParameters: {
      'start': startTime.toUtc().toIso8601String(),
      'end': endTime.toUtc().toIso8601String(),
    });
    try {
      final response =
          await client.get(uri, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((item) => FieldModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      if (response.statusCode == 404) return [];
      throw ServerException(
          message: _messageFromResponse(
              response, 'Error al obtener campos: ${response.statusCode}'));
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }

  @override
  Future<BookingInfo> reserveField({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
    String? paymentMethod,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$_kBaseUrl/$fieldId/reserve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
          'userId': userId,
          'paymentMethod': paymentMethod ?? 'paypal',
        }),
      );
      if (response.statusCode == 201) {
        return BookingInfo.fromJson(
            Map<String, dynamic>.from(jsonDecode(response.body) as Map));
      }
      if (response.statusCode == 409) {
        throw const ServerException(
            message: 'El campo ya está reservado en ese horario.');
      }
      if (response.statusCode == 403) {
        throw const ServerException(message: 'No tienes permiso.');
      }
      throw ServerException(
          message: _messageFromResponse(
              response, 'Error al reservar campo: ${response.statusCode}'));
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }

  @override
  Future<bool> confirmPago(
      {required String pagoId, required String orderId}) async {
    try {
      final response = await client.post(
        Uri.parse('$_kBaseUrl/pagos/$pagoId/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId}),
      );
      if (response.statusCode == 200) return true;
      throw ServerException(
          message: _messageFromResponse(
              response, 'Error al confirmar pago: ${response.statusCode}'));
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }

  @override
  Future<List<BookingInfo>> misReservas() async {
    try {
      final response = await client.get(Uri.parse('$_kBaseUrl/mis-reservas'),
          headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((item) =>
                BookingInfo.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      throw ServerException(
          message: _messageFromResponse(
              response, 'Error al obtener reservas: ${response.statusCode}'));
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }

  String _messageFromResponse(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map &&
          body['message'] is String &&
          (body['message'] as String).isNotEmpty) {
        return body['message'] as String;
      }
    } catch (_) {}
    return fallback;
  }
}
