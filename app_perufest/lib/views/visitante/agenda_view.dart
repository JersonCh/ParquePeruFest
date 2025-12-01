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
  Color tiempoColor = const Color(0xFF8B1B1B);
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF8B1B1B).withOpacity(0.13),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1B1B).withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con tiempo restante
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: tiempoColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(tiempoIcon, color: tiempoColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  tiempoTexto,
                  style: TextStyle(
                    color: tiempoColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => _confirmarRemover(actividadId, nombre),
                  tooltip: 'Quitar de agenda',
                ),
              ],
            ),
          ),
          
          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de la actividad
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Información de zona
                Row(
                  children: [
                    Icon(Icons.location_on, 
                         color: const Color(0xFF8B1B1B).withOpacity(0.7), 
                         size: 18),
                    const SizedBox(width: 8),
                    Text(
                      zona,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Fecha y hora
                if (fechaInicio != null) ...[
                  Row(
                    children: [
                      Icon(Icons.access_time, 
                           color: const Color(0xFF8B1B1B).withOpacity(0.7), 
                           size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _formatearFechaHora(fechaInicio),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (fechaFin != null) ...[
                        Text(
                          ' - ${_formatearHora(fechaFin)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Recordatorio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications, 
                           color: Colors.blue.shade600, 
                           size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Recordatorio: ${actividad['recordatorioMinutos']} min antes',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
                backgroundColor: const Color(0xFF8B1B1B),
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
                backgroundColor: const Color(0xFF8B1B1B),
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
                  color: const Color(0xFF8B1B1B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Color(0xFF8B1B1B),
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
                        backgroundColor: const Color(0xFF8B1B1B),
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
}