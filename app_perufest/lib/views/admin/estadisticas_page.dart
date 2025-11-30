import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/estadisticas_service.dart';
import '../../models/estadisticas.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  EstadisticasGenerales? _estadisticasGenerales;
  EstadisticasAgenda? _estadisticasAgenda;
  EstadisticasPorFecha? _estadisticasFecha;
  Map<String, int> _eventosPorCategoria = {};
  Map<String, int> _actividadesPorZona = {};
  List<UsuariosPorMes> _usuariosPorMes = [];
  
  bool _isLoading = false;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Cambiamos de 4 a 3 tabs (eliminamos Tendencias)
    _tabController = TabController(length: 3, vsync: this);
    _cargarEstadisticas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _isLoading = true);
    
    try {
      final futures = await Future.wait([
        EstadisticasService.obtenerEstadisticasGenerales(),
        EstadisticasService.obtenerEstadisticasAgenda(),
        EstadisticasService.obtenerEstadisticasPorFecha(
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        ),
        EstadisticasService.obtenerEventosPorCategoria(),
        EstadisticasService.obtenerActividadesPorZona(),
        EstadisticasService.obtenerUsuariosPorMes(),
      ]);

      setState(() {
        _estadisticasGenerales = futures[0] as EstadisticasGenerales;
        _estadisticasAgenda = futures[1] as EstadisticasAgenda;
        _estadisticasFecha = futures[2] as EstadisticasPorFecha;
        _eventosPorCategoria = futures[3] as Map<String, int>;
        _actividadesPorZona = futures[4] as Map<String, int>;
        _usuariosPorMes = futures[5] as List<UsuariosPorMes>;
      });
    } catch (e) {
      _mostrarError('Error al cargar estadísticas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fechaInicio, end: _fechaFin),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B1B1B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (rango != null) {
      setState(() {
        _fechaInicio = rango.start;
        _fechaFin = rango.end;
      });
      _cargarEstadisticas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header con filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Estadísticas del Sistema',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _seleccionarRangoFechas,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: const Text('Filtrar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B1B1B),
                    side: const BorderSide(color: Color(0xFF8B1B1B)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _cargarEstadisticas,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF8B1B1B),
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs (ahora solo 3)
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF8B1B1B),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF8B1B1B),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'General'),
                Tab(icon: Icon(Icons.event_note), text: 'Agenda'),
                Tab(icon: Icon(Icons.analytics), text: 'Análisis'),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B1B1B)),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralTab(),
                      _buildAgendaTab(),
                      _buildAnalisisTab(), // Eliminamos _buildTendenciasTab()
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    if (_estadisticasGenerales == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards de métricas principales con aspectRatio corregido
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Usuarios Registrados',
                      _estadisticasGenerales!.totalUsuarios.toString(),
                      Icons.people,
                      Colors.blue,
                      subtitle: '+${_estadisticasGenerales!.usuariosNuevosSemana} esta semana',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Eventos Activos',
                      '${_estadisticasGenerales!.eventosActivos}/${_estadisticasGenerales!.totalEventos}',
                      Icons.event,
                      Colors.green,
                      subtitle: 'Total de eventos',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Actividades',
                      _estadisticasGenerales!.totalActividades.toString(),
                      Icons.local_activity,
                      Colors.orange,
                      subtitle: 'Programadas',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Noticias',
                      _estadisticasGenerales!.totalNoticias.toString(),
                      Icons.article,
                      Colors.purple,
                      subtitle: '+${_estadisticasGenerales!.noticiasDelMes} este mes',
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Información del filtro de fechas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1B1B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF8B1B1B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Filtro activo: del ${_formatDate(_fechaInicio)} al ${_formatDate(_fechaFin)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B1B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Métricas del período filtrado
          if (_estadisticasFecha != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actividad en el Período Seleccionado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallMetricCard(
                          'Noticias',
                          _estadisticasFecha!.noticiasPublicadas.toString(),
                          Icons.article,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSmallMetricCard(
                          'Eventos',
                          _estadisticasFecha!.eventosCreados.toString(),
                          Icons.event,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSmallMetricCard(
                          'Actividades',
                          _estadisticasFecha!.actividadesCreadas.toString(),
                          Icons.local_activity,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
          
          // Gráfico de usuarios por mes
          _buildUsuariosPorMesChart(),
          
          const SizedBox(height: 24),
          
          // Eventos por categoría
          _buildEventosPorCategoriaChart(),
        ],
      ),
    );
  }

  Widget _buildAgendaTab() {
    if (_estadisticasAgenda == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métricas de agenda
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Usuarios con Agenda',
                  _estadisticasAgenda!.totalUsuariosConAgenda.toString(),
                  Icons.event_note,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Promedio por Usuario',
                  _estadisticasAgenda!.promedioActividadesPorUsuario.toString(),
                  Icons.trending_up,
                  Colors.teal,
                  subtitle: 'actividades',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Lista de actividades populares
          _buildActividadesPopulares(),
        ],
      ),
    );
  }

  Widget _buildAnalisisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actividades por zona
          _buildActividadesPorZonaChart(),
          
          const SizedBox(height: 24),
          
          // Resumen de anuncios activos
          _buildResumenAnuncios(),
        ],
      ),
    );
  }

  // Widget corregido para las tarjetas principales
