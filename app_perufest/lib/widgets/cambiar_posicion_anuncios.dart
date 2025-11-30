import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget para cambiar posición de anuncios existentes
class CambiarPosicionAnuncios extends StatelessWidget {
  const CambiarPosicionAnuncios({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _cambiarPosicionAnuncios(context),
      icon: const Icon(Icons.sync_alt),
      label: const Text('Cambiar anuncios a "general"'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  static Future<void> _cambiarPosicionAnuncios(BuildContext context) async {
    try {
      print('🔄 Cambiando posición de anuncios a "general"...');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('anuncios')
          .where('activo', isEqualTo: true)
          .get();

      int cambiados = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final titulo = data['titulo']?.toString() ?? '';
        
        // Solo cambiar anuncios reales (no de debug)
        if (!titulo.toLowerCase().contains('debug') && 
            !titulo.toLowerCase().contains('test') &&
            !titulo.toLowerCase().contains('prueba') &&
            !titulo.toLowerCase().contains('garantizado')) {
          
          await doc.reference.update({'posicion': 'general'});
          print('✅ Cambiado: $titulo → posicion: general');
          cambiados++;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cambiados $cambiados anuncios a posición "general"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error cambiando posición: $e');
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