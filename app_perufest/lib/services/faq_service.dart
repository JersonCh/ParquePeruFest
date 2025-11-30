import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/faq.dart';

class FAQService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'faqs';

  // Obtener todas las FAQs (para administrador)
  Future<List<FAQ>> obtenerTodasLasFAQs() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('fechaCreacion', descending: false)
          .get()
          .timeout(const Duration(seconds: 10));

      final faqs = querySnapshot.docs.map((doc) => FAQ.fromFirestore(doc)).toList();
      
      // Ordenar por orden en memoria para evitar índices compuestos
      faqs.sort((a, b) {
        if (a.orden != b.orden) {
          return a.orden.compareTo(b.orden);
        }
        return a.fechaCreacion.compareTo(b.fechaCreacion);
      });
      
      return faqs;
    } catch (e) {
      print('Error al obtener todas las FAQs: $e');
      return [];
    }
  }

  // Obtener solo FAQs activas (para visitantes)
  Future<List<FAQ>> obtenerFAQsActivas() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('estado', isEqualTo: true)
          .orderBy('fechaCreacion', descending: false)
          .get();

      final faqs = querySnapshot.docs.map((doc) => FAQ.fromFirestore(doc)).toList();
      
      // Ordenar por orden en memoria para evitar índices compuestos
      faqs.sort((a, b) {
        if (a.orden != b.orden) {
          return a.orden.compareTo(b.orden);
        }
        return a.fechaCreacion.compareTo(b.fechaCreacion);
      });
      
      return faqs;
    } catch (e) {
      print('Error al obtener FAQs activas: $e');
      return [];
    }
  }

  // Obtener una FAQ por ID
  Future<FAQ?> obtenerFAQPorId(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      
      if (doc.exists) {
        return FAQ.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error al obtener FAQ por ID: $e');
      return null;
    }
  }

  // Crear nueva FAQ
  Future<String?> crearFAQ({
    required String pregunta,
    required String respuesta,
    bool estado = true,
    int orden = 0,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = await _firestore.collection(_collectionName).add({
        'pregunta': pregunta,
        'respuesta': respuesta,
        'estado': estado,
        'fechaCreacion': Timestamp.fromDate(now),
        'fechaModificacion': Timestamp.fromDate(now),
        'orden': orden,
      });

      return docRef.id;
    } catch (e) {
      print('Error al crear FAQ: $e');
      return null;
    }
  }

  // Actualizar FAQ existente
  Future<bool> actualizarFAQ(String id, {
    String? pregunta,
    String? respuesta,
    bool? estado,
    int? orden,
  }) async {
    try {
      final Map<String, dynamic> datosActualizacion = {
        'fechaModificacion': Timestamp.fromDate(DateTime.now()),
      };

      if (pregunta != null) datosActualizacion['pregunta'] = pregunta;
      if (respuesta != null) datosActualizacion['respuesta'] = respuesta;
      if (estado != null) datosActualizacion['estado'] = estado;
      if (orden != null) datosActualizacion['orden'] = orden;

      await _firestore.collection(_collectionName).doc(id).update(datosActualizacion);
      return true;
    } catch (e) {
      print('Error al actualizar FAQ: $e');
      return false;
    }
  }

  // Eliminar FAQ
  Future<bool> eliminarFAQ(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      return true;
    } catch (e) {
      print('Error al eliminar FAQ: $e');
      return false;
    }
  }

  // Cambiar estado de FAQ (activar/desactivar)
  Future<bool> cambiarEstadoFAQ(String id, bool nuevoEstado) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'estado': nuevoEstado,
        'fechaModificacion': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error al cambiar estado de FAQ: $e');
      return false;
    }
  }

  // Reordenar FAQs (cambiar el orden de visualización)
  Future<bool> reordenarFAQs(List<String> idsOrdenados) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < idsOrdenados.length; i++) {
        final docRef = _firestore.collection(_collectionName).doc(idsOrdenados[i]);
        batch.update(docRef, {
          'orden': i,
          'fechaModificacion': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error al reordenar FAQs: $e');
      return false;
    }
  }

  // Buscar FAQs por texto (tanto en pregunta como respuesta)
  Future<List<FAQ>> buscarFAQs(String textoBusqueda) async {
    try {
      // Esta es una búsqueda básica. Para búsquedas más avanzadas,
      // se podría implementar con Algolia o similar
      final faqs = await obtenerFAQsActivas();
      
      if (textoBusqueda.isEmpty) return faqs;

      final textoBusquedaLower = textoBusqueda.toLowerCase();
      
      return faqs.where((faq) =>
        faq.pregunta.toLowerCase().contains(textoBusquedaLower) ||
        faq.respuesta.toLowerCase().contains(textoBusquedaLower)
      ).toList();
    } catch (e) {
      print('Error al buscar FAQs: $e');
      return [];
    }
  }

  // Obtener estadísticas de FAQs
  Future<Map<String, dynamic>> obtenerEstadisticasFAQs() async {
    try {
      final todasLasFAQs = await obtenerTodasLasFAQs();
      final faqsActivas = todasLasFAQs.where((faq) => faq.estado).length;
      final faqsInactivas = todasLasFAQs.where((faq) => !faq.estado).length;

      return {
        'total': todasLasFAQs.length,
        'activas': faqsActivas,
        'inactivas': faqsInactivas,
      };
    } catch (e) {
      print('Error al obtener estadísticas de FAQs: $e');
      return {
        'total': 0,
        'activas': 0,
        'inactivas': 0,
      };
    }
  }

  // Stream para escuchar cambios en FAQs activas (para UI reactiva)
  Stream<List<FAQ>> streamFAQsActivas() {
    return _firestore
        .collection(_collectionName)
        .where('estado', isEqualTo: true)
        .orderBy('fechaCreacion', descending: false)
        .snapshots()
        .map((snapshot) {
          final faqs = snapshot.docs.map((doc) => FAQ.fromFirestore(doc)).toList();
          
          // Ordenar por orden en memoria para evitar índices compuestos
          faqs.sort((a, b) {
            if (a.orden != b.orden) {
              return a.orden.compareTo(b.orden);
            }
            return a.fechaCreacion.compareTo(b.fechaCreacion);
          });
          
          return faqs;
        });
  }

  // Stream para escuchar cambios en todas las FAQs (para admin)
  Stream<List<FAQ>> streamTodasLasFAQs() {
    return _firestore
        .collection(_collectionName)
        .orderBy('fechaCreacion', descending: false)
        .snapshots()
        .map((snapshot) {
          final faqs = snapshot.docs.map((doc) => FAQ.fromFirestore(doc)).toList();
          
          // Ordenar por orden en memoria para evitar índices compuestos
          faqs.sort((a, b) {
            if (a.orden != b.orden) {
              return a.orden.compareTo(b.orden);
            }
            return a.fechaCreacion.compareTo(b.fechaCreacion);
          });
          
          return faqs;
        });
  }

  // Crear FAQs predeterminadas (para inicializar el sistema)
  Future<bool> crearFAQsPredeterminadas() async {
    try {
      // Verificar si ya existen FAQs con timeout
      final faqsExistentes = await obtenerTodasLasFAQs();
      
      // Solo crear si no existen FAQs
      if (faqsExistentes.isNotEmpty) {
        print('FAQs ya existen en el sistema: ${faqsExistentes.length}');
        return true;
      }

      final faqsPredeterminadas = [
        {
          'pregunta': '¿Cuál es el horario del festival?',
          'respuesta': 'El PeruFest 2025 se realizará de 9:00 AM a 10:00 PM todos los días del evento. Las actividades específicas tienen horarios diferentes que puedes consultar en la sección de eventos.',
          'orden': 1,
        },
        {
          'pregunta': '¿Dónde se ubica el ParquePerú Fest?',
          'respuesta': 'El festival se lleva a cabo en el Parque de la Exposición, ubicado en el centro de Lima. Puedes usar nuestro mapa interactivo para navegar por las diferentes zonas del evento.',
          'orden': 2,
        },
        {
          'pregunta': '¿Las entradas tienen costo?',
          'respuesta': 'La entrada general al festival es gratuita. Algunos eventos especiales y talleres pueden tener un costo adicional, el cual se especifica en cada actividad.',
          'orden': 3,
        },
        {
          'pregunta': '¿Puedo llevar comida y bebidas?',
          'respuesta': 'No está permitido ingresar comida o bebidas del exterior. Contamos con una amplia zona gastronómica con opciones para todos los gustos y presupuestos.',
          'orden': 4,
        },
        {
          'pregunta': '¿Hay estacionamiento disponible?',
          'respuesta': 'Sí, contamos con zonas de estacionamiento habilitadas cerca del evento. También recomendamos usar transporte público debido a la alta afluencia de visitantes.',
          'orden': 5,
        },
      ];

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final faqData in faqsPredeterminadas) {
        final docRef = _firestore.collection(_collectionName).doc();
        batch.set(docRef, {
          'pregunta': faqData['pregunta'],
          'respuesta': faqData['respuesta'],
          'estado': true,
          'fechaCreacion': Timestamp.fromDate(now),
          'fechaModificacion': Timestamp.fromDate(now),
          'orden': faqData['orden'],
        });
      }

      await batch.commit().timeout(const Duration(seconds: 15));
      print('FAQs predeterminadas creadas exitosamente');
      return true;
    } catch (e) {
      print('Error al crear FAQs predeterminadas: $e');
      return false;
    }
  }
}