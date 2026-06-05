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
                          'Versión 3.7.8',
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
                  
                  _buildSection(
                    'Misión del Proyecto',
                    'Proporcionar una plataforma integral y eficiente para la administración de activos y pasivos personales, facilitando un control riguroso sobre la liquidez real y el cumplimiento de metas financieras a largo plazo.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    'Capacidades del Sistema v3.7',
                    '• Arquitectura SQLite-First: Funcionamiento instantáneo y modo offline total.\n'
                    '• Sincronización Granular: Botones de nube por sección y pull-to-refresh en dashboard.\n'
                    '• Estabilidad Visual: Soporte nativo ARGB para colores impecables.\n'
                    '• IDs Determinísticos: Prevención de duplicados en registros recurrentes.\n'
                    '• Herencia de identidad visual (icono/color) en nuevos registros.\n'
                    '• Registro Relámpago (Quick Actions) con iconos circulares premium.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    'Infraestructura y Seguridad',
                    'El sistema opera bajo un modelo híbrido donde el almacenamiento local garantiza la velocidad, mientras que la nube proporciona respaldo seguro y sincronización multiplataforma para usuarios Premium.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  
                  const Divider(height: 80),
                  
                  Center(
                    child: Text(
                      'Máxima precisión con la potencia de la nube.',
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
