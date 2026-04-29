import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'export_platform_stub.dart'
    if (dart.library.io) 'export_platform_mobile.dart'
    if (dart.library.html) 'export_platform_web.dart';

class ExportUtils {
  static Future<void> exportToCSV(List<TransactionModel> transactions, String title) async {
    // BOM para Excel + Encabezados
    String csvData = '\uFEFFFecha,Concepto,Categoría,Monto,Moneda,Tipo,Estado\n';
    
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    for (var tx in transactions) {
      String date = dateFormat.format(tx.date);
      String concept = tx.title.replaceAll(',', ' ');
      String category = tx.category.replaceAll(',', ' ');
      String amount = tx.amount.toStringAsFixed(2);
      String currency = tx.currency;
      String type = tx.type == 'INCOME' ? 'Ingreso' : 'Gasto';
      String status = tx.isCompleted ? 'Completado' : 'Pendiente';
      
      csvData += '$date,$concept,$category,$amount,$currency,$type,$status\n';
    }

    final String fileName = 'reporte_${title.replaceAll(' ', '_')}.csv';
    
    // Llamada a la implementación específica de cada plataforma
    await saveAndDownload(csvData, fileName);
  }
}
