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
        title: const Text('Manual del Usuario v2.0'),
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
                'Novedades y herramientas de gestión avanzada de la Versión 2.0.',
                style: TextStyle(fontSize: 16, color: textColor, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('1. PANTALLA PRINCIPAL (Gestión Temporal)', titleColor),
              _buildParagraph(
                '• Tarjeta de Cobertura Inteligente: \n'
                '  - Pasado: Muestra el Cierre de Mes (Superávit/Déficit real).\n'
                '  - Presente: Disponibilidad real vs deudas pendientes.\n'
                '  - Futuro: Proyecciones basadas en plantillas cargadas.\n'
                '• Saldos de Cuentas: Si ves un icono de ojo tachado, la cuenta está excluida del cálculo de cobertura.\n'
                '• Lista de Movimientos: Elimina registros deslizando hacia la DERECHA.',
                textColor
              ),

              _buildSectionTitle('2. MANTENIMIENTO E IA', titleColor),
              _buildParagraph(
                'Suite interactiva para tus datos y consejos inteligentes:\n\n'
                '• Asesor Financiero IA: Analiza tus gastos con Gemini y recibe alertas, detección de gastos altos y consejos de ahorro personalizados.\n'
                '• Normalizar Formatos: Elimina comas de miles en bloque para purificar tu base de datos (Paso inicial recomendado).\n'
                '• Corregir Error 100x: Detecta y corrige montos inflados por errores de coma mediante aprobación manual.\n'
                '• Sincronizar Cuotas: Compara series históricas y propone corregir montos discrepantes.\n'
                '• Reconexión Manual: Vincula gastos sueltos a sus plantillas para un mejor control histórico.\n'
                '• Reparación de Emergencia: Limpia consumos duplicados dentro de una misma tarjeta.\n'
                '• Recuperar Cuotas Perdidas: Restaura cuotas que faltan en meses pasados basándose en el futuro.\n'
                '• Unificación Global: Unifica variaciones de nombres de tarjetas o comercios en toda la historia.',
                textColor
              ),

              _buildSectionTitle('3. CONFIGURACIÓN Y AUTOMATIZACIÓN', titleColor),
              _buildParagraph(
                '• Tarjetas Bimonetarias: Al editar el vencimiento o logo en una parte (UYU/USD), se sincroniza su gemela automáticamente.\n'
                '• Suscripciones: Vincula pagos fijos directamente a tus tarjetas para carga automática mensual.\n'
                '• Control de Cobertura: Puedes apagar el switch "Considerar para Cobertura" en cuentas de ahorro para no sumarlas al dinero para gastos.\n'
                '• Presupuestos: Ahora incluyen un diálogo de confirmación para asegurar el guardado correcto.\n'
                '• Categorías: Personaliza iconos y colores para organizar tus gastos.\n'
                '• Metas de Ahorro: Reserva dinero de cuentas reales para objetivos específicos. El saldo se resta del "disponible" para evitar gastos accidentales.',
                textColor
              ),

              _buildSectionTitle('4. OPERACIONES CLAVE', titleColor),
              _buildParagraph(
                '• Pago en Efectivo: Al crear un gasto, elige "Pago en Efectivo (Sin cuenta)" para no afectar tus balances bancarios.\n'
                '• Inicio de Cuotas Flexible: Usa el campo "Cuota Próxima" al registrar una tarjeta para empezar desde donde te toca pagar ahora.\n'
                '• Instalación en iPhone: En Safari, usa "Añadir a pantalla de inicio" para activar el modo app nativa con logo personalizado.',
                textColor
              ),

              _buildSectionTitle('5. REGLAS DE ORO (Integridad de Datos)', titleColor),
              _buildParagraph(
                '• Punto Decimal Estricto: Usa siempre el punto (.) para decimales. La app convertirá las comas de tu teclado automáticamente.\n'
                '• Cero Comas de Miles: No uses comas para separar miles. La app las oculta visualmente para evitar errores aritméticos.',
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
