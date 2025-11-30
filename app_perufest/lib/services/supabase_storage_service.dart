import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class SupabaseStorageService {
  final _supabase = Supabase.instance.client;
  static const String _bucket = 'eventos';
  
  /// Sube un archivo PDF a Supabase Storage
  /// Retorna la URL pública del archivo o null si hay error
  Future<String?> subirPDF(File pdfFile, String eventoId) async {
    try {
      // Verificar tamaño del archivo (máximo 5MB)
      final fileSize = await pdfFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('El archivo es demasiado grande. Máximo 5MB permitido.');
      }
      
      // Crear nombre único para el archivo
      final fileName = 'evento_$eventoId.pdf';
      final filePath = 'pdfs/$fileName';
      
      if (kDebugMode) {
        debugPrint('Subiendo PDF a Supabase Storage: $filePath');
      }
      
      // Subir archivo (upsert: true permite sobrescribir si ya existe)
      await _supabase.storage
          .from(_bucket)
          .upload(
            filePath, 
            pdfFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      // Obtener URL pública
      final publicUrl = _supabase.storage
          .from(_bucket)
          .getPublicUrl(filePath);
      
      if (kDebugMode) {
        debugPrint('PDF subido exitosamente: $publicUrl');
      }
      
      return publicUrl;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al subir PDF a Supabase Storage: $e');
      }
      return null;
    }
  }
  
  /// Elimina un archivo PDF de Supabase Storage
  Future<bool> eliminarPDF(String eventoId) async {
    try {
      final fileName = 'evento_$eventoId.pdf';
      final filePath = 'pdfs/$fileName';
      
      if (kDebugMode) {
        debugPrint('Eliminando PDF de Supabase Storage: $filePath');
      }
      
      await _supabase.storage
          .from(_bucket)
          .remove([filePath]);
      
      if (kDebugMode) {
        debugPrint('PDF eliminado exitosamente');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al eliminar PDF: $e');
      }
      return false;
    }
  }
  
  /// Verifica si existe un PDF para un evento
  Future<bool> existePDF(String eventoId) async {
    try {
      final fileName = 'evento_$eventoId.pdf';
      
      final files = await _supabase.storage
          .from(_bucket)
          .list(path: 'pdfs');
      
      return files.any((file) => file.name == fileName);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al verificar existencia de PDF: $e');
      }
      return false;
    }
  }
}
