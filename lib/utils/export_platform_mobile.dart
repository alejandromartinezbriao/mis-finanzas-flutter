import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndDownload(String content, String fileName) async {
  Directory? directory;
  
  if (Platform.isAndroid) {
    // Intentar obtener la carpeta de descargas pública en Android
    directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      directory = await getExternalStorageDirectory();
    }
  } else {
    directory = await getApplicationDocumentsDirectory();
  }

  try {
    final file = File('${directory!.path}/$fileName');
    await file.writeAsString(content);
    
    // Aunque se guarde, en móvil solemos notificar o permitir compartir 
    // porque el usuario no siempre sabe navegar a la carpeta de la app.
    // Pero si ya se guardó en /Download, el usuario lo verá en sus descargas.
    
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte guardado en: ${file.path}');
  } catch (e) {
    // Si falla por permisos en Android 11+, caemos en el método temporal + share
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsString(content);
    await Share.shareXFiles([XFile(tempFile.path)], text: 'Exportar Reporte');
  }
}
