import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget temporal para mostrar banners directamente desde Firebase (para debug)
class BannerAnunciosDirecto extends StatelessWidget {
  final String posicion;
  
  const BannerAnunciosDirecto({
    super.key,
    required this.posicion,
  });

  @override
  Widget build(BuildContext context) {
    print('🎯 BannerAnunciosDirecto - Solicitando anuncios para posición: $posicion');
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('anuncios')
          .where('activo', isEqualTo: true)
          .where('posicion', isEqualTo: posicion)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 60,
            color: Colors.grey.shade200,
            child: const Center(
              child: Text('⏳ Cargando banner...'),
            ),
          );
        }
        
        if (snapshot.hasError) {
          print('❌ Error en BannerAnunciosDirecto: ${snapshot.error}');
          return Container(
            height: 60,
            color: Colors.red.shade100,
            child: Center(
              child: Text('❌ Error: ${snapshot.error}'),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('📭 BannerAnunciosDirecto - No hay anuncios para posición: $posicion');
          return const SizedBox.shrink();
        }
        
        final docs = snapshot.data!.docs;
        print('📊 BannerAnunciosDirecto - Encontrados ${docs.length} anuncios para posición: $posicion');
        
        // Filtrar por vigencia
        final ahora = DateTime.now();
        final anunciosVigentes = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          try {
            final fechaInicio = (data['fechaInicio'] as Timestamp).toDate();
            final fechaFin = (data['fechaFin'] as Timestamp).toDate();
            final vigente = ahora.isAfter(fechaInicio) && ahora.isBefore(fechaFin);
            
            print('   📄 ${data['titulo']} - Vigente: $vigente');
            return vigente;
          } catch (e) {
            print('   ❌ Error procesando fechas para ${data['titulo']}: $e');
            return false;
          }
        }).toList();
        
        if (anunciosVigentes.isEmpty) {
          print('📭 BannerAnunciosDirecto - No hay anuncios vigentes para posición: $posicion');
          return const SizedBox.shrink();
        }
        
        print('✅ BannerAnunciosDirecto - Mostrando ${anunciosVigentes.length} anuncios vigentes');
        
        // Tomar el primer anuncio vigente por simplicidad
        final doc = anunciosVigentes.first;
        final data = doc.data() as Map<String, dynamic>;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['titulo'] ?? 'Anuncio',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (data['contenido'] != null)
                      Text(
                        data['contenido'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        );
      },
    );
  }
}