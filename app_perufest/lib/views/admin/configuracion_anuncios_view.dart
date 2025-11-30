import 'package:flutter/material.dart';
import '../../services/anuncios_control_service.dart';

/// Pantalla para configurar la experiencia de anuncios desde el panel de administrador
class ConfiguracionAnunciosView extends StatefulWidget {
  const ConfiguracionAnunciosView({super.key});

  @override
  State<ConfiguracionAnunciosView> createState() => _ConfiguracionAnunciosViewState();
}

class _ConfiguracionAnunciosViewState extends State<ConfiguracionAnunciosView> {
  Map<String, dynamic> _config = {};
  Map<String, dynamic> _estadisticas = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    
    try {
      final config = await AnunciosControlService.obtenerConfiguracion();
      final stats = await AnunciosControlService.obtenerEstadisticas();
      
      setState(() {
        _config = config;
        _estadisticas = stats;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _guardarConfiguracion() async {
    try {
      await AnunciosControlService.guardarConfiguracion(_config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Anuncios'),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarConfiguracion,
            tooltip: 'Guardar configuración',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEstadisticasCard(),
                  const SizedBox(height: 16),
                  _buildConfiguracionGeneralCard(),
                  const SizedBox(height: 16),
                  _buildLimitesCard(),
                  const SizedBox(height: 16),
                  _buildZonasCard(),
                  const SizedBox(height: 16),
                  _buildAccionesCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildEstadisticasCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Estadísticas de Hoy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Anuncios Mostrados',
                    '${_estadisticas['total_hoy'] ?? 0}',
                    Icons.visibility,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Última Hora',
                    '${_estadisticas['total_ultima_hora'] ?? 0}',
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            if (_estadisticas['por_zona'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Por Zona:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...((_estadisticas['por_zona'] as Map<String, dynamic>).entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('• ${entry.key}'),
                      Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String titulo, String valor, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(fontSize: 12, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracionGeneralCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Configuración General',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Anuncios Habilitados'),
              subtitle: const Text('Activar/desactivar todos los anuncios en la app'),
              value: _config['anuncios_habilitados'] ?? true,
              onChanged: (value) {
                setState(() {
                  _config['anuncios_habilitados'] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitesCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.red.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Límites de Frecuencia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSliderConfig(
              'Máximo por día',
              _config['max_por_dia'] ?? 15,
              1,
              50,
              (value) => _config['max_por_dia'] = value.round(),
            ),
            _buildSliderConfig(
              'Máximo por hora',
              _config['max_por_hora'] ?? 5,
              1,
              20,
              (value) => _config['max_por_hora'] = value.round(),
            ),
            _buildSliderConfig(
              'Minutos entre anuncios',
              _config['minutos_entre_anuncios'] ?? 3,
              1,
              30,
              (value) => _config['minutos_entre_anuncios'] = value.round(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderConfig(
    String titulo,
    dynamic valor,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${valor}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: (valor ?? min).toDouble(),
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: (value) {
            setState(() {
              onChanged(value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildZonasCard() {
    final zonas = ['eventos', 'actividades', 'noticias', 'general'];
    final zonasHabilitadas = List<String>.from(_config['zonas_habilitadas'] ?? zonas);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Zonas de Anuncios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...zonas.map((zona) {
              return CheckboxListTile(
                title: Text(zona.toUpperCase()),
                value: zonasHabilitadas.contains(zona),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      zonasHabilitadas.add(zona);
                    } else {
                      zonasHabilitadas.remove(zona);
                    }
                    _config['zonas_habilitadas'] = zonasHabilitadas;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionesCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Acciones de Mantenimiento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _limpiarRegistros,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Limpiar Registros Antiguos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pausarAnunciosTemporalmente,
                icon: const Icon(Icons.pause),
                label: const Text('Pausar por 1 Hora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar Estadísticas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _limpiarRegistros() async {
    try {
      await AnunciosControlService.limpiarRegistrosAntiguos();
      _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registros antiguos limpiados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pausarAnunciosTemporalmente() async {
    try {
      await AnunciosControlService.pausarAnuncios(
        duracion: const Duration(hours: 1),
      );
      _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anuncios pausados por 1 hora'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}