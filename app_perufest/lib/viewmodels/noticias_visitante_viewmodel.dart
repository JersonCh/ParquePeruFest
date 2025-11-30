import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/noticias.dart';
import '../services/noticias_service.dart';

class NoticiasVisitanteViewModel extends ChangeNotifier {
  final NoticiasService _noticiasService = NoticiasService();
  
  List<Noticia> _noticias = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String _errorMessage = '';
  String _filtroFecha = '';
  DocumentSnapshot? _ultimoDocumento;

  // Getters
  List<Noticia> get noticias => _noticias;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get errorMessage => _errorMessage;
  String get filtroFecha => _filtroFecha;

  /// Cargar noticias iniciales
  Future<void> cargarNoticias({bool limpiarLista = true}) async {
    if (limpiarLista) {
      _isLoading = true;
      _noticias.clear();
      _ultimoDocumento = null;
      _hasMore = true;
      notifyListeners();
    }

    try {
      final nuevasNoticias = await _noticiasService.getNoticiasPublicas(
        limite: 5,
        ultimoDocumento: _ultimoDocumento,
        filtroFecha: _filtroFecha.isEmpty ? null : _filtroFecha,
      );

      if (nuevasNoticias.isNotEmpty) {
        _noticias.addAll(nuevasNoticias);
        // Guardar referencia al último documento para paginación
        final snapshot = await FirebaseFirestore.instance
            .collection('noticias')
            .doc(nuevasNoticias.last.id)
            .get();
        _ultimoDocumento = snapshot;
        
        // Si obtuvimos menos de 5, no hay más
        _hasMore = nuevasNoticias.length == 5;
      } else {
        _hasMore = false;
      }

      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error al cargar noticias: $e';
      print('Error en cargarNoticias: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar más noticias (paginación)
  Future<void> cargarMasNoticias() async {
    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final nuevasNoticias = await _noticiasService.getNoticiasPublicas(
        limite: 5,
        ultimoDocumento: _ultimoDocumento,
        filtroFecha: _filtroFecha.isEmpty ? null : _filtroFecha,
      );

      if (nuevasNoticias.isNotEmpty) {
        _noticias.addAll(nuevasNoticias);
        
        // Actualizar último documento
        final snapshot = await FirebaseFirestore.instance
            .collection('noticias')
            .doc(nuevasNoticias.last.id)
            .get();
        _ultimoDocumento = snapshot;
        
        _hasMore = nuevasNoticias.length == 5;
      } else {
        _hasMore = false;
      }

      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Error al cargar más noticias: $e';
      print('Error en cargarMasNoticias: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Aplicar filtro de fecha
  Future<void> aplicarFiltroFecha(String filtro) async {
    _filtroFecha = filtro;
    await cargarNoticias(limpiarLista: true);
  }

  /// Limpiar filtros
  Future<void> limpiarFiltros() async {
    _filtroFecha = '';
    await cargarNoticias(limpiarLista: true);
  }

  /// Actualizar noticias
  Future<void> actualizarNoticias() async {
    await cargarNoticias(limpiarLista: true);
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}