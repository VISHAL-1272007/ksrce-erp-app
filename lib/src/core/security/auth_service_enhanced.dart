import '../data_service.dart';

class AuthServiceEnhanced {
  static String? get currentUserId => DataService().currentUserId;

  static String? get currentUserRole => DataService().currentRole;
}