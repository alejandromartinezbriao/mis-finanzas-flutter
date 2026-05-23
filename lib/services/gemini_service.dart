import 'dart:convert';
import 'package:dio/dio.dart';

class GeminiService {
  final String _url = 'https://analizargastosmensuales-cjiedaavia-uc.a.run.app';
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> analizarFinanzas({
    required double presupuestoTotal,
    required Map<String, dynamic> gastosPorCategoria,
  }) async {
    try {
      final response = await _dio.post(
        _url,
        data: {
          'presupuestoTotal': presupuestoTotal,
          'gastos': gastosPorCategoria,
        },
      );

      if (response.statusCode == 200) {
        return response.data is String ? jsonDecode(response.data) : response.data;
      }
      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
