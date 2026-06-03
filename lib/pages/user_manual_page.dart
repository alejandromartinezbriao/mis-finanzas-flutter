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
        title: const Text('Manual del Usuario v3.7.0'),
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
                'Arquitectura Soberanía Local: Rapidez y fiabilidad de un Reloj Suizo.',
                style: TextStyle(fontSize: 16, color: textColor, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('1. SOBERANÍA LOCAL Y MODO OFFLINE', titleColor),
              _buildParagraph(
                '• Funcionamiento Instantáneo: Los datos se leen de la base de datos local (SQLite), garantizando que la App nunca se "trabe" esperando a la nube.\n'
                '• Modo Avión: Puedes registrar cualquier movimiento sin internet. La App lo guardará localmente y lo subirá a Firebase en cuanto detecte conexión.\n'
                '• Sincronización Granular: En el Panel de Control encontrarás botones de nube individuales para bajar tus categorías, cuentas y plantillas solo cuando tú lo decidas.',
                textColor
              ),

              _buildSectionTitle('2. DASHBOARD Y MOVIMIENTOS', titleColor),
              _buildParagraph(
                '• Pull-to-Refresh: Tira hacia abajo en la lista principal para bajar tu historial de gastos reales del mes desde la nube.\n'
                '• Colores Dinámicos: Los gastos en el dashboard reflejan siempre el color e icono actual que tengas definido en tu configuración de categorías.\n'
                '• Agrupación de Tarjetas: Las compras con tarjeta se suman inteligentemente al total de la tarjeta correspondiente, evitando filas duplicadas innecesarias.',
                textColor
              ),

              _buildSectionTitle('3. CENTRO DE INTELIGENCIA IA', titleColor),
              _buildParagraph(
                '• Auditoría de Ahorros: Finanz-IA detecta si tus gastos están erosionando tu patrimonio.\n'
                '• Planificación a 6 meses: Análisis bimonetario (UYU/USD) proyectado según tus presupuestos actuales.',
                textColor
              ),

              _buildSectionTitle('4. OPERACIONES CLAVE', titleColor),
              _buildParagraph(
                '• Quick Actions: Mantén presionado el icono de la App para registrar un gasto rápido sin entrar al menú principal.\n'
                '• Arqueo de Cuentas: Gestiona tus saldos bancarios y de efectivo con total precisión.',
                textColor
              ),

              _buildSectionTitle('5. REGLAS DE ORO (Integridad)', titleColor),
              _buildParagraph(
                '• Punto Decimal: Usa siempre el punto (.) para decimales. La app convertirá las comas automáticamente.\n'
                '• Sin Comas de Miles: No utilices comas para separar miles; el sistema maneja la aritmética de forma exacta sin ellas.',
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
    return Text(
      text,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSectionTitle(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, bottom: 12.0),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        height: 1.6,
        color: color,
      ),
    );
  }
}
