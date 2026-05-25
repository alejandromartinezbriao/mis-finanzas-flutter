import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Paleta simplificada: Blanco para modo oscuro, Negro para modo claro.
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de Mis Finanzas'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera Centrada
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 80,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Mis Finanzas',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'Versión 3.0.1',
                          style: TextStyle(
                            fontSize: 16,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  
                  // Secciones alineadas a la izquierda
                  _buildSection(
                    'Misión del Proyecto',
                    'Proporcionar una plataforma integral y eficiente para la administración de activos y pasivos personales, facilitando un control riguroso sobre la liquidez real y el cumplimiento de metas financieras a largo plazo.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    'Capacidades del Sistema v3.0',
                    '• Centro de Inteligencia Finanz-IA con personalidad personalizada.\n'
                    '• Integración en tiempo real con cotización oficial del dólar.\n'
                    '• Auditoría bimonetaria con detección de erosión de ahorro.\n'
                    '• Planificación estratégica con proyecciones a 6 meses.\n'
                    '• Caché inteligente para consistencia absoluta de informes.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    'Infraestructura y Seguridad',
                    'La arquitectura del sistema utiliza servicios de alta disponibilidad en la nube para garantizar la integridad y persistencia de la información, permitiendo el acceso multiplataforma bajo estándares de seguridad corporativa.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                  const Divider(height: 80),
                  
                  Center(
                    child: Text(
                      'Solución desarrollada para optimizar la gestión económica y promover una salud financiera sostenible.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, Color titleColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: titleColor,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: textColor,
          ),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }
}
