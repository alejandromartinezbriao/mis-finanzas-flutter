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
}
