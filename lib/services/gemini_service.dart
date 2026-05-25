import 'dart:convert';
import 'package:dio/dio.dart';

class GeminiService {
  final Dio _dio = Dio();
  final String _base = 'https://us-central1-cuentaspersonales-36328.cloudfunctions.net';

  /// Llama a la Auditoría Mensual Centralizada en el Servidor.
  /// La App ya no envía datos, el servidor los recolecta directamente.
  Future<Map<String, dynamic>?> analizarFinanzas({
    required String uid,
    required int month,
    required int year,
    required String userName,
  }) async {
    try {
      final response = await _dio.post(
        '$_base/analizarGastosMensuales',
        data: {
          'uid': uid,
          'month': month,
          'year': year,
          'userName': userName,
        },
      );
      return _processResponse(response);
    } catch (e) {
      print('Error en IA Mensual: $e');
      return {'error': 'Error de comunicación con el asesor central.'};
    }
  }

  /// Llama a la Planificación Estratégica Centralizada en el Servidor.
  Future<Map<String, dynamic>?> analizarPlanificacion({
    required String uid,
    required String userName,
  }) async {
    try {
      final response = await _dio.post(
        '$_base/analizarSostenibilidadPlan',
        data: {
          'uid': uid,
          'userName': userName,
        },
      );
      return _processResponse(response);
    } catch (e) {
      print('Error en IA Planificación: $e');
      return {'error': 'Error de comunicación estratégica.'};
    }
  }

  Future<Map<String, dynamic>?> obtenerCotizacionDolar() async {
    try {
      final response = await _dio.get('$_base/obtenerCotizacionDolar');
      return _processResponse(response);
    } catch (e) {
      print('Error cotización: $e');
      return null;
    }
  }

  Map<String, dynamic>? _processResponse(Response response) {
    if (response.statusCode == 200) {
      return response.data is String ? jsonDecode(response.data) : response.data;
    }
    return null;
  }
}
