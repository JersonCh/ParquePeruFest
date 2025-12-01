import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../viewmodels/tickets_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/ticket.dart';
import '../../services/ticket_storage_service.dart';
import 'package:open_file/open_file.dart';
import 'ver_ticket_page.dart';

class MisTicketsPage extends StatefulWidget {
  const MisTicketsPage({super.key});

  @override
  State<MisTicketsPage> createState() => _MisTicketsPageState();
}

class _MisTicketsPageState extends State<MisTicketsPage> {
  String _filtroSeleccionado = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      if (authViewModel.currentUser != null) {
        debugPrint('🎫 Cargando tickets para usuario: ${authViewModel.currentUser!.id}');
        context.read<TicketsViewModel>().cargarMisTickets(authViewModel.currentUser!.id);
      } else {
        debugPrint('❌ No hay usuario logueado');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tickets'),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),
      body: Consumer<TicketsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(viewModel.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authViewModel = context.read<AuthViewModel>();
                      if (authViewModel.currentUser != null) {
                        viewModel.cargarMisTickets(authViewModel.currentUser!.id);
                      }
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final ticketsFiltrados = _filtrarTickets(viewModel.tickets);

          if (ticketsFiltrados.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes tickets',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getMensajeFiltro(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authViewModel = context.read<AuthViewModel>();
              if (authViewModel.currentUser != null) {
                await viewModel.cargarMisTickets(authViewModel.currentUser!.id);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ticketsFiltrados.length,
              itemBuilder: (context, index) {
                return _buildTicketCard(ticketsFiltrados[index]);
              },
            ),
          );
        },
      ),
    );
  }

  List<Ticket> _filtrarTickets(List<Ticket> tickets) {
    switch (_filtroSeleccionado) {
      case 'activos':
        return tickets.where((t) => t.estado == EstadoTicket.pagado && !t.estaExpirado).toList();
      case 'usados':
        return tickets.where((t) => t.estado == EstadoTicket.usado).toList();
      case 'expirados':
        return tickets.where((t) => t.estaExpirado || t.estado == EstadoTicket.expirado).toList();
      default:
        return tickets;
    }
  }

  String _getMensajeFiltro() {
    switch (_filtroSeleccionado) {
      case 'activos':
        return 'No tienes tickets activos';
      case 'usados':
        return 'No tienes tickets usados';
      case 'expirados':
        return 'No tienes tickets expirados';
      default:
        return 'Compra tickets para tus próximas visitas';
    }
  }

  Widget _buildTicketCard(Ticket ticket) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ticket.colorTema.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _verDetalleTicket(ticket),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con icono y estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ticket.colorTema.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(ticket.icono, color: ticket.colorTema, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.titulo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ticket.colorTema,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket.idFormateado,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildChipEstado(ticket),
                ],
              ),
              
              const Divider(height: 24),
              
              // Información del ticket
              _buildInfoRow(
                Icons.calendar_today,
                'Fecha de visita',
                formatoFecha.format(ticket.fechaValidez),
              ),
              
              const SizedBox(height: 8),
              
              _buildInfoRow(
                Icons.people,
                'Personas',
                '${ticket.cantidadPersonas}',
              ),
              
              const SizedBox(height: 8),
              
              _buildInfoRow(
                Icons.attach_money,
                'Monto',
                'S/. ${ticket.monto.toStringAsFixed(2)}',
              ),
              
              if (ticket.placaVehiculo != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.directions_car,
                  'Placa',
                  ticket.placaVehiculo!,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Botones de acción
              Row(
                children: [
                  // Botón Ver PDF
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _verPDF(ticket),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ticket.colorTema,
                        side: BorderSide(color: ticket.colorTema),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: const Text('Ver PDF'),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Botón Mostrar QR
                  if (ticket.estaActivo)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarQR(ticket),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ticket.colorTema,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.qr_code, color: Colors.white, size: 20),
                        label: const Text(
                          'QR',
                          style: TextStyle(color: Colors.white),
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

  Widget _buildChipEstado(Ticket ticket) {
    Color color;
    String texto;
    IconData icono;

    if (ticket.estado == EstadoTicket.usado) {
      color = Colors.grey;
      texto = 'Usado';
      icono = Icons.check_circle;
    } else if (ticket.estaExpirado) {
      color = Colors.red;
      texto = 'Expirado';
      icono = Icons.cancel;
    } else if (ticket.estado == EstadoTicket.pagado) {
      color = const Color(0xFF4CAF50);
      texto = 'Activo';
      icono = Icons.check_circle;
    } else {
      color = Colors.orange;
      texto = 'Pendiente';
      icono = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icono, String label, String valor) {
    return Row(
      children: [
        Icon(icono, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filtrar tickets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildOpcionFiltro('Todos', 'todos', Icons.all_inclusive),
            _buildOpcionFiltro('Activos', 'activos', Icons.check_circle),
            _buildOpcionFiltro('Usados', 'usados', Icons.history),
            _buildOpcionFiltro('Expirados', 'expirados', Icons.cancel),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionFiltro(String titulo, String valor, IconData icono) {
    final seleccionado = _filtroSeleccionado == valor;
    
    return ListTile(
      leading: Icon(
        icono,
        color: seleccionado ? const Color(0xFF1976D2) : Colors.grey,
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          color: seleccionado ? const Color(0xFF1976D2) : Colors.black,
        ),
      ),
      trailing: seleccionado
          ? const Icon(Icons.check, color: Color(0xFF1976D2))
          : null,
      onTap: () {
        setState(() {
          _filtroSeleccionado = valor;
        });
        Navigator.pop(context);
      },
    );
  }

  void _mostrarQR(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ticket.titulo,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ticket.colorTema,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                ticket.idFormateado,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // QR Code real
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: ticket.qrData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (ticket.tipoTicket == TipoTicket.grupal)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ticket.colorTema.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: ticket.colorTema),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Válido para ${ticket.cantidadPersonas} personas',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verDetalleTicket(Ticket ticket) {
    // Aquí se podría navegar a una vista de detalle completa
    // o mostrar el PDF del comprobante
    _mostrarQR(ticket);
  }

  Future<void> _verPDF(Ticket ticket) async {
    try {
      // Verificar si existe el PDF guardado
      final pdfPath = await TicketStorageService.getTicketPdfPath(ticket.id);
      
      if (pdfPath != null) {
        // Abrir el PDF con el visor predeterminado
        final result = await OpenFile.open(pdfPath);
        
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('PDF no encontrado. ¿Deseas regenerarlo?'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Regenerar',
                textColor: Colors.white,
                onPressed: () => _regenerarPDF(ticket),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _regenerarPDF(Ticket ticket) async {
    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Regenerando comprobante...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Aquí se podría implementar la regeneración del PDF
      // Por ahora solo mostramos un mensaje
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Función de regeneración no implementada aún'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
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
