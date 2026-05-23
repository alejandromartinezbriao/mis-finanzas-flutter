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
        title: const Text('Manual del Usuario v3.0'),
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
                'Novedades y herramientas del Centro de Inteligencia Finanz-IA.',
                style: TextStyle(fontSize: 16, color: textColor, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('1. CENTRO DE INTELIGENCIA', titleColor),
              _buildParagraph(
                'Accede desde el menú principal para interactuar con Finanz-IA:\n\n'
                '• Cotización del Día: Informa el valor oficial del dólar en Uruguay para tus cálculos.\n'
                '• Auditoría Mensual: Analiza tu gasto real, detecta si usaste ahorros previos y calcula tu Finanz-Score.\n'
                '• Planificación Estratégica: Audita tus presupuestos vs tus ingresos fijos proyectados a 6 meses.\n'
                '• Historial: Consulta informes previos guardados con consistencia total.',
                textColor
              ),

              _buildSectionTitle('2. PANTALLA PRINCIPAL (Gestión Temporal)', titleColor),
              _buildParagraph(
                '• Tarjeta de Cobertura Inteligente: \n'
                '  - Pasado: Cierre de Mes (Superávit/Déficit real).\n'
                '  - Presente: Disponibilidad real vs deudas pendientes.\n'
                '  - Futuro: Proyecciones basadas en plantillas cargadas.\n'
                '• Saldos de Cuentas: Si ves un icono de ojo tachado, la cuenta está excluida del cálculo de cobertura.',
                textColor
              ),

              _buildSectionTitle('3. MANTENIMIENTO Y DATOS', titleColor),
              _buildParagraph(
                'Suite interactiva (Menú > Mantenimiento):\n\n'
                '• Normalizar Formatos: Elimina comas de miles en bloque.\n'
                '• Corregir Error 100x: Arregla montos inflados mediante aprobación manual.\n'
                '• Sincronizar Cuotas: Propone corregir montos discrepantes basándose en el historial.',
                textColor
              ),

              _buildSectionTitle('4. OPERACIONES CLAVE', titleColor),
              _buildParagraph(
                '• Pago en Efectivo: Al crear un gasto, elige "Pago en Efectivo (Sin cuenta)" para no afectar tus balances bancarios.\n'
                '• Tarjetas Bimonetarias: Al editar el vencimiento o logo en una parte (UYU/USD), se sincroniza su gemela automáticamente.\n'
                '• Inicio de Cuotas Flexible: Usa el campo "Cuota Próxima" al registrar una tarjeta para empezar desde donde te toca pagar ahora.',
                textColor
              ),

              _buildSectionTitle('5. REGLAS DE ORO (Integridad de Datos)', titleColor),
              _buildParagraph(
                '• Punto Decimal Estricto: Usa siempre el punto (.) para decimales. La app convertirá las comas de tu teclado automáticamente.\n'
                '• Cero Comas de Miles: No uses comas para separar miles para evitar errores aritméticos.',
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
