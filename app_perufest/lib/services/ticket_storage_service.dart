import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class TicketStorageService {
  static const String _ticketsFolder = 'tickets';

  /// Obtiene el directorio donde se guardan los tickets
  static Future<Directory> _getTicketsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final ticketsDir = Directory('${appDir.path}/$_ticketsFolder');
    
    if (!await ticketsDir.exists()) {
      await ticketsDir.create(recursive: true);
    }
    
    return ticketsDir;
  }

  /// Guarda un PDF de ticket en almacenamiento local
  static Future<String> guardarTicketPdf({
    required String ticketId,
    required Uint8List pdfBytes,
  }) async {
    try {
      final ticketsDir = await _getTicketsDirectory();
      final fileName = 'ticket_$ticketId.pdf';
      final file = File('${ticketsDir.path}/$fileName');
      
      await file.writeAsBytes(pdfBytes);
      
      if (kDebugMode) {
        debugPrint('✅ Ticket PDF guardado: ${file.path}');
      }
      
      return file.path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al guardar ticket PDF: $e');
      }
      rethrow;
    }
  }

  /// Obtiene la ruta de un ticket PDF guardado
  static Future<String?> getTicketPdfPath(String ticketId) async {
    try {
      final ticketsDir = await _getTicketsDirectory();
      final fileName = 'ticket_$ticketId.pdf';
      final file = File('${ticketsDir.path}/$fileName');
      
      if (await file.exists()) {
        return file.path;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al obtener ruta de ticket: $e');
      }
      return null;
    }
  }

  /// Verifica si existe un ticket PDF guardado
  static Future<bool> existeTicketPdf(String ticketId) async {
    final path = await getTicketPdfPath(ticketId);
    return path != null;
  }

  /// Obtiene todos los PDFs de tickets guardados
  static Future<List<FileSystemEntity>> obtenerTodosLosTickets() async {
    try {
      final ticketsDir = await _getTicketsDirectory();
      final files = ticketsDir.listSync();
      
      // Filtrar solo archivos PDF
      return files.where((file) => file.path.endsWith('.pdf')).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al listar tickets: $e');
      }
      return [];
    }
  }

  /// Elimina un ticket PDF específico
  static Future<bool> eliminarTicketPdf(String ticketId) async {
    try {
      final ticketsDir = await _getTicketsDirectory();
      final fileName = 'ticket_$ticketId.pdf';
      final file = File('${ticketsDir.path}/$fileName');
      
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          debugPrint('✅ Ticket PDF eliminado: $ticketId');
        }
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al eliminar ticket PDF: $e');
      }
      return false;
    }
  }

  /// Limpia todos los tickets guardados
  static Future<void> limpiarTodosLosTickets() async {
    try {
      final ticketsDir = await _getTicketsDirectory();
      if (await ticketsDir.exists()) {
        await ticketsDir.delete(recursive: true);
        if (kDebugMode) {
          debugPrint('✅ Todos los tickets han sido eliminados');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al limpiar tickets: $e');
      }
    }
  }

  /// Obtiene el tamaño total ocupado por los tickets
  static Future<int> obtenerTamanioTotal() async {
    try {
      final files = await obtenerTodosLosTickets();
      int totalSize = 0;
      
      for (var file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al calcular tamaño total: $e');
      }
      return 0;
    }
  }

  /// Convierte bytes a formato legible (KB, MB)
  static String formatearTamanio(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
