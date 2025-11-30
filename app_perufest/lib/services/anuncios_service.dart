import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/anuncio.dart';

class AnunciosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'anuncios';

  // Obtener todos los anuncios (para admin)
  Stream<List<Anuncio>> obtenerTodosLosAnuncios() {
    try {
      return _firestore
          .collection(_collection)
          .orderBy('fechaCreacion', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                try {
                  return Anuncio.fromFirestore(doc);
                } catch (e) {
                  debugPrint('Error al procesar anuncio ${doc.id}: $e');
                  return null;
                }
              })
              .where((anuncio) => anuncio != null)
              .cast<Anuncio>()
              .toList())
          .handleError((error) {
            debugPrint('Error en stream de anuncios: $error');
          });
    } catch (e) {
      debugPrint('Error al obtener anuncios: $e');
      return Stream.value(<Anuncio>[]);
    }
  }

  // Obtener anuncios activos y vigentes (para usuarios)
  Stream<List<Anuncio>> obtenerAnunciosActivos({String? posicion}) {
    try {
      // Consulta simple solo por 'activo' para evitar índices compuestos
      return _firestore
          .collection(_collection)
          .where('activo', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            final ahora = DateTime.now();
            
            List<Anuncio> anuncios = snapshot.docs
                .map((doc) {
                  try {
                    return Anuncio.fromFirestore(doc);
                  } catch (e) {
                    debugPrint('Error al procesar anuncio ${doc.id}: $e');
                    return null;
                  }
                })
                .where((anuncio) => anuncio != null)
                .cast<Anuncio>()
                .where((anuncio) => 
                    ahora.isAfter(anuncio.fechaInicio) && 
                    ahora.isBefore(anuncio.fechaFin))
                .toList();

            // Filtrar por posición si se especifica
            if (posicion != null) {
              anuncios = anuncios.where((anuncio) => anuncio.posicion == posicion).toList();
            }
            
            // Ordenar por orden en memoria
            anuncios.sort((a, b) => a.orden.compareTo(b.orden));
            
            return anuncios;
          })
          .handleError((error) {
            debugPrint('Error en stream de anuncios activos: $error');
          });
    } catch (e) {
      debugPrint('Error al obtener anuncios activos: $e');
      return Stream.value(<Anuncio>[]);
    }
  }

  // Crear anuncio
  Future<void> crearAnuncio(Anuncio anuncio) async {
    try {
      await _firestore.collection(_collection).add(anuncio.toFirestore());
    } catch (e) {
      throw Exception('Error al crear anuncio: $e');
    }
  }

  // Actualizar anuncio
  Future<void> actualizarAnuncio(Anuncio anuncio) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(anuncio.id)
          .update(anuncio.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar anuncio: $e');
    }
  }

  // Eliminar anuncio
  Future<void> eliminarAnuncio(String anuncioId) async {
    try {
      await _firestore.collection(_collection).doc(anuncioId).delete();
    } catch (e) {
      throw Exception('Error al eliminar anuncio: $e');
    }
  }

  // Cambiar estado activo/inactivo
  Future<void> cambiarEstadoAnuncio(String anuncioId, bool nuevoEstado) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(anuncioId)
          .update({'activo': nuevoEstado});
    } catch (e) {
      throw Exception('Error al cambiar estado del anuncio: $e');
    }
  }

  // Obtener siguiente número de orden
  Future<int> obtenerSiguienteOrden() async {
    try {
      // Obtener todos los anuncios y calcular el orden en memoria para evitar índices
      final snapshot = await _firestore
          .collection(_collection)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return 1;
      }
      
      int maxOrden = 0;
      for (var doc in snapshot.docs) {
        final orden = doc.data()['orden'] as int? ?? 0;
        if (orden > maxOrden) {
          maxOrden = orden;
        }
      }
      
      return maxOrden + 1;
    } catch (e) {
      debugPrint('Error al obtener siguiente orden: $e');
      return DateTime.now().millisecondsSinceEpoch % 1000; // Orden temporal único
    }
  }

  // Actualizar orden de anuncios
  Future<void> actualizarOrden(String anuncioId, int nuevoOrden) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(anuncioId)
          .update({'orden': nuevoOrden});
    } catch (e) {
      throw Exception('Error al actualizar orden: $e');
    }
  }
}