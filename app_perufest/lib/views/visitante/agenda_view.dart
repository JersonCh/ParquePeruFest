import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/agenda_list_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/timezone_service.dart';

class AgendaView extends StatefulWidget {
  const AgendaView({super.key});

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarAgenda();
    });
  }

  void _cargarAgenda() {
    final authViewModel = context.read<AuthViewModel>();
    final agendaViewModel = context.read<AgendaListViewModel>();
    final userId = authViewModel.currentUser?.id ?? '';
    
    if (userId.isNotEmpty) {
      agendaViewModel.cargarActividadesAgenda(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FF),
      body: Column(
        children: [
          _buildMainHeader(),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: CustomScrollView(
                slivers: [
                  Consumer<AgendaListViewModel>(
                    builder: (context, agendaViewModel, child) {
                      if (agendaViewModel.isLoading) {
                        return const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (agendaViewModel.error.isNotEmpty) {
                        return SliverFillRemaining(
                          child: _buildErrorState(agendaViewModel.error),
                        );
                      }

                      if (agendaViewModel.actividadesAgenda.isEmpty) {
                        return SliverFillRemaining(
                          child: _buildEmptyState(),
                        );
                      }

                      return _buildActividadesList(agendaViewModel.actividadesAgenda);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 122, 0, 37),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Decoración superior
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 1,
                width: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.event_note,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Container(
                height: 1,
                width: 60,
                color: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Título principal
          const Text(
            'MI AGENDA',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          
          // Subtítulo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '"Tus actividades organizadas"',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActividadesList(List<Map<String, dynamic>> actividades) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final actividad = actividades[index];
            return _buildActividadCard(actividad);
          },
          childCount: actividades.length,
        ),
      ),
    );
  }

Widget _buildActividadCard(Map<String, dynamic> actividad) {
  // Las fechas ya vienen convertidas a Perú desde el viewmodel
  final fechaInicio = actividad['fechaInicio'] as DateTime?;
  final fechaFin = actividad['fechaFin'] as DateTime?;
  final nombre = actividad['nombre'] ?? 'Sin nombre';
  final zona = actividad['zona'] ?? 'Sin zona';
  final actividadId = actividad['id'] ?? '';

  // Calcular tiempo restante usando hora de Perú
  String tiempoTexto = '';
  Color tiempoColor = const Color.fromARGB(255, 122, 0, 37);
  IconData tiempoIcon = Icons.schedule;

  if (fechaInicio != null) {
    final ahoraEnPeru = TimezoneService.nowInPeru(); // Usar hora de Perú
    final diferencia = fechaInicio.difference(ahoraEnPeru);

    if (diferencia.isNegative) {
      if (fechaFin != null && fechaFin.isAfter(ahoraEnPeru)) {
        tiempoTexto = 'En progreso';
        tiempoColor = Colors.green;
        tiempoIcon = Icons.play_circle;
      } else {
        tiempoTexto = 'Finalizado';
        tiempoColor = Colors.grey;
        tiempoIcon = Icons.check_circle;
      }
    } else if (diferencia.inDays > 0) {
      tiempoTexto = 'En ${diferencia.inDays} días';
      tiempoIcon = Icons.calendar_today;
    } else if (diferencia.inHours > 0) {
      tiempoTexto = 'En ${diferencia.inHours} horas';
      tiempoColor = Colors.orange;
      tiempoIcon = Icons.access_time;
    } else if (diferencia.inMinutes > 0) {
      tiempoTexto = 'En ${diferencia.inMinutes} minutos';
      tiempoColor = Colors.red;
      tiempoIcon = Icons.alarm;
    } else {
      tiempoTexto = '¡Ahora!';
      tiempoColor = Colors.red;
      tiempoIcon = Icons.notification_important;
    }
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      children: [
        // Header compacto con estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tiempoColor == Colors.grey 
                  ? [Colors.grey.shade50, Colors.grey.shade100]
                  : [tiempoColor.withOpacity(0.05), tiempoColor.withOpacity(0.12)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            border: Border(
              bottom: BorderSide(
                color: tiempoColor.withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tiempoColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: tiempoColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tiempoIcon, 
                      color: Colors.white, 
                      size: 14
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tiempoTexto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => _confirmarRemover(actividadId, nombre),
                  borderRadius: BorderRadius.circular(12),
                  child: const Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Contenido principal compacto
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la actividad
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Información principal en una sola fila
              Row(
                children: [
                  // Zona
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: const Color.fromARGB(255, 122, 0, 37),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            zona,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Hora
                  if (fechaInicio != null) 
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatearHora(fechaInicio),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (fechaFin != null) ...[
                          Text(
                            ' - ${_formatearHora(fechaFin)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Fecha en línea separada
              if (fechaInicio != null) 
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.grey.shade500,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatearFecha(fechaInicio),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 12),
              
              // Recordatorio compacto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 122, 0, 37),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Recordatorio: ${actividad['recordatorioMinutos']} min antes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Tu agenda está vacía',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Agrega actividades desde la sección de eventos para verlas aquí',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _cargarAgenda,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 122, 0, 37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar agenda',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarAgenda,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 122, 0, 37),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarRemover(String actividadId, String nombreActividad) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Color.fromARGB(255, 122, 0, 37),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              
              // Título
              const Text(
                'Quitar de agenda',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 12),
              
              // Contenido
              Text(
                '¿Deseas quitar "$nombreActividad" de tu agenda?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _removerActividad(actividadId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 122, 0, 37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Quitar',
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

  void _removerActividad(String actividadId) async {
    final authViewModel = context.read<AuthViewModel>();
    final agendaViewModel = context.read<AgendaListViewModel>();
    final userId = authViewModel.currentUser?.id ?? '';

    if (userId.isNotEmpty) {
      final exito = await agendaViewModel.removerActividad(userId, actividadId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exito 
              ? 'Actividad removida de tu agenda' 
              : 'Error al remover la actividad'),
            backgroundColor: exito ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  // Los métodos de formateo no cambian porque las fechas ya vienen convertidas
  String _formatearFechaHora(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${_formatearHora(fecha)}';
  }

  String _formatearHora(DateTime fecha) {
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatearFecha(DateTime fecha) {
    final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    final diaSemana = dias[fecha.weekday % 7];
    final dia = fecha.day;
    final mes = meses[fecha.month - 1];
    
    return '$diaSemana $dia $mes';
  }
}