import '../models/field_model.dart';

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
