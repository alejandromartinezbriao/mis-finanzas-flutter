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
        title: const Text('Manual del Usuario'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildHeader('Guía de Uso de Mis Finanzas', titleColor),
              const SizedBox(height: 24),
              
              _buildSectionTitle('1. Conceptos Fundamentales', titleColor),
              _buildParagraph(
                'La aplicación está diseñada bajo tres pilares estratégicos:\n\n'
                '• Bimonetaria: Gestión nativa de Pesos (UYU) y Dólares (USD).\n'
                '• Arqueo Real: Comparación de saldos bancarios contra deudas actuales.\n'
                '• Reserva de Ahorros: Protección lógica de fondos destinados a metas.',
                textColor
              ),

              _buildSectionTitle('2. Panel de Control', titleColor),
              _buildParagraph(
                'Accede desde el menú de opciones (...) > Panel de Control. Antes de comenzar, configura tus bases:\n\n'
                '• Cuentas: Define tus bancos y billeteras. Mantén el saldo real actualizado para que el análisis de cobertura sea preciso.\n'
                '• Categorías: Personaliza tus tipos de gasto con iconos representativos.\n'
                '• Plantillas: Registra tus ingresos y gastos fijos para cargarlos automáticamente cada mes.',
                textColor
              ),

              _buildSectionTitle('3. Uso Diario', titleColor),
              _buildParagraph(
                'En la pantalla principal puedes registrar dos tipos de movimientos:\n\n'
                '• Movimientos Simples: Gastos o ingresos puntuales del mes.\n'
                '• Compras con Tarjeta: Registra el monto total y las cuotas; la app distribuirá el gasto en los meses futuros automáticamente.',
                textColor
              ),

              _buildSectionTitle('4. Metas y Ahorro', titleColor),
              _buildParagraph(
                'Desde la sección de Metas (icono bandera), puedes crear objetivos de ahorro. '
                'Al vincular una meta a una cuenta, el dinero asignado se mostrará como "Reservado", '
                'ayudándote a no gastar el dinero que ya has decidido ahorrar.',
                textColor
              ),

              _buildSectionTitle('5. Presupuestos y Estadísticas', titleColor),
              _buildParagraph(
                '• Presupuestos: Establece límites mensuales por categoría para evitar excederte.\n'
                '• Estadísticas: Analiza la evolución de tus finanzas en los últimos 6 meses con gráficos detallados.',
                textColor
              ),

              _buildSectionTitle('6. Exportación', titleColor),
              _buildParagraph(
                'Desde el menú de opciones (...), puedes exportar todos los movimientos del mes a un archivo CSV compatible con Excel para un análisis externo o respaldo.',
                textColor
              ),

              const Divider(height: 60),
              Center(
                child: Text(
                  'Si necesitas más ayuda, consulta la sección "Acerca de".',
                  style: TextStyle(color: textColor, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 40),
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
        fontSize: 24,
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
