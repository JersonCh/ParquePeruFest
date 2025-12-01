import 'dart:ui';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../models/evento.dart';
import '../../models/zona_mapa.dart';
import '../../services/eventos_service.dart';
import '../../services/zonas_service.dart';


class MapaView extends StatefulWidget {
  const MapaView({super.key});

  @override
  State<MapaView> createState() => _MapaViewState();
}

class _MapaViewState extends State<MapaView> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  List<Evento> _eventos = [];
  List<ZonaMapa> _zonas = [];
  Evento? _eventoSeleccionado;
  bool _cargando = true;
  late AnimationController _pulseController;
  LatLng? _ubicacionActual;
  bool _obteniendoUbicacion = false;
  ZonaMapa? _zonaSeleccionadaParaNavegacion;
  List<LatLng> _rutaPuntos = [];
  bool _mostrandoRuta = false;
  ZonaMapa? _zonaDestinoRuta;
  
  // Coordenadas del Parque Perú-Tacna
  static const LatLng _parquePeruTacna = LatLng(-17.9949, -70.2120);
  
  // Token público de Mapbox
  static const String _mapboxAccessToken = 'pk.eyJ1IjoiYW5kcmVzZWJhc3QxNiIsImEiOiJjbWltZ3d6NXowZHJkM2xvb3dhZmZyNmJlIn0.HpvsuqONO1Map7ah_K73dA';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _cargarEventos();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _cargarEventos() async {
    try {
      final eventos = await EventosService.obtenerEventos();
      if (mounted) {
        setState(() {
          _eventos = eventos.where((e) => e.estaActivo).toList();
          _eventoSeleccionado = _eventos.isNotEmpty ? _eventos.first : null;
          _cargando = false;
        });
      }
      if (_eventoSeleccionado != null) {
        await _cargarZonasDeEvento(_eventoSeleccionado!.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error de Conexión',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'No pudimos cargar los eventos. Verifica tu conexión.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _cargarZonasDeEvento(String eventoId) async {
    try {
      debugPrint('Cargando zonas para evento: $eventoId');
      final zonas = await ZonasService.obtenerZonasPorEvento(eventoId);
      debugPrint('Zonas cargadas: ${zonas.length}');
      for (var zona in zonas) {
        debugPrint('Zona: ${zona.nombre} en (${zona.ubicacion.latitude}, ${zona.ubicacion.longitude})');
      }
      if (mounted) {
        setState(() {
          _zonas = zonas;
        });
        _actualizarMarcadores();
      }
    } catch (e) {
      debugPrint('Error al cargar zonas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error al Cargar Zonas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Hubo un problema al cargar las zonas del evento',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF8F00),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Fondo claro consistente
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B1B1B),
              ),
            )
          : Stack(
              children: [
                // Mapa en toda la pantalla
                _buildFullScreenMap(),
                // Selector flotante encima del mapa
                _buildFloatingEventSelector(),
              ],
            ),
    );
  }

  Widget _buildFloatingEventSelector() {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8B1B1B),
                              Color(0xFFA52A2A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seleccionar Evento',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Explora las zonas del parque',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: DropdownButton<Evento>(
                      value: _eventoSeleccionado,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 6,
                      icon: const Icon(
                        Icons.expand_more_rounded,
                        color: Color(0xFF6B7280),
                        size: 24,
                      ),
                      hint: const Text(
                        'Selecciona un evento',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      items: _eventos.map((evento) {
                        return DropdownMenuItem<Evento>(
                          value: evento,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              evento.nombre,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (Evento? evento) {
                        if (mounted) {
                          setState(() {
                            _eventoSeleccionado = evento;
                          });
                        }
                        if (evento != null) {
                          _cargarZonasDeEvento(evento.id);
                        } else {
                          if (mounted) {
                            setState(() {
                              _zonas = [];
                            });
                            _actualizarMarcadores();
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildFullScreenMap() {
    return Container(
      color: const Color(0xFFF5F5F5), // Fondo claro para toda la pantalla
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5), // Fondo del mapa
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _parquePeruTacna,
                initialZoom: 16.0, // Zoom más amplio para mostrar más área
                minZoom: 14.0, // Permitir zoom más alejado
                maxZoom: 20.0, // Permitir zoom más cercano
                backgroundColor: const Color(0xFFF5F5F5), // Fondo claro cuando no hay tiles
                onMapEvent: (event) {
                  if (event is MapEventMoveEnd) {
                    final center = event.camera.center;
                    // Límites más amplios para mayor libertad de movimiento
                    if ((center.latitude - _parquePeruTacna.latitude).abs() > 0.01 ||
                        (center.longitude - _parquePeruTacna.longitude).abs() > 0.01) {
                      if (!_mostrandoRuta) { // No recentrar si se está mostrando una ruta
                        _centrarMapa();
                      }
                    }
                  }
                },
              ),
                      children: [
                        // Capa de tiles usando Mapbox
                        TileLayer(
                          urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}@2x?access_token=$_mapboxAccessToken',
                          userAgentPackageName: 'com.example.app_perufest',
                          maxZoom: 19,
                          tileSize: 512,
                          zoomOffset: -1,
                          backgroundColor: const Color(0xFFF5F5F5), // Fondo claro para este estilo
                          errorTileCallback: (tile, error, stackTrace) {
                            // Manejo de errores en tiles
                            debugPrint('Error cargando tile: $error');
                          },
                          additionalOptions: const {
                            'accessToken': _mapboxAccessToken,
                            'attribution': '© Mapbox',
                          },
                        ),
                        
                        // Capa de la ruta (debe ir antes de los marcadores)
                        if (_rutaPuntos.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              // Línea de borde para mejor visibilidad
                              Polyline(
                                points: _rutaPuntos,
                                strokeWidth: 6.0,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              // Línea principal
                              Polyline(
                                points: _rutaPuntos,
                                strokeWidth: 3.0,
                                color: const Color(0xFF8B1B1B),
                              ),
                            ],
                          ),
                        
                        // Marcadores de las zonas
                        MarkerLayer(
                          markers: _zonas.map((zona) => Marker(
                            point: zona.ubicacion,
                            width: 64,
                            height: 64,
                            child: GestureDetector(
                              onTap: () {
                                _mostrarInfoZona(zona);
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Pin del marcador con efecto de pulso
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Efecto de pulso
                                      AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Container(
                                            width: 44 + (20 * _pulseController.value),
                                            height: 44 + (20 * _pulseController.value),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFF8B1B1B).withOpacity(
                                                0.3 * (1 - _pulseController.value),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Marcador principal
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF8B1B1B),
                                              Color(0xFFA52A2A),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF8B1B1B).withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),

                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                        
                        // Marcador de ubicación actual
                        if (_ubicacionActual != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _ubicacionActual!,
                                width: 50,
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.my_location_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
          ),
        
        // Controles elegantes del mapa
        Positioned(
          right: 16,
          bottom: 110,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapControlButton(
                  icon: Icons.add_rounded,
                  onPressed: () => _zoomIn(),
                  heroTag: "zoomIn",
                  tooltip: 'Acercar',
                ),
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.grey.withOpacity(0.2),
                ),
                _buildMapControlButton(
                  icon: Icons.remove_rounded,
                  onPressed: () => _zoomOut(),
                  heroTag: "zoomOut",
                  tooltip: 'Alejar',
                ),
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.grey.withOpacity(0.2),
                ),
                _buildMapControlButton(
                  icon: Icons.my_location_rounded,
                  onPressed: () => _centrarMapa(),
                  heroTag: "center",
                  tooltip: 'Centrar',
                ),
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.grey.withOpacity(0.2),
                ),
                _buildMapControlButton(
                  icon: _obteniendoUbicacion ? Icons.hourglass_empty_rounded : Icons.person_pin_circle_rounded,
                  onPressed: _obteniendoUbicacion ? null : () => _obtenerUbicacionActual(),
                  heroTag: "location",
                  tooltip: 'Mi Ubicación',
                ),
              ],
            ),
          ),
        ),
        
        // Botón elegante para cerrar ruta (cuando hay ruta activa)
        if (_mostrandoRuta)
          Positioned(
            top: MediaQuery.of(context).padding.top + 160,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF4444),
                    Color(0xFFCC0000),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4444).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Tooltip(
                  message: 'Cerrar Ruta',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      // Agregar vibración táctil
                      _limpiarRuta();
                    },
                  child: Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Círculo de fondo sutil
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        // Icono principal
                        const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ),
            ),
          ),
        
        // Indicador discreto de Mapbox
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Mapbox',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }



  void _centrarMapa() {
    _mapController.move(_parquePeruTacna, 16.0); // Usar el mismo zoom inicial
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 0.5);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 0.5);
  }

  void _actualizarMarcadores() {
    // Los marcadores se actualizan automáticamente con MarkerLayer
    if (mounted) {
      setState(() {
        // Forzar rebuild para actualizar marcadores
      });
    }
  }

  // Función para obtener y mostrar la ruta
  Future<void> _mostrarRutaHasta(ZonaMapa zona) async {
    if (_ubicacionActual == null) {
      await _obtenerUbicacionActual();
      if (_ubicacionActual == null) {
        _mostrarDialogoError('Ubicación requerida', 
          'Se necesita tu ubicación actual para calcular la ruta.');
        return;
      }
    }

    setState(() {
      _mostrandoRuta = true;
      _zonaDestinoRuta = zona;
    });

    try {
      // Obtener la ruta usando OSRM (gratuito)
      final ruta = await _obtenerRutaOSRM(_ubicacionActual!, zona.ubicacion);
      
      if (ruta.isNotEmpty) {
        setState(() {
          _rutaPuntos = ruta;
        });
        
        // Ajustar el mapa para mostrar toda la ruta
        _ajustarMapaParaRuta();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '¡Ruta Encontrada!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Sigue la línea roja para llegar a tu destino',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2D7D32),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              action: SnackBarAction(
                label: 'Cerrar',
                textColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                onPressed: _limpiarRuta,
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _mostrandoRuta = false;
      });
      _mostrarDialogoError('Error de ruta', 
        'No se pudo calcular la ruta. Verifica tu conexión a internet.');
    }
  }

  // Obtener ruta usando OSRM API (gratuita)
  Future<List<LatLng>> _obtenerRutaOSRM(LatLng origen, LatLng destino) async {
    try {
      final url = 'http://router.project-osrm.org/route/v1/driving/'
          '${origen.longitude},${origen.latitude};'
          '${destino.longitude},${destino.latitude}'
          '?steps=true&geometries=geojson&overview=full';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final coordinates = geometry['coordinates'] as List;
          
          return coordinates.map<LatLng>((coord) => 
            LatLng(coord[1].toDouble(), coord[0].toDouble())
          ).toList();
        }
      }
      
      // Si falla la API, crear una línea directa
      return [origen, destino];
    } catch (e) {
      // Fallback: línea directa
      return [origen, destino];
    }
  }

  // Ajustar el mapa para mostrar toda la ruta
  void _ajustarMapaParaRuta() {
    if (_rutaPuntos.isEmpty || _ubicacionActual == null) return;

    double minLat = _rutaPuntos.first.latitude;
    double maxLat = _rutaPuntos.first.latitude;
    double minLng = _rutaPuntos.first.longitude;
    double maxLng = _rutaPuntos.first.longitude;

    for (final punto in _rutaPuntos) {
      minLat = math.min(minLat, punto.latitude);
      maxLat = math.max(maxLat, punto.latitude);
      minLng = math.min(minLng, punto.longitude);
      maxLng = math.max(maxLng, punto.longitude);
    }

    // Añadir padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    final bounds = LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    _mapController.fitCamera(CameraFit.bounds(bounds: bounds));
  }

  // Limpiar la ruta
  void _limpiarRuta() {
    setState(() {
      _rutaPuntos.clear();
      _mostrandoRuta = false;
      _zonaDestinoRuta = null;
    });
  }

  // Función para obtener ubicación actual
  Future<void> _obtenerUbicacionActual() async {
    if (_obteniendoUbicacion) return;

    setState(() {
      _obteniendoUbicacion = true;
    });

    try {
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _mostrarDialogoError('Servicios de ubicación deshabilitados', 
          'Por favor, habilita los servicios de ubicación en tu dispositivo.');
        return;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _mostrarDialogoError('Permisos denegados', 
            'Los permisos de ubicación fueron denegados.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _mostrarDialogoError('Permisos denegados permanentemente', 
          'Los permisos de ubicación fueron denegados permanentemente. Habilítalos en configuración.');
        return;
      }

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _ubicacionActual = LatLng(position.latitude, position.longitude);
      });

      // Mover el mapa a la ubicación actual
      _mapController.move(_ubicacionActual!, 16.0);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¡Te Encontramos!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Tu ubicación ha sido localizada exitosamente',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1976D2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _mostrarDialogoError('Error de ubicación', 
        'No se pudo obtener tu ubicación. Verifica tu conexión GPS.');
    } finally {
      setState(() {
        _obteniendoUbicacion = false;
      });
    }
  }

  // Función para navegar a una zona específica
  Future<void> _navegarAZona(ZonaMapa zona) async {
    setState(() {
      _zonaSeleccionadaParaNavegacion = zona;
    });

    if (_ubicacionActual == null) {
      await _obtenerUbicacionActual();
      if (_ubicacionActual == null) return;
    }

    // Mostrar diálogo con opciones de navegación
    _mostrarOpcionesNavegacion(zona);
  }

  void _mostrarOpcionesNavegacion(ZonaMapa zona) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1B1B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navegar a ${zona.nombre}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Escoge tu aplicación preferida',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Nueva opción para mostrar ruta en el mapa
            SizedBox(
              width: double.infinity,
              child: _buildNavigationOption(
                'Ver Ruta en Mapa',
                Icons.route_rounded,
                () {
                  Navigator.pop(context);
                  _mostrarRutaHasta(zona);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNavigationOption(
                    'Google Maps',
                    Icons.map_rounded,
                    () => _abrirEnGoogleMaps(zona),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavigationOption(
                    'Waze',
                    Icons.directions_car_rounded,
                    () => _abrirEnWaze(zona),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildNavigationOption(
                'Ver en Mapa',
                Icons.center_focus_strong_rounded,
                () {
                  Navigator.pop(context);
                  _centrarEnZona(zona);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationOption(String titulo, IconData icono, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: const Color(0xFF8B1B1B), size: 20),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Abrir en Google Maps
  Future<void> _abrirEnGoogleMaps(ZonaMapa zona) async {
    Navigator.pop(context);
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${zona.ubicacion.latitude},${zona.ubicacion.longitude}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // Abrir en Waze
  Future<void> _abrirEnWaze(ZonaMapa zona) async {
    Navigator.pop(context);
    final url = 'https://waze.com/ul?ll=${zona.ubicacion.latitude},${zona.ubicacion.longitude}&navigate=yes';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // Centrar en zona específica
  void _centrarEnZona(ZonaMapa zona) {
    _mapController.move(LatLng(zona.ubicacion.latitude, zona.ubicacion.longitude), 18.0);
  }

  void _mostrarDialogoError(String titulo, String mensaje) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF3E0),
                  Color(0xFFFFE0B2),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFFF6B35),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  mensaje,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1B1B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String heroTag,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6B7280),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarInfoZona(ZonaMapa zona) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle del modal
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Header con icono y título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8B1B1B), Color(0xFFA52A2A)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B1B1B).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zona.nombre,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1B1B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Zona del Evento',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B1B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Información de coordenadas
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1B1B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Color(0xFF8B1B1B),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Coordenadas GPS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Latitud: ${zona.ubicacion.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Longitud: ${zona.ubicacion.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navegarAZona(zona);
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text('Navegar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1B1B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B1B1B),
                        side: const BorderSide(color: Color(0xFF8B1B1B)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}