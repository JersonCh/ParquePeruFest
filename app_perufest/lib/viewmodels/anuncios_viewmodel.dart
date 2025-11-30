import 'package:flutter/material.dart';
import 'dart:io';
import '../models/anuncio.dart';
import '../services/anuncios_service.dart';
import '../services/imgbb_service.dart';

class AnunciosViewModel extends ChangeNotifier {
  final AnunciosService _anunciosService = AnunciosService();

  List<Anuncio> _anuncios = [];
  bool _isLoading = false;
  String? _error;

  List<Anuncio> get anuncios => _anuncios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Inicializar y escuchar cambios
  void initialize() {
    print('🚀 Inicializando AnunciosViewModel...');
    try {
      _anunciosService.obtenerTodosLosAnuncios().listen(
        (anuncios) {
          print('📊 AnunciosViewModel - Recibidos ${anuncios.length} anuncios de Firebase');
          if (mounted) {
            _anuncios = anuncios;
            
            // Log detallado de anuncios
            for (var anuncio in anuncios) {
              final ahora = DateTime.now();
              final vigente = ahora.isAfter(anuncio.fechaInicio) && ahora.isBefore(anuncio.fechaFin);
              print('   📄 ${anuncio.titulo} - Activo: ${anuncio.activo}, Vigente: $vigente, Posición: ${anuncio.posicion}');
            }
            
            notifyListeners();
            print('🔄 AnunciosViewModel - Listeners notificados');
          } else {
            print('⚠️ AnunciosViewModel - Widget no montado, no se actualizó');
          }
        },
        onError: (error) {
          print('❌ AnunciosViewModel - Error en stream: $error');
          if (mounted) {
            _error = error.toString();
            notifyListeners();
          }
        },
      );
    } catch (e) {
      print('❌ AnunciosViewModel - Error al inicializar: $e');
      _error = 'Error al inicializar: $e';
      notifyListeners();
    }
  }

  // Verificar si el widget sigue montado
  bool get mounted => hasListeners;

  // Crear nuevo anuncio
  Future<bool> crearAnuncio({
    required String titulo,
    required String contenido,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String posicion,
    required String creadoPor,
    String? imagenPath,
  }) async {
    _setLoading(true);
    try {
      String? imagenUrl;
      
      // Subir imagen si se proporcionó
      if (imagenPath != null && imagenPath.isNotEmpty) {
        final imagenFile = File(imagenPath);
        imagenUrl = await ImgBBService.subirImagenPerfil(imagenFile, 'anuncio_${DateTime.now().millisecondsSinceEpoch}');
      }

      final orden = await _anunciosService.obtenerSiguienteOrden();
      
      final anuncio = Anuncio(
        id: '', // Se asigna automáticamente por Firestore
        titulo: titulo,
        contenido: contenido,
        imagenUrl: imagenUrl,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        posicion: posicion,
        activo: true,
        orden: orden,
        fechaCreacion: DateTime.now(),
        creadoPor: creadoPor,
      );

      await _anunciosService.crearAnuncio(anuncio);
      _clearError();
      return true;
    } catch (e) {
      _setError('Error al crear anuncio: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar anuncio existente
  Future<bool> actualizarAnuncio({
    required String anuncioId,
    required String titulo,
    required String contenido,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String posicion,
    String? nuevaImagenPath,
    String? imagenUrlActual,
  }) async {
    _setLoading(true);
    try {
      String? imagenUrl = imagenUrlActual;
      
      // Subir nueva imagen si se proporcionó
      if (nuevaImagenPath != null && nuevaImagenPath.isNotEmpty) {
        final imagenFile = File(nuevaImagenPath);
        imagenUrl = await ImgBBService.subirImagenPerfil(imagenFile, 'anuncio_${DateTime.now().millisecondsSinceEpoch}');
      }

      final anuncioOriginal = _anuncios.firstWhere((a) => a.id == anuncioId);
      final anuncioActualizado = anuncioOriginal.copyWith(
        titulo: titulo,
        contenido: contenido,
        imagenUrl: imagenUrl,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        posicion: posicion,
      );

      await _anunciosService.actualizarAnuncio(anuncioActualizado);
      _clearError();
      return true;
    } catch (e) {
      _setError('Error al actualizar anuncio: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar anuncio
  Future<bool> eliminarAnuncio(String anuncioId) async {
    _setLoading(true);
    try {
      await _anunciosService.eliminarAnuncio(anuncioId);
      _clearError();
      return true;
    } catch (e) {
      _setError('Error al eliminar anuncio: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cambiar estado activo/inactivo
  Future<bool> cambiarEstadoAnuncio(String anuncioId, bool nuevoEstado) async {
    try {
      await _anunciosService.cambiarEstadoAnuncio(anuncioId, nuevoEstado);
      _clearError();
      return true;
    } catch (e) {
      _setError('Error al cambiar estado: ${e.toString()}');
      return false;
    }
  }

  // Obtener anuncios activos por posición
  Stream<List<Anuncio>> obtenerAnunciosActivos({String? posicion}) {
    return _anunciosService.obtenerAnunciosActivos(posicion: posicion);
  }

  // Obtener anuncios para una zona específica (para anuncios compactos)
  Future<List<Anuncio>> obtenerAnunciosParaZona(String zona) async {
    print('🔍 Obteniendo anuncios para zona: $zona');
    try {
      // Filtrar anuncios activos y válidos para la zona
      final ahora = DateTime.now();
      print('📅 Fecha actual: $ahora');
      print('📊 Total anuncios disponibles: ${_anuncios.length}');
      
      final anunciosActivos = _anuncios.where((anuncio) {
        final vigente = anuncio.fechaInicio.isBefore(ahora) && anuncio.fechaFin.isAfter(ahora);
        final zonaValida = (anuncio.posicion == 'general' || anuncio.posicion == zona);
        final cumpleCondiciones = anuncio.activo && vigente && zonaValida;
        
        print('   📄 ${anuncio.titulo}:');
        print('      - Activo: ${anuncio.activo}');
        print('      - Vigente: $vigente (${anuncio.fechaInicio} - ${anuncio.fechaFin})');
        print('      - Zona válida: $zonaValida (${anuncio.posicion} vs $zona)');
        print('      - Cumple condiciones: $cumpleCondiciones');
        
        return cumpleCondiciones;
      }).toList();
      
      print('✅ Anuncios filtrados para zona $zona: ${anunciosActivos.length}');
      
      // Ordenar por orden configurado
      anunciosActivos.sort((a, b) => a.orden.compareTo(b.orden));
      return anunciosActivos;
    } catch (e) {
      print('❌ Error obteniendo anuncios para zona $zona: $e');
      return [];
    }
  }

  // Método para obtener anuncios con límite (para evitar saturación)
  Future<List<Anuncio>> obtenerAnunciosLimitados({
    String? zona,
    int limite = 3,
  }) async {
    try {
      final anuncios = zona != null 
          ? await obtenerAnunciosParaZona(zona)
          : _anuncios.where((a) => a.activo).toList();
      
      return anuncios.take(limite).toList();
    } catch (e) {
      print('Error obteniendo anuncios limitados: $e');
      return [];
    }
  }

  // Métodos auxiliares
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}