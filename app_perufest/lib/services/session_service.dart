import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class SessionService {
  static const String _userIdKey = 'current_user_id';
  static const String _userNameKey = 'current_user_name';

  /// Guardar datos de sesión del usuario
  static Future<bool> guardarSesion(String userId, String userName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userNameKey, userName);
      return true;
    } catch (e) {
      print('Error al guardar sesión: $e');
      return false;
    }
  }

  /// Obtener ID del usuario actual
  static Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      print('Error al obtener user ID: $e');
      return null;
    }
  }

  /// Obtener nombre del usuario actual
  static Future<String?> getCurrentUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNameKey);
    } catch (e) {
      print('Error al obtener user name: $e');
      return null;
    }
  }

  /// Obtener usuario completo desde Firestore
  static Future<Usuario?> getCurrentUser() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Usuario.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario actual: $e');
      return null;
    }
  }

  /// Cerrar sesión
  static Future<bool> cerrarSesion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNameKey);
      return true;
    } catch (e) {
      print('Error al cerrar sesión: $e');
      return false;
    }
  }

  /// Verificar si hay una sesión activa
  static Future<bool> hayUsuarioLogueado() async {
    final userId = await getCurrentUserId();
    return userId != null && userId.isNotEmpty;
  }
}