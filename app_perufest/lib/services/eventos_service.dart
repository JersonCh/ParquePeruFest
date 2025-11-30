import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/evento.dart';
import '../services/timezone.dart';
import '../services/supabase_storage_service.dart';

class EventosService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'eventos';
  static final SupabaseStorageService _supabaseStorage = SupabaseStorageService();

  static Future<String> crearEvento(Evento evento, {File? pdfFile}) async {
    try {
      final now = TimezoneUtils.now(); // Use Peru timezone
      
      // Primero crear el evento para obtener el ID
      final eventoData = evento.copyWith(
        fechaCreacion: now,
        fechaActualizacion: now,
      ).toJson();

      final docRef = await _db.collection(_collection).add(eventoData);
      final eventoId = docRef.id;
      
      if (kDebugMode) {
        debugPrint('Evento creado con ID: $eventoId');
      }
      
      // Si hay PDF, subirlo después de crear el evento
      if (pdfFile != null) {
        final pdfUrl = await _supabaseStorage.subirPDF(pdfFile, eventoId);
        
        if (pdfUrl != null) {
          // Actualizar el evento con la URL del PDF
          await _db.collection(_collection).doc(eventoId).update({
            'pdfUrl': pdfUrl,
          });
          
          if (kDebugMode) {
            debugPrint('PDF subido a Supabase Storage: $pdfUrl');
          }
        }
      }
      
      return eventoId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al crear evento: $e');
      }
      throw Exception('Error al crear el evento');
    }
  }

  static Future<List<Evento>> obtenerEventos() async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .orderBy('fechaInicio', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Evento.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener eventos: $e');
      }
      throw Exception('Error al cargar los eventos');
    }
  }

  static Future<List<Evento>> buscarEventos(String termino) async {
    try {
      final snapshot = await _db.collection(_collection).get();
      
      final eventos = snapshot.docs
          .map((doc) => Evento.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      return eventos.where((evento) {
        final terminoLower = termino.toLowerCase();
        return evento.nombre.toLowerCase().contains(terminoLower) ||
            evento.lugar.toLowerCase().contains(terminoLower) ||
            evento.organizador.toLowerCase().contains(terminoLower);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al buscar eventos: $e');
      }
      throw Exception('Error al buscar eventos');
    }
  }

  static Future<List<Evento>> filtrarEventosPorCategoria(String categoria) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('categoria', isEqualTo: categoria)
          .orderBy('fechaInicio', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Evento.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al filtrar eventos: $e');
      }
      throw Exception('Error al filtrar eventos');
    }
  }


  static Future<Evento?> obtenerEventoPorId(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      
      if (doc.exists && doc.data() != null) {
        return Evento.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener evento: $e');
      }
      throw Exception('Error al cargar el evento');
    }
  }

  static Future<void> actualizarEvento(String id, Evento evento, {File? pdfFile}) async {
    try {
      Evento eventoActualizado = evento;
      
      // Si hay un archivo PDF, subirlo a Supabase Storage
      if (pdfFile != null) {
        final pdfUrl = await _supabaseStorage.subirPDF(pdfFile, id);
        
        if (pdfUrl != null) {
          // Actualizar evento con la URL del PDF
          eventoActualizado = evento.copyWith(
            pdfUrl: pdfUrl,
            pdfBase64: null, // Limpiar Base64 si existe
          );
          
          if (kDebugMode) {
            debugPrint('PDF subido a Supabase Storage: $pdfUrl');
          }
        } else {
          throw Exception('Error al subir el archivo PDF');
        }
      }
      
      final eventoData = eventoActualizado.copyWith(
        fechaActualizacion: TimezoneUtils.now(), // Use Peru timezone
      ).toJson();
      
      await _db.collection(_collection).doc(id).update(eventoData);
      
      if (kDebugMode) {
        debugPrint('Evento actualizado: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al actualizar evento: $e');
      }
      throw Exception('Error al actualizar el evento');
    }
  }

  static Future<void> eliminarEvento(String id) async {
    try {
      // Eliminar PDF de Supabase Storage si existe
      await _supabaseStorage.eliminarPDF(id);
      
      // Eliminar evento de Firestore
      await _db.collection(_collection).doc(id).delete();
      
      if (kDebugMode) {
        debugPrint('Evento eliminado: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al eliminar evento: $e');
      }
      throw Exception('Error al eliminar el evento');
    }
  }

  static Future<void> actualizarEstadoEvento(String id, String nuevoEstado) async {
    try {
      await _db.collection(_collection).doc(id).update({
        'estado': nuevoEstado,
        'fechaActualizacion': TimezoneUtils.now().toIso8601String(), // Use Peru timezone
      });
      
      if (kDebugMode) {
        debugPrint('Estado del evento actualizado: $id -> $nuevoEstado');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al actualizar estado: $e');
      }
      throw Exception('Error al actualizar el estado del evento');
    }
  }
}