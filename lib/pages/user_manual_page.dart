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
              _buildHeader('Guía Rápida de Uso', titleColor),
              const SizedBox(height: 8),
              Text(
                'Esta guía detalla dónde encontrar y cómo utilizar las funciones principales de la aplicación.',
                style: TextStyle(fontSize: 16, color: textColor, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('1. PANTALLA PRINCIPAL (Gestión Mensual)', titleColor),
              _buildParagraph(
                'Es el centro de operaciones diario:\n\n'
                '• Selector de Mes (Barra Superior): Flechas para navegar entre meses pasados (historial), el actual y futuros (proyecciones).\n'
                '• Cuadro de Cobertura (Arriba): Comparación visual de tu dinero disponible vs. deudas pendientes del mes.\n'
                '• Saldos de Cuentas: Visualización rápida del dinero real en tus bancos y billeteras.\n'
                '• Lista de Movimientos: Ingresos (Verde) y Gastos (Naranja).\n'
                '• Botón REGISTRAR MOVIMIENTO: Acceso rápido para crear Ingresos, Gastos o Compras con Tarjeta.',
                textColor
              ),

              _buildSectionTitle('2. CONFIGURACIÓN MAESTRA (Menú > Configuración)', titleColor),
              _buildParagraph(
                'Lugar para definir tu estructura financiera antes de empezar:\n\n'
                '• Pestaña Gastos / Tarjetas: Gestión de pagos fijos y tarjetas. Arrastra desde el icono de las flechas para reordenar.\n'
                '• Pestaña Ingresos: Gestión de sueldos o rentas fijas.\n'
                '• Pestaña Mis Cuentas: Registro de bancos (Santander, BROU, etc.) y efectivo.\n'
                '• Pestaña Categorías: Personalización de iconos y colores.\n'
                '• Pestaña Presupuestos: Configuración de topes de gasto mensuales.\n'
                '• Pestaña Metas: Creación de fondos de ahorro (ej. "Vacaciones").',
                textColor
              ),

              _buildSectionTitle('3. HERRAMIENTAS DE CONTROL', titleColor),
              _buildParagraph(
                'Ubicadas en el menú lateral o iconos de acceso directo:\n\n'
                '• Metas de Ahorro (Icono Bandera): Permite "reservar" dinero de una cuenta real para que no se cuente como disponible para gastos.\n'
                '• Estadísticas (Icono Gráfico): Evolución de los últimos 6 meses y reparto de gastos por categoría.\n'
                '• Presupuestos (Icono Barras): Control visual de cuánto has gastado frente al límite definido.\n'
                '• Exportación (Menú ... > Exportar): Descarga el mes actual en formato CSV (Excel).',
                textColor
              ),

              _buildSectionTitle('4. OPERACIONES CLAVE', titleColor),
              _buildParagraph(
                '• Carga Mensual: Al iniciar un nuevo mes, presiona "Cargar Plantillas" en el centro para traer tus gastos fijos automáticamente.\n'
                '• Pago Automático: Al marcar un gasto como "Completado" (check), la app descuenta el dinero de la cuenta elegida.\n'
                '• Ingreso Inteligente: Al crear un ingreso, elige la cuenta de destino para sumar el saldo automáticamente.\n'
                '• Compras en Cuotas: Indica el número de cuotas y la app las distribuirá en los meses correspondientes.',
                textColor
              ),

              _buildSectionTitle('5. TIPS DE CARGA DE DATOS', titleColor),
              _buildParagraph(
                '• Decimales: Utiliza siempre el punto (.) para separar decimales.\n'
                '• Símbolos: No escribas "\$" ni "U\$S", la app los asigna según la moneda.\n'
                '• Iconos: Pulsa sobre el icono de cualquier movimiento para cambiar su imagen o logo.',
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