Widget _buildMetricCard(
  String title,
  String value,
  IconData icon,
  Color color, {
  String? subtitle,
}) {
  return Container(
    padding: const EdgeInsets.all(20), // Aumentado a 20
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Se adapta al contenido
      children: [
        // Icono
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        
        const SizedBox(height: 11), // Espacio fijo entre icono y contenido
        
        // Valor principal
        Text(
          value,
          style: const TextStyle(
            fontSize: 20, // Más grande
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 8),
        
        // Título
        Text(
          title,
          style: TextStyle(
            fontSize: 13, // Más grande
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Subtítulo opcional
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13, // Más grande
              color: Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    ),
  );
}

  // Nuevo widget para tarjetas pequeñas
  Widget _buildSmallMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUsuariosPorMesChart() {
    if (_usuariosPorMes.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registros de Usuarios por Mes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < _usuariosPorMes.length) {
                          final mes = _usuariosPorMes[value.toInt()].mes;
                          return Text(
                            mes.substring(5),
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _usuariosPorMes
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.cantidad.toDouble()))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF8B1B1B),
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF8B1B1B).withOpacity(0.1),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF8B1B1B),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActividadesPopulares() {
    if (_estadisticasAgenda?.actividadesPopulares.isEmpty ?? true) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay actividades en agenda aún',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividades Más Populares',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...(_estadisticasAgenda?.actividadesPopulares ?? []).take(5).map((actividad) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1B1B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        actividad.cantidadUsuarios.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B1B1B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actividad.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          actividad.zona,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${actividad.cantidadUsuarios} usuarios',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEventosPorCategoriaChart() {
    if (_eventosPorCategoria.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay eventos por categoría aún',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final colores = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Eventos por Categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _eventosPorCategoria.entries.map((entry) {
                  final index = _eventosPorCategoria.keys.toList().indexOf(entry.key);
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${entry.value}',
                    color: colores[index % colores.length],
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _eventosPorCategoria.entries.map((entry) {
              final index = _eventosPorCategoria.keys.toList().indexOf(entry.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colores[index % colores.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

Widget _buildActividadesPorZonaChart() {
  if (_actividadesPorZona.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay actividades por zona aún',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ordenar zonas por cantidad de actividades (mayor a menor)
  final zonasOrdenadas = _actividadesPorZona.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final maxActividades = zonasOrdenadas.first.value;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividades por Zona',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        
        // Lista de zonas con barras horizontales
        ...zonasOrdenadas.map((zona) {
          final porcentaje = zona.value / maxActividades;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        zona.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1B1B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${zona.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B1B1B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: porcentaje,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1B1B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    ),
  );
}

  Widget _buildResumenAnuncios() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1B1B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.campaign,
                  color: Color(0xFF8B1B1B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Resumen del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_estadisticasGenerales != null) ...[
            Text(
              'El sistema cuenta actualmente con ${_estadisticasGenerales!.totalUsuarios} usuarios registrados, '
              '${_estadisticasGenerales!.eventosActivos} eventos activos de un total de ${_estadisticasGenerales!.totalEventos}, '
              '${_estadisticasGenerales!.totalActividades} actividades programadas y ${_estadisticasGenerales!.totalNoticias} noticias publicadas.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'En la última semana se registraron ${_estadisticasGenerales!.usuariosNuevosSemana} nuevos usuarios '
              'y este mes se han publicado ${_estadisticasGenerales!.noticiasDelMes} noticias.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}