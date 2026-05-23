import 'dart:convert';
import 'package:dio/dio.dart';

class GeminiService {
  final String _url = 'https://analizargastosmensuales-cjiedaavia-uc.a.run.app';
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> analizarFinanzas({
    required double presupuestoTotal,
    required Map<String, dynamic> gastosPorCategoria,
    required Map<String, double> pagadoTotal,
    required Map<String, double> pendienteTotal,
    required Map<String, double> ingresoTotal,
    Map<String, double>? saldosActuales,
    String? userName,
  }) async {
    try {
      final response = await _dio.post(
        _url,
        data: {
          'presupuestoTotal': presupuestoTotal,
          'gastos': gastosPorCategoria,
          'pagadoTotal': pagadoTotal,
          'pendienteTotal': pendienteTotal,
          'ingresoTotal': ingresoTotal,
          'saldosActuales': saldosActuales,
          'userName': userName ?? 'Usuario',
          'tipoCambio': 43.0, // Valor de referencia para Uruguay
        },
      );

      if (response.statusCode == 200) {
        return response.data is String ? jsonDecode(response.data) : response.data;
      }
      return null;
    } catch (e) {
      print('Error en IA: $e');
      return {'error': 'Error de comunicación con el asesor.'};
    }
  }

  Future<Map<String, dynamic>?> obtenerCotizacionDolar() async {
    try {
      final response = await _dio.get('https://obtenercotizaciondolar-cjiedaavia-uc.a.run.app');
      if (response.statusCode == 200) {
        return response.data is String ? jsonDecode(response.data) : response.data;
      }
      return null;
    } catch (e) {
      print('Error cotización: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analizarPlanificacion({
    required List<Map<String, dynamic>> presupuestos,
    required List<Map<String, dynamic>> ingresosPrevistos,
    required Map<String, double> saldosActuales,
    String? userName,
  }) async {
    try {
      final response = await _dio.post(
        'https://analizarsostenibilidadplan-cjiedaavia-uc.a.run.app', // URL de la nueva función
        data: {
          'presupuestos': presupuestos,
          'ingresosPrevistos': ingresosPrevistos,
          'saldosActuales': saldosActuales,
          'userName': userName ?? 'Usuario',
        },
      );

      if (response.statusCode == 200) {
        return response.data is String ? jsonDecode(response.data) : response.data;
      }
      return null;
    } catch (e) {
      print('Error en IA Planificación: $e');
      return {'error': 'No se pudo conectar con el motor de estrategia.'};
    }
  }
}
