import 'package:cloud_firestore/cloud_firestore.dart';

class TimezoneService {
  // Perú está en UTC-5
  static const int peruOffsetHours = -5;
  
  /// Convierte una fecha UTC a hora de Perú
  static DateTime utcToPeru(DateTime utcDateTime) {
    return utcDateTime.add(Duration(hours: peruOffsetHours));
  }
  
  /// Obtiene la fecha/hora actual en zona horaria de Perú
  static DateTime nowInPeru() {
    return utcToPeru(DateTime.now().toUtc());
  }
  
  /// Convierte Timestamp de Firestore a hora de Perú
  static DateTime timestampToPeru(dynamic timestamp) {
    if (timestamp == null) return nowInPeru();
    
    DateTime utcDateTime;
    if (timestamp is Timestamp) {
      utcDateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      utcDateTime = timestamp.toUtc();
    } else {
      return nowInPeru();
    }
    
    return utcToPeru(utcDateTime);
  }
}