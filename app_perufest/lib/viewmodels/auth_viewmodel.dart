import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../services/firestore_service.dart';
import '../services/session_service.dart';  // ← AGREGAR ESTA LÍNEA
import 'package:bcrypt/bcrypt.dart';

enum AuthState { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthState _state = AuthState.idle;
  String _errorMessage = '';
  Usuario? _currentUser;

  AuthState get state => _state;
  String get errorMessage => _errorMessage;
  Usuario? get currentUser => _currentUser;
  bool get isLoading => _state == AuthState.loading;
  bool get isLoggedIn => _currentUser != null;

  // ← AGREGAR ESTE MÉTODO para inicializar desde sesión guardada
  Future<void> initializeFromSession() async {
    try {
      final hayUsuarioLogueado = await SessionService.hayUsuarioLogueado();
      if (hayUsuarioLogueado) {
        final usuario = await SessionService.getCurrentUser();
        if (usuario != null) {
          _currentUser = usuario;
          _setState(AuthState.success);
          if (kDebugMode) {
            debugPrint('✅ Sesión restaurada: ${usuario.nombre}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al restaurar sesión: $e');
      }
    }
  }

  Future<void> registrar({
    required String nombre,
    required String username,
    required String correo,
    required String telefono,
    required String rol,
    required String contrasena,
  }) async {
    if (_state == AuthState.loading) return;

    _setState(AuthState.loading);

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final correoExiste = await FirestoreService.correoExiste(correo);
      if (correoExiste) {
        _setError('El correo ya está registrado');
        return;
      }

      final contrasenaEncriptada = BCrypt.hashpw(contrasena, BCrypt.gensalt());

      final usuario = Usuario(
        id: '',
        nombre: nombre,
        username: username,
        correo: correo,
        telefono: telefono,
        rol: rol,
        contrasena: contrasenaEncriptada,
      );

      await FirestoreService.registrarUsuario(usuario);

      _setState(AuthState.success);
      if (kDebugMode) {
        debugPrint('Usuario registrado exitosamente: $correo');
      }
    } catch (e) {
      _setError('Error al registrar usuario');
      if (kDebugMode) {
        debugPrint('Error al registrar usuario: $e');
      }
    }
  }

  Future<void> login(String correo, String contrasena) async {
    if (_state == AuthState.loading) return;

    _setState(AuthState.loading);

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final usuario = await FirestoreService.loginUsuario(correo, contrasena);

      if (usuario != null) {
        _currentUser = usuario;
        
        // ← GUARDAR SESIÓN EN SHARED PREFERENCES
        await SessionService.guardarSesion(usuario.id, usuario.nombre);
        
        _setState(AuthState.success);
        if (kDebugMode) {
          debugPrint('✅ Login exitoso para: ${usuario.nombre} (ID: ${usuario.id})');
        }
      } else {
        _setError('Credenciales incorrectas');
      }
    } catch (e) {
      _setError('Error al hacer login');
      if (kDebugMode) {
        debugPrint('Error al hacer login: $e');
      }
    }
  }

  Future<void> logout() async {
    // ← LIMPIAR SESIÓN DE SHARED PREFERENCES
    await SessionService.cerrarSesion();
    
    _currentUser = null;
    _setState(AuthState.idle);
    if (kDebugMode) {
      debugPrint('✅ Usuario deslogueado y sesión limpiada');
    }
  }

  Future<void> actualizarUsuario() async {
    if (_currentUser == null) return;

    try {
      final usuarioActualizado = await FirestoreService.obtenerUsuarioPorId(_currentUser!.id);
      if (usuarioActualizado != null) {
        _currentUser = usuarioActualizado;
        
        // ← ACTUALIZAR TAMBIÉN EN SHARED PREFERENCES
        await SessionService.guardarSesion(usuarioActualizado.id, usuarioActualizado.nombre);
        
        notifyListeners();
        if (kDebugMode) {
          debugPrint('Datos del usuario actualizados: ${usuarioActualizado.nombre}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al actualizar datos del usuario: $e');
      }
    }
  }

  void resetState() {
    _setState(AuthState.idle);
  }

  void _setState(AuthState newState) {
    _state = newState;
    if (newState != AuthState.error) {
      _errorMessage = '';
    }
    notifyListeners();
  }

  void _setError(String message) {
    _state = AuthState.error;
    _errorMessage = message;
    notifyListeners();
  }
}