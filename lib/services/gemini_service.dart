import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // URL de la Cloud Function desplegada
  final String _url = 'https://analizargastosmensuales-cjiedaavia-uc.a.run.app';

  Future<Map<String, dynamic>?> analizarFinanzas({
    required double presupuestoTotal,
    required Map<String, double> gastosPorCategoria,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'presupuestoTotal': presupuestoTotal,
          'gastos': gastosPorCategoria,
        }),
      );

      if (response.statusCode == 200) {
        // Mapeamos el JSON exacto estructurado en la Cloud Function
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Error en el servidor de IA: ${response.statusCode} - ${response.body}');
        // Retornamos el cuerpo para ver si hay un mensaje de error útil
        try {
          return jsonDecode(response.body);
        } catch (_) {
          return {'error': 'Código de estado: ${response.statusCode}'};
        }
      }
    } catch (e) {
      print('Error de conexión al analizar finanzas: $e');
      return null;
    }
  }
}
