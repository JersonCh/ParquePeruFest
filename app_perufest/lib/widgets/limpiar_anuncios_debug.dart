import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget para limpiar anuncios de debug desde la app
class LimpiarAnunciosDebug extends StatelessWidget {
  const LimpiarAnunciosDebug({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _limpiarAnunciosDebug(context),
      icon: const Icon(Icons.delete_sweep),
      label: const Text('Limpiar Anuncios de Prueba'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }

  static Future<void> _limpiarAnunciosDebug(BuildContext context) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Eliminar todos los anuncios de prueba/debug?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      print('🗑️ Buscando anuncios de debug para eliminar...');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('anuncios')
          .get();

      final anunciosDebug = snapshot.docs.where((doc) {
        final data = doc.data();
        final titulo = data['titulo']?.toString().toLowerCase() ?? '';
        return titulo.contains('debug') || 
               titulo.contains('garantizado') || 
               titulo.contains('prueba') ||
               titulo.contains('test');
      }).toList();

      print('🗑️ Encontrados ${anunciosDebug.length} anuncios de debug');

      for (var doc in anunciosDebug) {
        await doc.reference.delete();
        print('🗑️ Eliminado: ${doc.data()['titulo']}');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Eliminados ${anunciosDebug.length} anuncios de debug'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error limpiando anuncios: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}