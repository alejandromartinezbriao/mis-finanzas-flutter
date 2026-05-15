import 'firebase/firebase_base.dart';
import 'firebase/user_service.dart';
import 'firebase/balance_service.dart';
import 'firebase/category_service.dart';
import 'firebase/transaction_service.dart';
import 'firebase/template_service.dart';
import 'firebase/goal_service.dart';
import 'firebase/subscription_service.dart';
import 'firebase/transfer_service.dart';
import 'firebase/maintenance_service.dart';

class FirebaseService extends FirebaseBase 
    with UserService, 
         BalanceService, 
         CategoryService, 
         TransactionService, 
         TemplateService, 
         GoalService, 
         SubscriptionService, 
         TransferService,
         MaintenanceService {
  
  // Singleton para asegurar que toda la app use la misma instancia
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
}
