import 'package:flutter/material.dart';

class UserManualPage extends StatelessWidget {
  const UserManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor = isDark ? Colors.white : Colors.black;
    final Color textColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual del Usuario v3.7.8'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildHeader('Guía de Uso Profesional', titleColor),
              const SizedBox(height: 8),
              Text(
                'Arquitectura Soberanía Local: Rapidez y fiabilidad profesional.',
                style: TextStyle(fontSize: 16, color: textColor, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('1. SOBERANÍA LOCAL Y MODO OFFLINE', titleColor),
              _buildParagraph(
                '• Funcionamiento Instantáneo: Los datos se leen de la base de datos local (SQLite), garantizando máxima velocidad.\n'
                '• Modo Offline: Puedes registrar movimientos sin internet. La App los sincronizará con la nube automáticamente al detectar conexión.',
                textColor
              ),

              _buildSectionTitle('2. DASHBOARD Y MOVIMIENTOS', titleColor),
              _buildParagraph(
                '• Pull-to-Refresh: Tira hacia abajo en la lista principal para bajar tu historial de gastos reales del mes desde la nube.\n'
                '• Colores Dinámicos: Los gastos reflejan el color e icono actual definido en tu configuración de categorías.',
                textColor
              ),

              _buildSectionTitle('3. SOPORTE TÉCNICO PROFESIONAL', titleColor),
              _buildParagraph(
                '• Auditoría Remota: Si detectas inconsistencias en tus datos históricos, nuestro equipo puede realizar una auditoría de integridad remota para corregir errores de formato o duplicados sin que tengas que reinstalar la aplicación.',
                textColor
              ),

              _buildSectionTitle('4. OPERACIONES CLAVE', titleColor),
              _buildParagraph(
                '• Quick Actions: Mantén presionado el icono de la App para registros rápidos.\n'
                '• Arqueo de Cuentas: Gestiona tus saldos bancarios y de efectivo con total precisión.',
                textColor
              ),

              _buildSectionTitle('5. REGLAS DE ORO', titleColor),
              _buildParagraph(
                '• Punto Decimal: Usa siempre el punto (.) para decimales.\n'
                '• Sin Comas de Miles: No utilices comas para separar miles para evitar errores aritméticos.',
                textColor
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text, Color color) {
    return Text(text, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5));
  }

  Widget _buildSectionTitle(String text, Color color) {
    return Padding(padding: const EdgeInsets.only(top: 32.0, bottom: 12.0), child: Text(text.toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.2)));
  }

  Widget _buildParagraph(String text, Color color) {
    return Text(text, style: TextStyle(fontSize: 16, height: 1.6, color: color));
  }
}
