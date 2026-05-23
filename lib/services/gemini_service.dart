import 'dart:convert';
import 'package:dio/dio.dart';

class GeminiService {
  final Dio _dio = Dio();
  final String _base = 'https://us-central1-cuentaspersonales-36328.cloudfunctions.net';

  Future<Map<String, dynamic>?> analizarFinanzas({
    required double presupuestoTotal,
    required Map<String, dynamic> gastosPorCategoria,
    required Map<String, double> pagadoTotal,
    required Map<String, double> pendienteTotal,
    required Map<String, double> ingresoTotal,
    required List<String> cuentasActivas,
    List<Map<String, dynamic>>? suscripciones, // Nuevo
    Map<String, double>? saldosActuales,
    String? userName,
    double? tipoCambio,
  }) async {
    try {
      final response = await _dio.post(
        '$_base/analizarGastosMensuales',
        data: {
          'presupuestoTotal': presupuestoTotal,
          'gastos': gastosPorCategoria,
          'pagadoTotal': pagadoTotal,
          'pendienteTotal': pendienteTotal,
          'ingresoTotal': ingresoTotal,
          'cuentasActivas': cuentasActivas,
          'suscripciones': suscripciones,
          'saldosActuales': saldosActuales,
          'userName': userName,
          'tipoCambio': tipoCambio,
        },
      );
      return _processResponse(response);
    } catch (e) { return {'error': 'Error de conexión.'}; }
  }

  Future<Map<String, dynamic>?> analizarPlanificacion({
    required List<Map<String, dynamic>> presupuestos,
    required List<Map<String, dynamic>> ingresosPrevistos,
    required Map<String, double> saldosActuales,
    required Map<String, dynamic> gastosActuales, // Nuevo: Base real del mes
    List<Map<String, dynamic>>? suscripciones,
    String? userName,
  }) async {
    try {
      final response = await _dio.post(
        '$_base/analizarSostenibilidadPlan',
        data: {
          'presupuestos': presupuestos,
          'ingresosPrevistos': ingresosPrevistos,
          'saldosActuales': saldosActuales,
          'gastosActuales': gastosActuales,
          'suscripciones': suscripciones,
          'userName': userName,
        },
      );
      return _processResponse(response);
    } catch (e) { return {'error': 'Error de conexión estratégica.'}; }
  }

  Future<Map<String, dynamic>?> obtenerCotizacionDolar() async {
    try {
      final response = await _dio.get('$_base/obtenerCotizacionDolar');
      return _processResponse(response);
    } catch (e) { return null; }
  }

  Map<String, dynamic>? _processResponse(Response response) {
    if (response.statusCode == 200) {
      return response.data is String ? jsonDecode(response.data) : response.data;
    }
    return null;
  }
}
