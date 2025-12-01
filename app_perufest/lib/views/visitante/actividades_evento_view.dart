import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/evento.dart';
import '../../models/actividad.dart';
import '../../viewmodels/actividades_viewmodel.dart';
import '../../viewmodels/agenda_viewmodel.dart';
import '../../widgets/anuncio_compacto.dart';
class ActividadesEventoView extends StatefulWidget {
  final Evento evento;
  final String userId; // Agregar userId como parámetro

  const ActividadesEventoView({
    super.key, 
    required this.evento,
    required this.userId,
  });
  @override
  State<ActividadesEventoView> createState() => _ActividadesEventoViewState();
}
class _ActividadesEventoViewState extends State<ActividadesEventoView>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<DateTime> _diasEvento = [];
  final List<Color> _colorPalette = [
    const Color(0xFF8B1B1B), // Guinda principal
    const Color(0xFFA52A2A), // Rojo-marrón
    const Color(0xFF8B0000), // Rojo oscuro
    const Color(0xFF800020), // Burgundy
    const Color(0xFF722F37), // Marrón-rojo
    const Color(0xFF9B1B1B), // Guinda claro
    const Color(0xFF7B1B1B), // Guinda oscuro
    const Color(0xFF8B2635), // Guinda-rosado
    const Color(0xFF8B3A3A), // Rojo tierra
    const Color(0xFF8B4B4B), // Rojo suave
  ];
  @override
  void initState() {
    super.initState();
    _configurarDiasEvento();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configurarAgenda();
      _cargarActividades();
    });
  }
  void _configurarDiasEvento() {
    final viewModel = context.read<ActividadesViewModel>();
    _diasEvento = viewModel.generarDiasDelEvento(
      widget.evento.fechaInicio,
      widget.evento.fechaFin,
    );

    _tabController = TabController(
      length: _diasEvento.length,
      vsync: this,
    );
  }
  void _configurarAgenda() {
    final agendaViewModel = context.read<AgendaViewModel>();
    agendaViewModel.configurarUsuario(widget.userId);
  }
  Future<void> _cargarActividades() async {
    final viewModel = context.read<ActividadesViewModel>();
    await viewModel.cargarActividadesPorEvento(widget.evento.id);

    // Verificar estado de agenda para todas las actividades
    final agendaViewModel = context.read<AgendaViewModel>();
    final actividadesIds = viewModel.actividades.map((a) => a.id).toList();
    await agendaViewModel.verificarEstadoActividades(actividadesIds);
  }
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ActividadesViewModel>(
        builder: (context, viewModel, child) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              if (viewModel.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando actividades...'),
                      ],
                    ),
                  ),
                )
              else if (viewModel.state == ActividadesState.error)
                SliverFillRemaining(
                  child: _buildErrorState(viewModel),
                )
              else
                _buildActividadesContent(viewModel),
            ],
          );
        },
      ),
    );
  }
  Widget _buildSliverAppBar() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 4),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 122, 0, 37),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Título principal
              Text(
                'ACTIVIDADES ${widget.evento.nombre.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              
              // Fecha
              Text(
                '${_formatearFecha(widget.evento.fechaInicio)} - ${_formatearFecha(widget.evento.fechaFin)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Decoración central con icono
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 1,
                    width: 40,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.event,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 1,
                    width: 40,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              // Subtítulo en contenedor redondeado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '"Todas las actividades del evento"',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Agregar las pestañas de fechas dentro de la cabecera
              if (_diasEvento.isNotEmpty) ...[
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  isScrollable: _diasEvento.length > 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  indicatorColor: Colors.white,
                  indicatorWeight: 2,
                  indicator: UnderlineTabIndicator(
                    borderSide: const BorderSide(width: 2, color: Colors.white),
                    insets: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: _diasEvento.map((dia) => Tab(
                    text: _formatearDiaTab(dia),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActividadesContent(ActividadesViewModel viewModel) {
    if (_diasEvento.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyDaysState(),
      );
    }
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: _diasEvento.map((dia) => _buildActividadesDia(viewModel, dia)).toList(),
      ),
    );
  }
  Widget _buildActividadesDia(ActividadesViewModel viewModel, DateTime dia) {
    final actividades = viewModel.obtenerActividadesDeDia(dia);
    if (actividades.isEmpty) {
      return _buildDiaSinActividades(dia);
    }
    actividades.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
    
    return RefreshIndicator(
      onRefresh: _cargarActividades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: actividades.length * 2, // Duplicar para intercalar anuncios
        itemBuilder: (context, index) {
          // Calcular índice real de actividad
          final actividadIndex = index ~/ 2;
          final isAnuncio = index.isOdd && actividadIndex < actividades.length;
          
            if (isAnuncio) {
              // No mostrar anuncios en la lista de actividades: devolver widget vacío
              return const SizedBox.shrink();
            } else {
            // Mostrar actividad
            if (actividadIndex >= actividades.length) {
              return const SizedBox.shrink();
            }
            
            final actividad = actividades[actividadIndex];
            final color = _colorPalette[actividadIndex % _colorPalette.length];
            return _buildTarjetaActividad(actividad, color);
          }
        },
      ),
    );
  }
  Widget _buildTarjetaActividad(Actividad actividad, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header compacto
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indicador de color y horario
                    Container(
                      width: 4,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Contenido principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Horario y zona en la misma línea
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  actividad.horario,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  actividad.zona,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Nombre de la actividad
                          Text(
                            actividad.nombre,
                            style: const TextStyle(
                              color: Color(0xFF2D2D2D),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Descripción en cuadro gris
                          if (actividad.descripcion.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                actividad.descripcion,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          // Duración en una línea compacta
                          Text(
                            'Duración: ${actividad.duracion}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Botones en la parte inferior
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón de valorar a la izquierda
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implementar valoración
                      },
                      icon: const Icon(Icons.star, size: 16, color: Colors.orange),
                      label: const Text('Valorar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade50,
                        foregroundColor: Colors.orange.shade700,
                        elevation: 2,
                        side: BorderSide(color: Colors.orange.shade200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    // Botón de agendar a la derecha
                    _buildBotonAgendarCompacto(actividad, color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Nuevo botón compacto para el diseño mejorado
  Widget _buildBotonAgendarCompacto(Actividad actividad, Color color) {
    return Consumer<AgendaViewModel>(
      builder: (context, agendaViewModel, child) {
        final estaEnAgenda = agendaViewModel.estaEnAgenda(actividad.id);
        final estaCargando = agendaViewModel.estaCargando(actividad.id);
        
        final ahora = DateTime.now();
        final yaInicio = ahora.isAfter(actividad.fechaInicio.add(const Duration(minutes: 1)));
        
        if (yaInicio && !estaEnAgenda) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Iniciada',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        
        return GestureDetector(
          onTap: estaCargando ? null : () => _manejarBotonAgendar(actividad),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: estaEnAgenda ? Colors.green : color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: estaCargando 
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    estaEnAgenda ? Icons.check : Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
          ),
        );
      },
    );
  }

  // Replace the _buildBotonAgendar method
  Widget _buildBotonAgendar(Actividad actividad) {
    return Consumer<AgendaViewModel>(
      builder: (context, agendaViewModel, child) {
        final estaEnAgenda = agendaViewModel.estaEnAgenda(actividad.id);
        final estaCargando = agendaViewModel.estaCargando(actividad.id);
        
        // Obtener hora actual
        final ahora = DateTime.now();
        
        // La actividad YA INICIÓ si la hora actual es POSTERIOR a la hora de inicio
        // Agregamos un pequeño buffer de 1 minuto para evitar problemas de sincronización
        final yaInicio = ahora.isAfter(actividad.fechaInicio.add(const Duration(minutes: 1)));
        
        print('¿Ya inició?: $yaInicio');
        print('==============================');
        
        if (yaInicio && !estaEnAgenda) {
          return SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Actividad ya iniciada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: estaCargando ? null : () => _manejarBotonAgendar(actividad),
            style: ElevatedButton.styleFrom(
              backgroundColor: estaEnAgenda ? Colors.green : const Color(0xFF8B1B1B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: estaCargando 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Procesando...'),
                    ],
                  )
                : Text(estaEnAgenda ? 'Quitar de Agenda' : 'Agregar a Agenda'),
          ),
        );
      },
    );
  }
  // Replace the _manejarBotonAgendar method
  Future<void> _manejarBotonAgendar(Actividad actividad) async {
    final agendaViewModel = context.read<AgendaViewModel>();
    
    // Si está agregando, calcular recordatorio inteligente
    if (!agendaViewModel.estaEnAgenda(actividad.id)) {
      final ahora = DateTime.now();
      final minutosHastaInicio = actividad.fechaInicio.difference(ahora).inMinutes;
      
      print('=== DEBUG MANEJAR BOTON ===');
      print('DateTime.now(): $ahora');
      print('actividad.fechaInicio: ${actividad.fechaInicio}');
      print('minutosHastaInicio: $minutosHastaInicio');
      
      // CORREGIR: Asegurar que siempre sea mínimo 1 minuto
      final recordatorioMinutos = minutosHastaInicio > 30 
          ? 30 
          : (minutosHastaInicio > 1 ? minutosHastaInicio - 1 : 1);
      
      print('recordatorioMinutos calculado: $recordatorioMinutos');
      print('========================');
      
      agendaViewModel.setRecordatorioTemporal(recordatorioMinutos);
    }

    final exito = await agendaViewModel.alternarActividadEnAgenda(actividad.id);

    if (mounted && exito) {
      final estaEnAgenda = agendaViewModel.estaEnAgenda(actividad.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(estaEnAgenda 
              ? 'Actividad agregada a tu agenda' 
              : 'Actividad removida de tu agenda'),
          backgroundColor: estaEnAgenda ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar la solicitud'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  Widget _buildDiaSinActividades(DateTime dia) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin actividades programadas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay actividades para ${_formatearDiaCompleto(dia)}',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyDaysState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar días',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se pudieron cargar los días del evento',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildErrorState(ActividadesViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar actividades',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.errorMessage,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargarActividades,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1B1B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
  String _formatearDiaTab(DateTime fecha) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${dias[fecha.weekday - 1]} ${fecha.day}/${fecha.month}';
  }
  String _formatearDiaCompleto(DateTime fecha) {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${dias[fecha.weekday - 1]} ${fecha.day} de ${meses[fecha.month - 1]}';
  }
}