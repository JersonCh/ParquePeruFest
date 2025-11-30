import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget simple para mostrar TODOS los anuncios sin filtros
class AnunciosDebugSimple extends StatelessWidget {
  const AnunciosDebugSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔧 ANUNCIOS SIN FILTROS (DEBUG)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('anuncios')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('⏳ Cargando anuncios...');
              }
              
              if (snapshot.hasError) {
                return Text('❌ Error: ${snapshot.error}');
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('📭 No hay anuncios en Firebase');
              }
              
              final anuncios = snapshot.data!.docs;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 Total: ${anuncios.length} anuncios encontrados'),
                  const SizedBox(height: 8),
                  ...anuncios.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fechaInicio = data['fechaInicio'] != null 
                        ? (data['fechaInicio'] as Timestamp).toDate()
                        : null;
                    final fechaFin = data['fechaFin'] != null 
                        ? (data['fechaFin'] as Timestamp).toDate()
                        : null;
                    
                    final ahora = DateTime.now();
                    final vigente = fechaInicio != null && fechaFin != null
                        ? ahora.isAfter(fechaInicio) && ahora.isBefore(fechaFin)
                        : false;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: data['activo'] == true && vigente 
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        border: Border.all(
                          color: data['activo'] == true && vigente 
                              ? Colors.green 
                              : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📄 ${data['titulo'] ?? 'Sin título'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('🆔 ID: ${doc.id}'),
                          Text('✅ Activo: ${data['activo']}'),
                          Text('📍 Posición: ${data['posicion']}'),
                          Text('🔢 Orden: ${data['orden']}'),
                          if (fechaInicio != null)
                            Text('📅 Inicio: ${fechaInicio.toString().substring(0, 16)}'),
                          if (fechaFin != null)
                            Text('📅 Fin: ${fechaFin.toString().substring(0, 16)}'),
                          Text('⏰ Vigente: $vigente'),
                          Text(
                            '🎯 Debería mostrarse: ${data['activo'] == true && vigente}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: data['activo'] == true && vigente 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}