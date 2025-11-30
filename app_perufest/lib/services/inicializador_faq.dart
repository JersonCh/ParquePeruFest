import 'package:flutter/material.dart';
import '../services/faq_service.dart';

class InicializadorFAQ {
  static final FAQService _faqService = FAQService();

  /// Inicializa las preguntas frecuentes predeterminadas del PeruFest
  /// Solo se ejecutará si no existen FAQs en la base de datos
  static Future<bool> inicializarFAQsPredeterminadas() async {
    try {
      debugPrint('Inicializando FAQs predeterminadas...');
      
      // Verificar si ya existen FAQs
      final faqsExistentes = await _faqService.obtenerTodasLasFAQs();
      
      if (faqsExistentes.isNotEmpty) {
        debugPrint('Ya existen FAQs en el sistema (${faqsExistentes.length} encontradas)');
        return true;
      }

      // Crear FAQs predeterminadas
      final success = await _faqService.crearFAQsPredeterminadas();
      
      if (success) {
        debugPrint('FAQs predeterminadas creadas exitosamente');
      } else {
        debugPrint('Error al crear FAQs predeterminadas');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error en inicializadorFAQ: $e');
      return false;
    }
  }

  /// Crea FAQs adicionales para casos específicos
  static Future<void> crearFAQsAdicionales() async {
    try {
      final faqsAdicionales = [
        {
          'pregunta': '¿Cómo puedo agregar eventos a mi agenda personal?',
          'respuesta': 'Para agregar eventos a tu agenda, ve a la sección de Eventos, selecciona el evento que te interesa y toca el botón "Agregar a Agenda". También puedes ver todas las actividades del evento y seleccionar las específicas que deseas seguir.',
        },
        {
          'pregunta': '¿Qué medidas de seguridad se implementan durante el festival?',
          'respuesta': 'El PeruFest cuenta con personal de seguridad distribuido por todo el parque, cámaras de vigilancia, puntos de primeros auxilios y protocolos de emergencia. También hay zonas designadas para niños perdidos y puntos de información.',
        },
        {
          'pregunta': '¿Hay acceso para personas con discapacidad?',
          'respuesta': 'Sí, el PeruFest está completamente adaptado para personas con discapacidad. Contamos con rampas de acceso, baños adaptados, zonas de estacionamiento preferencial y personal capacitado para brindar asistencia cuando sea necesario.',
        },
      ];

      for (final faq in faqsAdicionales) {
        await _faqService.crearFAQ(
          pregunta: faq['pregunta']!,
          respuesta: faq['respuesta']!,
          estado: true,
          orden: 0, // Se organizará automáticamente
        );
      }

      debugPrint('FAQs adicionales creadas exitosamente');
    } catch (e) {
      debugPrint('Error al crear FAQs adicionales: $e');
    }
  }

  /// Actualiza una FAQ específica si existe
  static Future<bool> actualizarFAQExistente(String preguntaBuscar, String nuevaRespuesta) async {
    try {
      final todasLasFAQs = await _faqService.obtenerTodasLasFAQs();
      
      final faqsEncontradas = todasLasFAQs.where(
        (faq) => faq.pregunta.toLowerCase().contains(preguntaBuscar.toLowerCase())
      );
      
      final faqEncontrada = faqsEncontradas.isNotEmpty ? faqsEncontradas.first : null;
      
      if (faqEncontrada != null) {
        final success = await _faqService.actualizarFAQ(
          faqEncontrada.id,
          respuesta: nuevaRespuesta,
        );
        
        if (success) {
          debugPrint('FAQ actualizada: ${faqEncontrada.pregunta}');
        }
        
        return success;
      } else {
        debugPrint('FAQ no encontrada con el texto: $preguntaBuscar');
        return false;
      }
    } catch (e) {
      debugPrint('Error al actualizar FAQ existente: $e');
      return false;
    }
  }

  /// Desactiva FAQs que ya no sean relevantes
  static Future<void> desactivarFAQsAntiguas(List<String> textosABuscar) async {
    try {
      final todasLasFAQs = await _faqService.obtenerTodasLasFAQs();
      
      for (final textoBuscar in textosABuscar) {
        final faqsEncontradas = todasLasFAQs.where(
          (faq) => faq.pregunta.toLowerCase().contains(textoBuscar.toLowerCase()) && faq.estado
        );
        
        for (final faq in faqsEncontradas) {
          await _faqService.cambiarEstadoFAQ(faq.id, false);
          debugPrint('FAQ desactivada: ${faq.pregunta}');
        }
      }
    } catch (e) {
      debugPrint('Error al desactivar FAQs antiguas: $e');
    }
  }
}