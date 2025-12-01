import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
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
          const SnackBar(
            content: Text('Error al cargar los eventos'),
            backgroundColor: Colors.red,
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
            content: Text('Error al cargar las zonas del evento: $e'),
            backgroundColor: Colors.red,
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
                initialZoom: 17.5,
                minZoom: 15.5,
                maxZoom: 19.0,
                backgroundColor: const Color(0xFFF5F5F5), // Fondo claro cuando no hay tiles
                onMapEvent: (event) {
                  if (event is MapEventMoveEnd) {
                    final center = event.camera.center;
                    // Mantener el mapa cerca del área del parque
                    if ((center.latitude - _parquePeruTacna.latitude).abs() > 0.003 ||
                        (center.longitude - _parquePeruTacna.longitude).abs() > 0.003) {
                      _centrarMapa();
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
                  icon: _obteniendoUbicacion ? Icons.hourglass_empty_rounded : Icons.gps_fixed_rounded,
                  onPressed: _obteniendoUbicacion ? null : () => _obtenerUbicacionActual(),
                  heroTag: "location",
                  tooltip: 'Mi Ubicación',
                ),
              ],
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
    _mapController.move(_parquePeruTacna, 17.5);
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
            content: const Text('Ubicación encontrada'),
            backgroundColor: const Color(0xFF8B1B1B),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
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
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido', style: TextStyle(color: Color(0xFF8B1B1B))),
            ),
          ],
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