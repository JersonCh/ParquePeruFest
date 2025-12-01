import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/tickets_viewmodel.dart';
import '../../models/ticket.dart';

class DashboardVentasPage extends StatefulWidget {
  const DashboardVentasPage({super.key});

  @override
  State<DashboardVentasPage> createState() => _DashboardVentasPageState();
}

class _DashboardVentasPageState extends State<DashboardVentasPage> {
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketsViewModel>().cargarEstadisticasDia(_fechaSeleccionada);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas de Entradas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TicketsViewModel>().cargarEstadisticasDia(_fechaSeleccionada);
            },
          ),
        ],
      ),
      body: Consumer<TicketsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await viewModel.cargarEstadisticasDia(_fechaSeleccionada);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de fecha
                  _buildSelectorFecha(),
                  
                  const SizedBox(height: 24),
                  
                  // Resumen principal
                  _buildResumenPrincipal(viewModel),
                  
                  const SizedBox(height: 24),
                  
                  // Desglose por tipo
                  _buildDesgloseTipos(viewModel),
                  
                  const SizedBox(height: 24),
                  
                  // Estadísticas adicionales
                  _buildEstadisticasAdicionales(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectorFecha() {
    final formatoFecha = DateFormat('EEEE, d \'de\' MMMM', 'es_ES');
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fecha seleccionada',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatoFecha.format(_fechaSeleccionada),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _seleccionarFecha(context),
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenPrincipal(TicketsViewModel viewModel) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Color(0xFF1976D2),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _fechaSeleccionada.day == DateTime.now().day &&
                      _fechaSeleccionada.month == DateTime.now().month &&
                      _fechaSeleccionada.year == DateTime.now().year
                      ? 'HOY'
                      : DateFormat('dd/MM/yyyy').format(_fechaSeleccionada),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            // Grid de estadísticas principales
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildEstadisticaCard(
                  'Tickets vendidos',
                  '${viewModel.ticketsVendidosHoy}',
                  Icons.confirmation_number,
                  const Color(0xFF4CAF50),
                ),
                _buildEstadisticaCard(
                  'Personas esperadas',
                  '${viewModel.personasEsperadasHoy}',
                  Icons.people,
                  const Color(0xFF2196F3),
                ),
                _buildEstadisticaCard(
                  'Cocheras reservadas',
                  '${viewModel.cocherasReservadasHoy}',
                  Icons.local_parking,
                  const Color(0xFFFF9800),
                ),
                _buildEstadisticaCard(
                  'Ingresos',
                  'S/. ${viewModel.ingresosHoy.toStringAsFixed(2)}',
                  Icons.attach_money,
                  const Color(0xFF9C27B0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticaCard(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesgloseTipos(TicketsViewModel viewModel) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DESGLOSE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetalleTicket(
              'Individuales',
              viewModel.ticketsIndividualesHoy,
              viewModel.personasIndividualesHoy,
              Icons.person,
              const Color(0xFF4CAF50),
            ),
            
            const Divider(height: 24),
            
            _buildDetalleTicket(
              'Grupales',
              viewModel.ticketsGrupalesHoy,
              viewModel.personasGrupalesHoy,
              Icons.group,
              const Color(0xFF2196F3),
            ),
            
            const Divider(height: 24),
            
            _buildDetalleTicket(
              'Múltiples',
              viewModel.ticketsMultiplesHoy,
              viewModel.personasMultiplesHoy,
              Icons.groups,
              const Color(0xFF9C27B0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleTicket(
    String tipo,
    int tickets,
    int personas,
    IconData icono,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tipo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$tickets ${tickets == 1 ? 'ticket' : 'tickets'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$personas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              personas == 1 ? 'persona' : 'personas',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstadisticasAdicionales(TicketsViewModel viewModel) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROMEDIOS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPromedioRow(
              'Personas por ticket grupal',
              viewModel.promedioPersonasPorTicketGrupal.toStringAsFixed(2),
              Icons.group,
            ),
            
            const Divider(height: 24),
            
            _buildPromedioRow(
              'Ticket más grande',
              '${viewModel.ticketMasGrande} personas',
              Icons.trending_up,
            ),
            
            const Divider(height: 24),
            
            _buildPromedioRow(
              'Monto promedio',
              'S/. ${viewModel.montoPromedio.toStringAsFixed(2)}',
              Icons.payment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromedioRow(String titulo, String valor, IconData icono) {
    return Row(
      children: [
        Icon(icono, color: const Color(0xFF1976D2), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
      if (mounted) {
        context.read<TicketsViewModel>().cargarEstadisticasDia(_fechaSeleccionada);
      }
    }
  }
}
