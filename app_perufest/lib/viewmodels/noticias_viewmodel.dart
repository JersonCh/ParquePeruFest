import 'package:flutter/material.dart';
import 'dart:io';
import '../models/noticias.dart';
import '../services/noticias_service.dart';
import '../services/session_service.dart';
import '../services/imgbb_service.dart';

class NoticiasViewModel extends ChangeNotifier {
  final NoticiasService _noticiasService = NoticiasService();
  
  List<Noticia> _noticias = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<Noticia> get noticias => _noticias;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Stream de noticias del usuario actual
  Stream<List<Noticia>> get noticiasStream async* {
    final userId = await SessionService.getCurrentUserId();
    if (userId != null) {
      yield* _noticiasService.getNoticiasByAutor(userId);
    } else {
      yield [];
    }
  }

  /// Crear nueva noticia
  Future<bool> crearNoticia({
    required String titulo,
    required String textoCorto,
    required String descripcion,
    File? imagenFile,
    String? enlaceExterno,
  }) async {
    _setLoading(true);
    
    try {
      // Obtener datos del usuario actual
      final autorId = await SessionService.getCurrentUserId();
      final autorNombre = await SessionService.getCurrentUserName();

      if (autorId == null || autorNombre == null) {
        _setError('No se pudo obtener la información del usuario');
        return false;
      }

      String? imagenUrl;

      // Subir imagen si se proporcionó
      if (imagenFile != null) {
        try {
          imagenUrl = await ImgBBService.subirImagenFormData(imagenFile);
          if (imagenUrl == null) {
            _setError('Error al subir la imagen');
            return false;
          }
        } catch (e) {
          _setError('Error al subir imagen: $e');
          return false;
        }
      }

      final success = await _noticiasService.crearNoticia(
        titulo: titulo,
        textoCorto: textoCorto,
        descripcion: descripcion,
        imagenUrl: imagenUrl,
        enlaceExterno: enlaceExterno,
        autorId: autorId,
        autorNombre: autorNombre,
      );

      if (success) {
        _setError('');
      } else {
        _setError('Error al crear la noticia');
      }

      return success;
    } catch (e) {
      _setError('Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Actualizar noticia
  Future<bool> actualizarNoticia({
    required String id,
    required String titulo,
    required String textoCorto,
    required String descripcion,
    File? imagenFile,
    String? imagenUrlActual,
    String? enlaceExterno,
  }) async {
    _setLoading(true);
    
    try {
      String? imagenUrl = imagenUrlActual;

      // Subir nueva imagen si se proporcionó
      if (imagenFile != null) {
        try {
          imagenUrl = await ImgBBService.subirImagenFormData(imagenFile);
          if (imagenUrl == null) {
            _setError('Error al subir la nueva imagen');
            return false;
          }
        } catch (e) {
          _setError('Error al subir imagen: $e');
          return false;
        }
      }

      final datos = {
        'titulo': titulo,
        'textoCorto': textoCorto,
        'descripcion': descripcion,
        'imagenUrl': imagenUrl,
        'enlaceExterno': enlaceExterno,
      };

      final success = await _noticiasService.actualizarNoticia(id, datos);
      
      if (success) {
        _setError('');
      } else {
        _setError('Error al actualizar la noticia');
      }

      return success;
    } catch (e) {
      _setError('Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Eliminar noticia
  Future<bool> eliminarNoticia(String id) async {
    _setLoading(true);
    
    try {
      final success = await _noticiasService.eliminarNoticia(id);
      
      if (success) {
        _setError('');
      } else {
        _setError('Error al eliminar la noticia');
      }

      return success;
    } catch (e) {
      _setError('Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}