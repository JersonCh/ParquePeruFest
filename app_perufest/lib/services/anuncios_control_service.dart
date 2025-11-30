import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Servicio para controlar la frecuencia y experiencia de visualización de anuncios
class AnunciosControlService {
  static const String _keyVistosHoy = 'anuncios_vistos_hoy';
  static const String _keyUltimaVez = 'ultima_vez_anuncio';
  static const String _keyConfiguracion = 'config_anuncios';

  // Límites por defecto para no saturar al usuario
  static const int maxAnunciosPorDia = 15;
  static const int maxAnunciosPorHora = 5;
  static const int minutosMinimoEntreMostrar = 3;

  /// Configuración personalizable de anuncios
  static Future<Map<String, dynamic>> obtenerConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_keyConfiguracion);
    
    if (configJson != null) {
      return Map<String, dynamic>.from(jsonDecode(configJson));
    }
    
    // Configuración por defecto
    return {
      'anuncios_habilitados': true,
      'max_por_dia': maxAnunciosPorDia,
      'max_por_hora': maxAnunciosPorHora,
      'minutos_entre_anuncios': minutosMinimoEntreMostrar,
      'zonas_habilitadas': ['eventos', 'actividades', 'noticias', 'general'],
      'tipos_habilitados': ['banner', 'compacto'],
    };
  }

  /// Guardar configuración de anuncios
  static Future<void> guardarConfiguracion(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConfiguracion, jsonEncode(config));
  }

  /// Verificar si se puede mostrar un anuncio
  static Future<bool> puedesMostrarAnuncio({
    required String zona,
    required String tipo,
  }) async {
    try {
      final config = await obtenerConfiguracion();
      
      // Verificar si los anuncios están habilitados
      if (!(config['anuncios_habilitados'] ?? true)) {
        return false;
      }

      // Verificar si la zona está habilitada
      final zonasHabilitadas = List<String>.from(config['zonas_habilitadas'] ?? []);
      if (!zonasHabilitadas.contains(zona)) {
        return false;
      }

      // Verificar si el tipo está habilitado
      final tiposHabilitados = List<String>.from(config['tipos_habilitados'] ?? []);
      if (!tiposHabilitados.contains(tipo)) {
        return false;
      }

      // Verificar límites de tiempo
      final ahora = DateTime.now();
      final prefs = await SharedPreferences.getInstance();

      // Verificar tiempo mínimo entre anuncios
      final ultimaVezStr = prefs.getString(_keyUltimaVez);
      if (ultimaVezStr != null) {
        final ultimaVez = DateTime.parse(ultimaVezStr);
        final minutosDesdeLaUltima = ahora.difference(ultimaVez).inMinutes;
        final minimoRequerido = config['minutos_entre_anuncios'] ?? minutosMinimoEntreMostrar;
        
        if (minutosDesdeLaUltima < minimoRequerido) {
          return false;
        }
      }

      // Verificar límites diarios y por hora
      final vistosHoy = await _obtenerAnunciosVistosHoy();
      final maxDia = config['max_por_dia'] ?? maxAnunciosPorDia;
      final maxHora = config['max_por_hora'] ?? maxAnunciosPorHora;

      // Filtrar anuncios de hoy
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final anunciosHoy = vistosHoy.where((v) {
        final fechaVisto = DateTime.parse(v['timestamp']);
        final diaVisto = DateTime(fechaVisto.year, fechaVisto.month, fechaVisto.day);
        return diaVisto.isAtSameMomentAs(hoy);
      }).toList();

      if (anunciosHoy.length >= maxDia) {
        return false;
      }

      // Filtrar anuncios de la última hora
      final unaHoraAtras = ahora.subtract(const Duration(hours: 1));
      final anunciosUltimaHora = vistosHoy.where((v) {
        final fechaVisto = DateTime.parse(v['timestamp']);
        return fechaVisto.isAfter(unaHoraAtras);
      }).toList();

      if (anunciosUltimaHora.length >= maxHora) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error verificando si se puede mostrar anuncio: $e');
      return true; // En caso de error, permitir mostrar
    }
  }

  /// Registrar que se ha mostrado un anuncio
  static Future<void> registrarAnuncioMostrado({
    required String anuncioId,
    required String zona,
    required String tipo,
  }) async {
    try {
      final ahora = DateTime.now();
      final prefs = await SharedPreferences.getInstance();

      // Actualizar última vez que se mostró un anuncio
      await prefs.setString(_keyUltimaVez, ahora.toIso8601String());

      // Agregar a la lista de anuncios vistos
      final vistosHoy = await _obtenerAnunciosVistosHoy();
      vistosHoy.add({
        'id': anuncioId,
        'zona': zona,
        'tipo': tipo,
        'timestamp': ahora.toIso8601String(),
      });

      // Mantener solo los últimos 50 registros para no saturar memoria
      if (vistosHoy.length > 50) {
        vistosHoy.removeRange(0, vistosHoy.length - 50);
      }

      // Guardar la lista actualizada
      await prefs.setString(_keyVistosHoy, jsonEncode(vistosHoy));
    } catch (e) {
      print('Error registrando anuncio mostrado: $e');
    }
  }

  /// Obtener estadísticas de anuncios vistos
  static Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final vistosHoy = await _obtenerAnunciosVistosHoy();
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final unaHoraAtras = ahora.subtract(const Duration(hours: 1));

      final anunciosHoy = vistosHoy.where((v) {
        final fechaVisto = DateTime.parse(v['timestamp']);
        final diaVisto = DateTime(fechaVisto.year, fechaVisto.month, fechaVisto.day);
        return diaVisto.isAtSameMomentAs(hoy);
      }).toList();

      final anunciosUltimaHora = vistosHoy.where((v) {
        final fechaVisto = DateTime.parse(v['timestamp']);
        return fechaVisto.isAfter(unaHoraAtras);
      }).toList();

      // Estadísticas por zona
      final porZona = <String, int>{};
      for (final anuncio in anunciosHoy) {
        final zona = anuncio['zona'] ?? 'desconocida';
        porZona[zona] = (porZona[zona] ?? 0) + 1;
      }

      return {
        'total_hoy': anunciosHoy.length,
        'total_ultima_hora': anunciosUltimaHora.length,
        'por_zona': porZona,
        'config': await obtenerConfiguracion(),
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {};
    }
  }

  /// Limpiar registros antiguos (llamar periódicamente)
  static Future<void> limpiarRegistrosAntiguos() async {
    try {
      final vistosHoy = await _obtenerAnunciosVistosHoy();
      final tresDiasAtras = DateTime.now().subtract(const Duration(days: 3));

      // Filtrar solo registros de los últimos 3 días
      final registrosFiltrados = vistosHoy.where((v) {
        final fechaVisto = DateTime.parse(v['timestamp']);
        return fechaVisto.isAfter(tresDiasAtras);
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyVistosHoy, jsonEncode(registrosFiltrados));
    } catch (e) {
      print('Error limpiando registros antiguos: $e');
    }
  }

  /// Obtener anuncios vistos hoy (método privado)
  static Future<List<Map<String, dynamic>>> _obtenerAnunciosVistosHoy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vistosJson = prefs.getString(_keyVistosHoy);
      
      if (vistosJson != null) {
        final vistosData = jsonDecode(vistosJson);
        return List<Map<String, dynamic>>.from(vistosData);
      }
      
      return [];
    } catch (e) {
      print('Error obteniendo anuncios vistos: $e');
      return [];
    }
  }

  /// Desactivar anuncios temporalmente (por ejemplo, durante una compra)
  static Future<void> pausarAnuncios({Duration? duracion}) async {
    final config = await obtenerConfiguracion();
    config['anuncios_habilitados'] = false;
    
    if (duracion != null) {
      config['pausado_hasta'] = DateTime.now().add(duracion).toIso8601String();
    }
    
    await guardarConfiguracion(config);
  }

  /// Reactivar anuncios
  static Future<void> reanudarAnuncios() async {
    final config = await obtenerConfiguracion();
    config['anuncios_habilitados'] = true;
    config.remove('pausado_hasta');
    await guardarConfiguracion(config);
  }

  /// Verificar si los anuncios están pausados temporalmente
  static Future<bool> anunciosPausados() async {
    final config = await obtenerConfiguracion();
    
    if (!(config['anuncios_habilitados'] ?? true)) {
      // Verificar si hay una fecha límite para la pausa
      final pausadoHastaStr = config['pausado_hasta'];
      if (pausadoHastaStr != null) {
        final pausadoHasta = DateTime.parse(pausadoHastaStr);
        if (DateTime.now().isAfter(pausadoHasta)) {
          // La pausa expiró, reactivar anuncios
          await reanudarAnuncios();
          return false;
        }
      }
      return true;
    }
    
    return false;
  }
}