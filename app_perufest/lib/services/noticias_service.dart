import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/noticias.dart';
import 'timezone_service.dart';

class NoticiasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'noticias';

  /// Obtener todas las noticias ordenadas por fecha
  Stream<List<Noticia>> getNoticias() {
    return _firestore
        .collection(_collection)
        .orderBy('fechaPublicacion', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Noticia.fromFirestore(doc)).toList());
  }

  /// Obtener noticias de un autor específico
  Stream<List<Noticia>> getNoticiasByAutor(String autorId) {
    return _firestore
        .collection(_collection)
        .where('autorId', isEqualTo: autorId)
        .orderBy('fechaPublicacion', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Noticia.fromFirestore(doc)).toList());
  }

  /// Crear nueva noticia
  Future<bool> crearNoticia({
    required String titulo,
    required String textoCorto,
    required String descripcion,
    String? imagenUrl,
    String? enlaceExterno,
    required String autorId,
    required String autorNombre,
  }) async {
    try {
      final noticia = Noticia(
        id: '',
        titulo: titulo,
        textoCorto: textoCorto,
        descripcion: descripcion,
        imagenUrl: imagenUrl,
        enlaceExterno: enlaceExterno,
        fechaPublicacion: TimezoneService.nowInPeru(),
        autorId: autorId,
        autorNombre: autorNombre,
      );

      await _firestore.collection(_collection).add(noticia.toFirestore());
      return true;
    } catch (e) {
      print('Error al crear noticia: $e');
      return false;
    }
  }

  /// Actualizar noticia existente
  Future<bool> actualizarNoticia(String id, Map<String, dynamic> datos) async {
    try {
      await _firestore.collection(_collection).doc(id).update(datos);
      return true;
    } catch (e) {
      print('Error al actualizar noticia: $e');
      return false;
    }
  }

  /// Eliminar noticia
  Future<bool> eliminarNoticia(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error al eliminar noticia: $e');
      return false;
    }
  }

  /// Obtener noticia por ID
  Future<Noticia?> getNoticiaPorId(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Noticia.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error al obtener noticia: $e');
      return null;
    }
  }

  Future<List<Noticia>> getNoticiasPublicas({
    int limite = 5,
    DocumentSnapshot? ultimoDocumento,
    String? filtroFecha,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('fechaPublicacion', descending: true);

      // Aplicar filtro de fecha si se especifica
      if (filtroFecha != null && filtroFecha.isNotEmpty) {
        DateTime fechaFiltro;
        final now = DateTime.now();
        
        switch (filtroFecha) {
          case 'hoy':
            fechaFiltro = DateTime(now.year, now.month, now.day);
            query = query.where('fechaPublicacion', 
                isGreaterThanOrEqualTo: Timestamp.fromDate(fechaFiltro));
            break;
          case 'semana':
            fechaFiltro = now.subtract(const Duration(days: 7));
            query = query.where('fechaPublicacion', 
                isGreaterThanOrEqualTo: Timestamp.fromDate(fechaFiltro));
            break;
          case 'mes':
            fechaFiltro = DateTime(now.year, now.month - 1, now.day);
            query = query.where('fechaPublicacion', 
                isGreaterThanOrEqualTo: Timestamp.fromDate(fechaFiltro));
            break;
        }
      }

      // Aplicar paginación
      if (ultimoDocumento != null) {
        query = query.startAfterDocument(ultimoDocumento);
      }

      query = query.limit(limite);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Noticia.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error al obtener noticias públicas: $e');
      return [];
    }
  }

}