import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cambiar_posicion_anuncios.dart';

/// Widget temporal para hacer debug de anuncios
class DebugAnunciosWidget extends StatelessWidget {
  const DebugAnunciosWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            '🐛 DEBUG ANUNCIOS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _verificarAnuncios,
            child: const Text('Verificar Anuncios en Firebase'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _crearAnuncioPrueba(context),
            child: const Text('Crear Anuncio de Prueba'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _crearAnuncioGarantizado(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('🎯 Crear Anuncio GARANTIZADO'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _crearAnuncioReal(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('🚀 Crear Anuncio REAL para Banner'),
          ),
          const SizedBox(height: 8),
          const CambiarPosicionAnuncios(),
        ],
      ),
    );
  }

  static Future<void> _verificarAnuncios() async {
    try {
      print('🔍 VERIFICANDO ANUNCIOS EN FIREBASE...');
      print('📅 Fecha y hora actual: ${DateTime.now()}');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('anuncios')
          .get();
      
      print('📊 Total anuncios encontrados: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        print('❌ NO HAY ANUNCIOS EN FIREBASE');
        return;
      }
      
      int activosCount = 0;
      int vigentesCount = 0;
      int superioresCount = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('=====================================');
        print('🆔 ID: ${doc.id}');
        print('📝 Título: ${data['titulo']}');
        print('✅ Activo: ${data['activo']}');
        print('📍 Posición: ${data['posicion']}');
        print('📅 Fecha inicio: ${data['fechaInicio']}');
        print('📅 Fecha fin: ${data['fechaFin']}');
        print('🔢 Orden: ${data['orden']}');
        print('👤 Creado por: ${data['creadoPor']}');
        
        // Contar estadísticas
        if (data['activo'] == true) activosCount++;
        if (data['posicion'] == 'superior') superioresCount++;
        
        // Verificar si está vigente
        try {
          final ahora = DateTime.now();
          final fechaInicio = (data['fechaInicio'] as Timestamp).toDate();
          final fechaFin = (data['fechaFin'] as Timestamp).toDate();
          final vigente = fechaInicio.isBefore(ahora) && fechaFin.isAfter(ahora);
          
          print('⏰ Vigente: $vigente');
          print('   📍 Inicio: ${fechaInicio.toString().substring(0, 19)}');
          print('   📍 Fin: ${fechaFin.toString().substring(0, 19)}');
          print('   📍 Ahora: ${ahora.toString().substring(0, 19)}');
          
          if (vigente) vigentesCount++;
          
          // Verificar si cumple todos los criterios para mostrarse
          final mostrable = data['activo'] == true && vigente;
          print('🎯 Debe mostrarse: $mostrable');
        } catch (e) {
          print('❌ Error verificando fechas: $e');
        }
        print('=====================================');
      }
      
      print('');
      print('📈 RESUMEN ESTADÍSTICAS:');
      print('   📊 Total anuncios: ${snapshot.docs.length}');
      print('   ✅ Anuncios activos: $activosCount');
      print('   ⏰ Anuncios vigentes: $vigentesCount');
      print('   🔝 Anuncios posición superior: $superioresCount');
      print('   🎯 Anuncios que deberían mostrarse: ${activosCount > 0 && vigentesCount > 0 ? 'SÍ' : 'NO'}');
      
    } catch (e) {
      print('❌ Error verificando anuncios: $e');
    }
  }

  static Future<void> _crearAnuncioPrueba(BuildContext context) async {
    try {
      print('🔧 CREANDO ANUNCIO DE PRUEBA...');
      
      final ahora = DateTime.now();
      final anuncioData = {
        'titulo': '🍕 Pizza Test - DEBUG',
        'contenido': 'Este es un anuncio de prueba para verificar el sistema',
        'fechaInicio': Timestamp.fromDate(ahora),
        'fechaFin': Timestamp.fromDate(ahora.add(const Duration(days: 7))),
        'posicion': 'general',
        'activo': true,
        'orden': 1,
        'fechaCreacion': Timestamp.fromDate(ahora),
        'creadoPor': 'debug_system',
      };

      final docRef = await FirebaseFirestore.instance
          .collection('anuncios')
          .add(anuncioData);

      print('✅ Anuncio de prueba creado con ID: ${docRef.id}');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Anuncio de prueba creado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error creando anuncio de prueba: $e');
      
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

  static Future<void> _crearAnuncioGarantizado(BuildContext context) async {
    try {
      print('🎯 CREANDO ANUNCIO GARANTIZADO PARA MOSTRAR...');
      
      final ahora = DateTime.now();
      final anuncioData = {
        'titulo': '⭐ ANUNCIO GARANTIZADO - DEBERÍA APARECER',
        'contenido': 'Este anuncio está configurado para aparecer definitivamente. Si no lo ves, hay un problema en el código.',
        'imagenUrl': 'https://via.placeholder.com/150x100/FF6B35/FFFFFF?text=TEST',
        'fechaInicio': Timestamp.fromDate(ahora.subtract(const Duration(hours: 1))), // Comenzó hace 1 hora
        'fechaFin': Timestamp.fromDate(ahora.add(const Duration(days: 30))), // Termina en 30 días
        'posicion': 'superior', // Para que aparezca en el banner
        'activo': true,
        'orden': 1,
        'fechaCreacion': Timestamp.fromDate(ahora),
        'creadoPor': 'debug_garantizado',
      };

      final docRef = await FirebaseFirestore.instance
          .collection('anuncios')
          .add(anuncioData);

      print('✅ Anuncio GARANTIZADO creado con ID: ${docRef.id}');
      print('📋 Configuración:');
      print('   - Activo: true');
      print('   - Posición: superior');
      print('   - Vigente desde: ${ahora.subtract(const Duration(hours: 1))}');
      print('   - Válido hasta: ${ahora.add(const Duration(days: 30))}');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎯 Anuncio GARANTIZADO creado - Debería aparecer ahora'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Error creando anuncio garantizado: $e');
      
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

  static Future<void> _crearAnuncioReal(BuildContext context) async {
    try {
      print('🚀 CREANDO ANUNCIO REAL PARA BANNER...');
      
      final ahora = DateTime.now();
      final anuncioData = {
        'titulo': 'Patrocinadores Oficiales PeruFest 2025',
        'contenido': '¡Conoce a nuestros patrocinadores oficiales! Visita sus stands y disfruta de promociones especiales.',
        'imagenUrl': 'https://via.placeholder.com/400x150/8B1B1B/FFFFFF?text=PeruFest+2025+Patrocinadores',
        'fechaInicio': Timestamp.fromDate(ahora.subtract(const Duration(minutes: 30))), // Comenzó hace 30 min
        'fechaFin': Timestamp.fromDate(ahora.add(const Duration(days: 60))), // Termina en 60 días
        'posicion': 'superior', // Para que aparezca en el banner superior
        'activo': true,
        'orden': 1,
        'fechaCreacion': Timestamp.fromDate(ahora),
        'creadoPor': 'admin_perufest',
        'enlaceUrl': 'https://perufest.com/patrocinadores',
      };

      final docRef = await FirebaseFirestore.instance
          .collection('anuncios')
          .add(anuncioData);

      print('✅ Anuncio REAL creado con ID: ${docRef.id}');
      print('📋 Configuración:');
      print('   - Título: ${anuncioData['titulo']}');
      print('   - Activo: true');
      print('   - Posición: superior');
      print('   - Vigente desde: ${ahora.subtract(const Duration(minutes: 30))}');
      print('   - Válido hasta: ${ahora.add(const Duration(days: 60))}');
      print('   - NO contiene palabras de debug');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Anuncio REAL creado - Debería aparecer en el banner superior'),
            backgroundColor: Colors.purple,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Error creando anuncio real: $e');
      
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