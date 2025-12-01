import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket.dart';
import '../../viewmodels/tickets_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/culqi_service.dart';

class ResumenCompraPage extends StatefulWidget {
  final TipoEntrada tipoEntrada;
  final TipoTicket tipoTicket;
  final int cantidadPersonas;
  final String nombreComprador;
  final String dniComprador;
  final String emailComprador;
  final String? telefonoComprador;
  final String? placaVehiculo;
  final TipoVehiculo? tipoVehiculo;
  final DateTime fechaVisita;

  const ResumenCompraPage({
    super.key,
    required this.tipoEntrada,
    required this.tipoTicket,
    required this.cantidadPersonas,
    required this.nombreComprador,
    required this.dniComprador,
    required this.emailComprador,
    this.telefonoComprador,
    this.placaVehiculo,
    this.tipoVehiculo,
    required this.fechaVisita,
  });

  @override
  State<ResumenCompraPage> createState() => _ResumenCompraPageState();
}

class _ResumenCompraPageState extends State<ResumenCompraPage> {
  bool _procesando = false;

  double get _precioUnitario {
    return widget.tipoEntrada == TipoEntrada.combo ? 20.0 : 10.0;
  }

  double get _total {
    return _precioUnitario * widget.cantidadPersonas;
  }

  Color get _colorTema {
    switch (widget.tipoEntrada) {
      case TipoEntrada.entrada:
        return const Color(0xFF4CAF50);
      case TipoEntrada.cochera:
        return const Color(0xFFFF9800);
      case TipoEntrada.combo:
        return const Color(0xFF9C27B0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de compra'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: _procesando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Procesando pago...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información del ticket
                  _buildInfoTicket(),
                  
                  const SizedBox(height: 16),
                  
                  // Datos del comprador
                  _buildDatosComprador(),
                  
                  const SizedBox(height: 16),
                  
                  // Datos del vehículo (si aplica)
                  if (widget.placaVehiculo != null)
                    _buildDatosVehiculo(),
                  
                  if (widget.placaVehiculo != null)
                    const SizedBox(height: 16),
                  
                  // Resumen de pago
                  _buildResumenPago(),
                  
                  const SizedBox(height: 24),
                  
                  // Términos y condiciones
                  _buildTerminos(),
                  
                  const SizedBox(height: 24),
                  
                  // Botón de pago
                  ElevatedButton(
                    onPressed: _procesarPago,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorTema,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Pagar S/. ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Logo Culqi
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Pago seguro con',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'CULQI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A19B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTicket() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _colorTema.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIcono(),
                    color: _colorTema,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitulo(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _colorTema,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSubtitulo(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha de visita',
              _formatearFecha(widget.fechaVisita),
            ),
            
            const SizedBox(height: 8),
            
            _buildInfoRow(
              Icons.people,
              'Cantidad',
              '${widget.cantidadPersonas} ${widget.cantidadPersonas == 1 ? 'persona' : 'personas'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosComprador() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del comprador',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 16),
            
            _buildInfoRow(Icons.person, 'Nombre', widget.nombreComprador),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.badge, 'DNI', widget.dniComprador),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, 'Email', widget.emailComprador),
            if (widget.telefonoComprador != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, 'Teléfono', widget.telefonoComprador!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDatosVehiculo() {
    return Card(
      elevation: 2,
      color: const Color(0xFFFF9800).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_parking, color: Color(0xFFFF9800)),
                SizedBox(width: 8),
                Text(
                  'Datos del vehículo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            
            _buildInfoRow(Icons.directions_car, 'Placa', widget.placaVehiculo!),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.commute,
              'Tipo',
              _getNombreTipoVehiculo(widget.tipoVehiculo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenPago() {
    return Card(
      elevation: 2,
      color: const Color(0xFF1976D2).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RESUMEN DE PAGO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const Divider(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.cantidadPersonas}x ${_getTipoTexto()}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'S/. ${(_precioUnitario * widget.cantidadPersonas).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const Divider(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL A PAGAR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'S/. ${_total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _colorTema,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminos() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Al realizar el pago, aceptas:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildTerminoItem('El ticket es válido solo para la fecha seleccionada'),
            _buildTerminoItem('Cancelaciones hasta 24 horas antes'),
            _buildTerminoItem('Recibir el comprobante por email'),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminoItem(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icono, String label, String valor) {
    return Row(
      children: [
        Icon(icono, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  IconData _getIcono() {
    switch (widget.tipoEntrada) {
      case TipoEntrada.entrada:
        return Icons.confirmation_number;
      case TipoEntrada.cochera:
        return Icons.local_parking;
      case TipoEntrada.combo:
        return Icons.card_giftcard;
    }
  }

  String _getTitulo() {
    if (widget.tipoTicket == TipoTicket.grupal) {
      switch (widget.tipoEntrada) {
        case TipoEntrada.entrada:
          return 'Entrada Grupal';
        case TipoEntrada.cochera:
          return 'Cochera';
        case TipoEntrada.combo:
          return 'Combo Familiar';
      }
    } else {
      switch (widget.tipoEntrada) {
        case TipoEntrada.entrada:
          return 'Entradas Individuales';
        case TipoEntrada.cochera:
          return 'Cochera';
        case TipoEntrada.combo:
          return 'Combos Individuales';
      }
    }
  }

  String _getSubtitulo() {
    if (widget.tipoTicket == TipoTicket.grupal) {
      return 'Todos ingresan con 1 QR';
    } else {
      return '${widget.cantidadPersonas} QRs individuales';
    }
  }

  String _getTipoTexto() {
    switch (widget.tipoEntrada) {
      case TipoEntrada.entrada:
        return 'Entrada';
      case TipoEntrada.cochera:
        return 'Cochera';
      case TipoEntrada.combo:
        return 'Combo';
    }
  }

  String _formatearFecha(DateTime fecha) {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 
                   'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    
    final dia = dias[fecha.weekday - 1];
    final mes = meses[fecha.month - 1];
    
    return '$dia, ${fecha.day} de $mes de ${fecha.year}';
  }

  String _getNombreTipoVehiculo(TipoVehiculo? tipo) {
    switch (tipo) {
      case TipoVehiculo.automovil:
        return 'Automóvil';
      case TipoVehiculo.camioneta:
        return 'Camioneta';
      case TipoVehiculo.motocicleta:
        return 'Motocicleta';
      case TipoVehiculo.otro:
        return 'Otro';
      default:
        return 'No especificado';
    }
  }

  Future<void> _procesarPago() async {
    // Mostrar diálogo de pago con Culqi
    final resultado = await _mostrarDialogoPago();
    
    if (resultado == true && mounted) {
      // Pago exitoso
      _mostrarDialogoExito();
    }
  }

  Future<bool?> _mostrarDialogoPago() async {
    // Por ahora simulamos el pago
    // En producción aquí iría la integración real con Culqi
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pago con Culqi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card, size: 64, color: Color(0xFF00A19B)),
            SizedBox(height: 16),
            Text('Por ahora el pago está en modo simulación.'),
            SizedBox(height: 8),
            Text(
              'En producción se abrirá el formulario de pago de Culqi.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A19B),
            ),
            child: const Text('Simular pago exitoso'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
            SizedBox(width: 12),
            Text('¡Pago exitoso!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tu compra se ha procesado correctamente.'),
            SizedBox(height: 8),
            Text(
              'Recibirás un correo con tu comprobante digital.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Volver al inicio
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Ir al inicio'),
          ),
        ],
      ),
    );
  }
}
