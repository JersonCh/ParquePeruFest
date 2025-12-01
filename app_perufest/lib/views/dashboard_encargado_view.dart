import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/tickets_viewmodel.dart';
import '../models/ticket.dart';
import 'admin/validar_tickets_page.dart';

class DashboardEncargadoView extends StatefulWidget {
  const DashboardEncargadoView({super.key});

  @override
  State<DashboardEncargadoView> createState() => _DashboardEncargadoViewState();
}

class _DashboardEncargadoViewState extends State<DashboardEncargadoView> {
  int _ticketsPendientes = 0;
  int _ticketsValidados = 0;
  List<Ticket> _historialTickets = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    // Cargar después de que el widget se haya construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEstadisticas();
    });
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _cargando = true);
    
    try {
      final ticketsViewModel = Provider.of<TicketsViewModel>(context, listen: false);
      
      // Cargar todos los tickets
      await ticketsViewModel.cargarTodosLosTickets();
      
      // Calcular estadísticas
      final todosTickets = ticketsViewModel.allTickets;
      
      _ticketsPendientes = todosTickets.where(
        (t) => t.estado == EstadoTicket.pagado && !t.estaExpirado
      ).length;
      
      _ticketsValidados = todosTickets.where(
        (t) => t.estado == EstadoTicket.usado
      ).length;
      
      // Historial ordenado por fecha más reciente
      _historialTickets = List.from(todosTickets)
        ..sort((a, b) => b.fechaCompra.compareTo(a.fechaCompra));
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estadísticas: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _irAValidarTickets() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ValidarTicketsPage()),
    ).then((_) => _cargarEstadisticas()); // Recargar al volver
  }

  void _cerrarSesion() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    authViewModel.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final usuario = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Validación'),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEstadisticas,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarEstadisticas,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bienvenida
                      Card(
                        elevation: 2,
                        color: const Color(0xFF1976D2),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.verified_user,
                                  size: 35,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Bienvenido',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      usuario?.nombre ?? 'Encargado',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      usuario?.correo ?? '',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Estadísticas en cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Pendientes',
                              _ticketsPendientes.toString(),
                              Icons.pending_actions,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Validados',
                              _ticketsValidados.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Botón grande para validar
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _irAValidarTickets,
                          icon: const Icon(Icons.qr_code_scanner, size: 28),
                          label: const Text(
                            'Validar Tickets',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Historial
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Historial de Tickets',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_historialTickets.length} tickets',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Lista de tickets
                      if (_historialTickets.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay tickets registrados',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _historialTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = _historialTickets[index];
                            return _buildTicketCard(ticket);
                          },
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icono, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icono, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    
    Color estadoColor;
    IconData estadoIcon;
    String estadoTexto;
    
    switch (ticket.estado) {
      case EstadoTicket.usado:
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        estadoTexto = 'Validado';
        break;
      case EstadoTicket.pagado:
        if (ticket.estaExpirado) {
          estadoColor = Colors.red;
          estadoIcon = Icons.cancel;
          estadoTexto = 'Expirado';
        } else {
          estadoColor = Colors.orange;
          estadoIcon = Icons.pending;
          estadoTexto = 'Pendiente';
        }
        break;
      case EstadoTicket.cancelado:
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel;
        estadoTexto = 'Cancelado';
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help;
        estadoTexto = 'Pendiente pago';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _mostrarDetallesTicket(ticket),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          ticket.icono,
                          color: const Color(0xFF1976D2),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.titulo,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ID: ${ticket.idFormateado}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      estadoTexto,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    avatar: Icon(estadoIcon, size: 16, color: Colors.white),
                    backgroundColor: estadoColor,
                    padding: const EdgeInsets.all(0),
                  ),
                ],
              ),
              
              const Divider(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.calendar_today, 'Válido: ${formatter.format(ticket.fechaValidez)}'),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.shopping_cart, 'Compra: ${formatter.format(ticket.fechaCompra)}'),
                      if (ticket.estado == EstadoTicket.usado && ticket.fechaValidacion != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _buildInfoRow(
                            Icons.verified,
                            'Validado: ${formatter.format(ticket.fechaValidacion!)}',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }



  void _mostrarDetallesTicket(Ticket ticket) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Row(
                      children: [
                        Icon(
                          ticket.icono,
                          size: 32,
                          color: const Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detalles del Ticket',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                ticket.titulo,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    // Información
                    _buildDetalle('ID', ticket.idFormateado),
                    _buildDetalle('Orden', ticket.ordenId ?? 'N/A'),
                    _buildDetalle('Estado', ticket.estado.toString().split('.').last.toUpperCase()),
                    _buildDetalle('Monto', 'S/ ${ticket.monto.toStringAsFixed(2)}'),
                    _buildDetalle('Personas', ticket.cantidadPersonas.toString()),
                    _buildDetalle('Fecha de Compra', formatter.format(ticket.fechaCompra)),
                    _buildDetalle('Fecha de Validez', formatter.format(ticket.fechaValidez)),
                    _buildDetalle('Comprador', ticket.nombreComprador),
                    _buildDetalle('DNI', ticket.dniComprador),
                    if (ticket.placaVehiculo != null)
                      _buildDetalle('Placa Vehículo', ticket.placaVehiculo!),
                    
                    if (ticket.estado == EstadoTicket.usado) ...[
                      const Divider(height: 32),
                      const Text(
                        'Información de Validación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (ticket.fechaValidacion != null)
                        _buildDetalle('Validado el', formatter.format(ticket.fechaValidacion!)),
                      if (ticket.validadoPor != null)
                        _buildDetalle('Validado por', ticket.validadoPor!),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Botón cerrar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ),
                    
                    // Espacio adicional para evitar que el teclado tape
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalle(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
