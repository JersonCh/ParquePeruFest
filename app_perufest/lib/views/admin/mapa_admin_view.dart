import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/evento.dart';
import '../../models/zona_mapa.dart';
import '../../services/eventos_service.dart';
import '../../services/zonas_service.dart';

class MapaAdminView extends StatefulWidget {
  const MapaAdminView({super.key});

  @override
  State<MapaAdminView> createState() => _MapaAdminViewState();
}

class _MapaAdminViewState extends State<MapaAdminView> {
  final MapController _mapController = MapController();
  final TextEditingController _nombreZonaController = TextEditingController();



  void _centrarEnZona(LatLng ubicacion) {
    _mapController.move(ubicacion, 18.0);
  }

  void _actualizarMarcadores() {
    // Los marcadores se actualizan automáticamente con MarkerLayer
    if (mounted) {
      setState(() {
        // Forzar rebuild para actualizar marcadores
      });
    }
  }

  List<Evento> _eventos = [];
  List<ZonaMapa> _zonas = [];
  Evento? _eventoSeleccionado;
  LatLng? _ubicacionSeleccionada;
  bool _cargando = true;
  bool _guardando = false;
  
  // Coordenadas del Parque Perú-Tacna
  static const LatLng _parquePeruTacna = LatLng(-17.9949, -70.2120);

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  @override
  void dispose() {
    _nombreZonaController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _cargarEventos() async {
    try {
      final eventos = await EventosService.obtenerEventos();
      if (mounted) {
        setState(() {
          _eventos = eventos.where((e) => e.estaActivo).toList();
          _cargando = false;
        });
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
      final zonas = await ZonasService.obtenerZonasPorEvento(eventoId);
      if (mounted) {
        setState(() {
          _zonas = zonas;
        });
        _actualizarMarcadores();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar las zonas del evento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _guardarZona() async {
    if (_eventoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un evento primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_ubicacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una ubicación en el mapa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_nombreZonaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un nombre para la zona'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final nuevaZona = ZonaMapa(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreZonaController.text.trim(),
        eventoId: _eventoSeleccionado!.id,
        ubicacion: _ubicacionSeleccionada!,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      await ZonasService.crearZona(nuevaZona);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Zona guardada correctamente'),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        setState(() {
          _ubicacionSeleccionada = null;
          _nombreZonaController.clear();
        });

        await _cargarZonasDeEvento(_eventoSeleccionado!.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la zona: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Administrar Zonas del Mapa'),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de evento
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seleccionar Evento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Evento>(
                            value: _eventoSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Evento',
                              border: OutlineInputBorder(),
                            ),
                            items: _eventos.map((evento) {
                              return DropdownMenuItem<Evento>(
                                value: evento,
                                child: Text(evento.nombre),
                              );
                            }).toList(),
                            onChanged: (Evento? evento) {
                              setState(() {
                                _eventoSeleccionado = evento;
                                _zonas = [];
                                _ubicacionSeleccionada = null;
                              });
                              if (evento != null) {
                                _cargarZonasDeEvento(evento.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mapa
                  Card(
                    elevation: 2,
                    child: Container(
                      height: 400,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mapa Interactivo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Toca en el mapa para seleccionar la ubicación de una nueva zona',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _parquePeruTacna,
                                    initialZoom: 16.8,
                                    minZoom: 16.0,
                                    maxZoom: 19.0,
                                    onTap: (tapPosition, point) {
                                      // Solo permitir colocar puntos si hay un evento seleccionado
                                      if (_eventoSeleccionado != null) {
                                        setState(() {
                                          _ubicacionSeleccionada = point;
                                        });
                                        _actualizarMarcadores();
                                      }
                                    },
                                  ),
                                  children: [
                                    // Capa de tiles usando Mapbox
                                    TileLayer(
                                      urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiYW5kcmVzZWJhc3QxNiIsImEiOiJjbWltZ3d6NXowZHJkM2xvb3dhZmZyNmJlIn0.HpvsuqONO1Map7ah_K73dA',
                                      userAgentPackageName: 'com.example.app_perufest',
                                      maxZoom: 19,
                                      tileSize: 512,
                                      zoomOffset: -1,
                                      additionalOptions: const {
                                        'accessToken': 'pk.eyJ1IjoiYW5kcmVzZWJhc3QxNiIsImEiOiJjbWltZ3d6NXowZHJkM2xvb3dhZmZyNmJlIn0.HpvsuqONO1Map7ah_K73dA',
                                        'attribution': '© Mapbox',
                                      },
                                    ),

                                    // Marcador de ubicación seleccionada
                                    if (_ubicacionSeleccionada != null)
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _ubicacionSeleccionada!,
                                            width: 50,
                                            height: 50,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.9),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    blurRadius: 5,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.add_location,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                    // Marcadores de zonas existentes
                                    MarkerLayer(
                                      markers: _zonas.map((zona) {
                                        return Marker(
                                          point: zona.ubicacion,
                                          width: 120,
                                          height: 70,
                                          child: Column(
                                            children: [
                                              // Nombre de la zona
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  zona.nombre,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF8B1B1B),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // Icono del marcador
                                              GestureDetector(
                                                onTap: () => _centrarEnZona(zona.ubicacion),
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF8B1B1B).withOpacity(0.9),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.3),
                                                        blurRadius: 5,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.location_on,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Formulario para nueva zona
                  if (_ubicacionSeleccionada != null)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nueva Zona',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nombreZonaController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de la zona',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ubicación: ${_ubicacionSeleccionada!.latitude.toStringAsFixed(4)}, ${_ubicacionSeleccionada!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _guardando ? null : _guardarZona,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B1B1B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _guardando
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Guardar Zona'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Lista de zonas existentes
                  if (_zonas.isNotEmpty)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zonas Existentes (${_zonas.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...(_zonas.map((zona) => ListTile(
                              leading: const Icon(Icons.location_on, color: Color(0xFF8B1B1B)),
                              title: Text(zona.nombre),
                              subtitle: Text(
                                '${zona.ubicacion.latitude.toStringAsFixed(4)}, ${zona.ubicacion.longitude.toStringAsFixed(4)}',
                              ),
                              onTap: () => _centrarEnZona(zona.ubicacion),
                            ))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}