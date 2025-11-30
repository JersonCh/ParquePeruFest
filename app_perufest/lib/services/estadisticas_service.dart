import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/estadisticas.dart';
import 'timezone_service.dart';

class EstadisticasService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obtener estadísticas generales del sistema
  static Future<EstadisticasGenerales> obtenerEstadisticasGenerales() async {
    try {
      final ahora = TimezoneService.nowInPeru();
      final inicioMes = DateTime(ahora.year, ahora.month, 1);
      final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));

      // Usuarios registrados
      final usuariosSnapshot = await _db.collection('usuarios').get();
      final totalUsuarios = usuariosSnapshot.size;

      // Usuarios registrados esta semana
      final usuariosSemanaSnapshot = await _db
          .collection('usuarios')
          .where('fechaRegistro', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioSemana))
          .get();
      final usuariosSemana = usuariosSemanaSnapshot.size;

      // Eventos activos
      final eventosSnapshot = await _db
          .collection('eventos')
          .where('estado', isEqualTo: 'activo')
          .get();
      final eventosActivos = eventosSnapshot.size;

      // Total eventos
      final totalEventosSnapshot = await _db.collection('eventos').get();
      final totalEventos = totalEventosSnapshot.size;

      // Actividades totales
      final actividadesSnapshot = await _db.collection('actividades').get();
      final totalActividades = actividadesSnapshot.size;

      // Noticias publicadas
      final noticiasSnapshot = await _db.collection('noticias').get();
      final totalNoticias = noticiasSnapshot.size;

      // Noticias del mes
      final noticiasDelMesSnapshot = await _db
          .collection('noticias')
          .where('fechaPublicacion', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
          .get();
      final noticiasDelMes = noticiasDelMesSnapshot.size;

      // Anuncios activos
      final anunciosActivosSnapshot = await _db
          .collection('anuncios')
          .where('activo', isEqualTo: true)
          .get();
      final anunciosActivos = anunciosActivosSnapshot.size;

      return EstadisticasGenerales(
        totalUsuarios: totalUsuarios,
        usuariosNuevosSemana: usuariosSemana,
        eventosActivos: eventosActivos,
        totalEventos: totalEventos,
        totalActividades: totalActividades,
        totalNoticias: totalNoticias,
        noticiasDelMes: noticiasDelMes,
        anunciosActivos: anunciosActivos,
        fechaActualizacion: ahora,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener estadísticas generales: $e');
      }
      throw Exception('Error al cargar estadísticas');
    }
  }

  /// Obtener estadísticas de uso de agenda
  static Future<EstadisticasAgenda> obtenerEstadisticasAgenda() async {
    try {
      final agendaSnapshot = await _db.collection('agenda_usuarios').get();
      
      int totalUsuariosConAgenda = 0;
      int totalActividadesEnAgenda = 0;
      
      for (var doc in agendaSnapshot.docs) {
        final data = doc.data();
        final actividades = List<String>.from(data['actividades'] ?? []);
        
        if (actividades.isNotEmpty) {
          totalUsuariosConAgenda++;
          totalActividadesEnAgenda += actividades.length;
        }
      }

      // Actividades más populares en agenda
      final actividadesPopulares = await _obtenerActividadesPopulares();

      return EstadisticasAgenda(
        totalUsuariosConAgenda: totalUsuariosConAgenda,
        totalActividadesEnAgenda: totalActividadesEnAgenda,
        promedioActividadesPorUsuario: totalUsuariosConAgenda > 0 
            ? (totalActividadesEnAgenda / totalUsuariosConAgenda).round() 
            : 0,
        actividadesPopulares: actividadesPopulares,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener estadísticas de agenda: $e');
      }
      throw Exception('Error al cargar estadísticas de agenda');
    }
  }

  /// Obtener actividades más populares
  static Future<List<ActividadPopular>> _obtenerActividadesPopulares() async {
    try {
      final agendaSnapshot = await _db.collection('agenda_usuarios').get();
      Map<String, int> contadorActividades = {};

      for (var doc in agendaSnapshot.docs) {
        final data = doc.data();
        final actividades = List<String>.from(data['actividades'] ?? []);
        
        for (String actividadId in actividades) {
          contadorActividades[actividadId] = (contadorActividades[actividadId] ?? 0) + 1;
        }
      }

      // Obtener detalles de las actividades más populares
      List<ActividadPopular> actividadesPopulares = [];
      
      final actividadesOrdenadas = contadorActividades.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (var entry in actividadesOrdenadas.take(10)) {
        try {
          final actividadDoc = await _db.collection('actividades').doc(entry.key).get();
          if (actividadDoc.exists) {
            final data = actividadDoc.data()!;
            actividadesPopulares.add(ActividadPopular(
              id: entry.key,
              nombre: data['nombre'] ?? 'Sin nombre',
              zona: data['zona'] ?? 'Sin zona',
              cantidadUsuarios: entry.value,
            ));
          }
        } catch (e) {
          debugPrint('Error al obtener actividad ${entry.key}: $e');
        }
      }

      return actividadesPopulares;
    } catch (e) {
      debugPrint('Error al obtener actividades populares: $e');
      return [];
    }
  }

  /// Obtener estadísticas por rango de fechas
  static Future<EstadisticasPorFecha> obtenerEstadisticasPorFecha({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    try {
      final inicioTimestamp = Timestamp.fromDate(fechaInicio);
      final finTimestamp = Timestamp.fromDate(fechaFin);

      // Noticias publicadas en el rango
      final noticiasSnapshot = await _db
          .collection('noticias')
          .where('fechaPublicacion', isGreaterThanOrEqualTo: inicioTimestamp)
          .where('fechaPublicacion', isLessThanOrEqualTo: finTimestamp)
          .get();

      // Eventos creados en el rango
      final eventosSnapshot = await _db
          .collection('eventos')
          .where('fechaCreacion', isGreaterThanOrEqualTo: inicioTimestamp)
          .where('fechaCreacion', isLessThanOrEqualTo: finTimestamp)
          .get();

      // Actividades en el rango
      final actividadesSnapshot = await _db
          .collection('actividades')
          .where('fechaCreacion', isGreaterThanOrEqualTo: inicioTimestamp)
          .where('fechaCreacion', isLessThanOrEqualTo: finTimestamp)
          .get();

      return EstadisticasPorFecha(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        noticiasPublicadas: noticiasSnapshot.size,
        eventosCreados: eventosSnapshot.size,
        actividadesCreadas: actividadesSnapshot.size,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener estadísticas por fecha: $e');
      }
      throw Exception('Error al cargar estadísticas por fecha');
    }
  }

  /// Obtener estadísticas de eventos por categoría
  static Future<Map<String, int>> obtenerEventosPorCategoria() async {
    try {
      final eventosSnapshot = await _db.collection('eventos').get();
      Map<String, int> categorias = {};

      for (var doc in eventosSnapshot.docs) {
        final data = doc.data();
        final categoria = data['categoria'] ?? 'Sin categoría';
        categorias[categoria] = (categorias[categoria] ?? 0) + 1;
      }

      return categorias;
    } catch (e) {
      debugPrint('Error al obtener eventos por categoría: $e');
      return {};
    }
  }

  /// Obtener estadísticas de actividades por zona
  static Future<Map<String, int>> obtenerActividadesPorZona() async {
    try {
      final actividadesSnapshot = await _db.collection('actividades').get();
      Map<String, int> zonas = {};

      for (var doc in actividadesSnapshot.docs) {
        final data = doc.data();
        final zona = data['zona'] ?? 'Sin zona';
        zonas[zona] = (zonas[zona] ?? 0) + 1;
      }

      return zonas;
    } catch (e) {
      debugPrint('Error al obtener actividades por zona: $e');
      return {};
    }
  }

  /// Obtener datos para gráfico de usuarios registrados por mes
  static Future<List<UsuariosPorMes>> obtenerUsuariosPorMes() async {
    try {
      final usuariosSnapshot = await _db.collection('usuarios').get();
      Map<String, int> usuariosPorMes = {};

      for (var doc in usuariosSnapshot.docs) {
        final data = doc.data();
        final fechaRegistro = data['fechaRegistro'] as Timestamp?;
        
        if (fechaRegistro != null) {
          final fecha = TimezoneService.timestampToPeru(fechaRegistro);
          final claveMes = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
          usuariosPorMes[claveMes] = (usuariosPorMes[claveMes] ?? 0) + 1;
        }
      }

      final resultado = usuariosPorMes.entries
          .map((entry) => UsuariosPorMes(
                mes: entry.key,
                cantidad: entry.value,
              ))
          .toList();

      resultado.sort((a, b) => a.mes.compareTo(b.mes));
      return resultado;
    } catch (e) {
      debugPrint('Error al obtener usuarios por mes: $e');
      return [];
    }
  }
}