import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/pdf_service.dart';
import '../../services/ticket_storage_service.dart';
import '../../services/email_service.dart';
import '../../services/tickets_service.dart';
import 'package:open_file/open_file.dart';
import 'dart:async';

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
  Map<String, dynamic>? _pendingMetadata;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
                  
                  // Logo MercadoPago
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.payment,
                                color: Color(0xFF009EE3),
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'MERCADO PAGO',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF009EE3),
                                  letterSpacing: 1,
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
    setState(() => _procesando = true);
    
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      // Generar ID temporal del ticket
      final ticketId = 'ticket_${DateTime.now().millisecondsSinceEpoch}';
      
      // Guardar metadata para el pago
      _pendingMetadata = {
        'ticketId': ticketId,
        'userId': authViewModel.currentUser!.id,
        'tipoEntrada': widget.tipoEntrada.name,
        'tipoTicket': widget.tipoTicket.name,
        'cantidadPersonas': widget.cantidadPersonas,
        'fechaVisita': widget.fechaVisita.toIso8601String(),
        'nombreComprador': widget.nombreComprador,
        'dniComprador': widget.dniComprador,
        'emailComprador': widget.emailComprador,
        'telefonoComprador': widget.telefonoComprador ?? '',
        'placaVehiculo': widget.placaVehiculo ?? '',
        'tipoVehiculo': widget.tipoVehiculo?.name ?? '',
      };
      
      setState(() => _procesando = false);
      
      // Mostrar formulario de pago de MercadoPago
      await _mostrarFormularioPago();
      
    } catch (e) {
      debugPrint('❌ Error al procesar pago: $e');
      if (mounted) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pago: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _mostrarFormularioPago() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _FormularioPagoMercadoPago(
        monto: _total,
        concepto: 'Entrada ${_getTipoTexto()} - Parque Perú',
      ),
    );

    if (result == true && mounted) {
      // Pago exitoso - completar la compra
      await _completarPagoExitoso({
        'ticketId': _pendingMetadata!['ticketId'],
        'payment_id': 'MP-${DateTime.now().millisecondsSinceEpoch}',
      });
    } else if(mounted) {
      // Pago cancelado
      setState(() => _procesando = false);
    }
  }

  // Este método se llamará cuando el pago sea exitoso
  Future<void> _completarPagoExitoso(Map<String, dynamic> paymentData) async {
    setState(() => _procesando = true);
    
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final ticketsService = TicketsService();
      
      final ticketId = paymentData['ticketId'] as String;
      final transactionId = paymentData['payment_id'] as String? ?? 'txn_${DateTime.now().millisecondsSinceEpoch}';
      
      // Crear el ticket en Firestore
      final ticketTemporal = Ticket(
        id: ticketId,
        userId: authViewModel.currentUser!.id,
        transactionId: transactionId,
        tipo: widget.tipoEntrada,
        cantidadPersonas: widget.cantidadPersonas,
        tipoTicket: widget.tipoTicket,
        monto: _total,
        fechaCompra: DateTime.now(),
        fechaValidez: widget.fechaVisita,
        nombreComprador: widget.nombreComprador,
        dniComprador: widget.dniComprador,
        emailComprador: widget.emailComprador,
        telefonoComprador: widget.telefonoComprador,
        placaVehiculo: widget.placaVehiculo,
        tipoVehiculo: widget.tipoVehiculo,
        estado: EstadoTicket.pagado,
        qrData: widget.tipoEntrada == TipoEntrada.entrada 
            ? 'ENTRADA-$ticketId'
            : widget.tipoEntrada == TipoEntrada.cochera
                ? 'COCHERA-$ticketId'
                : 'COMBO-$ticketId',
        usosRestantes: widget.tipoTicket == TipoTicket.grupal ? widget.cantidadPersonas : 1,
      );
      
      // Guardar el ticket en Firestore
      await ticketsService.crearTicket(ticketTemporal);
      
      // Generar el PDF del comprobante
      final pdfBytes = await PdfService.generarComprobante(
        ticket: ticketTemporal,
        nombreTitular: widget.nombreComprador,
        dniTitular: widget.dniComprador,
        emailTitular: widget.emailComprador,
        telefonoTitular: widget.telefonoComprador,
        placaVehiculo: widget.placaVehiculo,
        tipoVehiculo: widget.tipoVehiculo,
        fechaVisita: widget.fechaVisita,
        totalPagado: _total,
        cantidadAdultos: widget.cantidadPersonas,
        cantidadNinos: 0,
        cantidadAdultosMayor: 0,
        metodoPago: 'MercadoPago',
      );
      
      // Guardar PDF en almacenamiento local
      final pdfPath = await TicketStorageService.guardarTicketPdf(
        ticketId: ticketId,
        pdfBytes: pdfBytes,
      );
      
      // Enviar PDF por email
      final emailService = EmailService();
      try {
        await emailService.enviarTicketPorEmail(
          destinatario: widget.emailComprador,
          nombreDestinatario: widget.nombreComprador,
          ticketId: ticketId,
          pdfPath: pdfPath,
        );
      } catch (e) {
        debugPrint('⚠️ No se pudo enviar el email: $e');
      }
      
      // Mostrar diálogo de éxito
      if (mounted) {
        setState(() => _procesando = false);
        _mostrarDialogoExito(pdfPath);
      }
    } catch (e) {
      debugPrint('❌ Error al completar pago: $e');
      if (mounted) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el ticket: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoExito([String? pdfPath]) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tu compra se ha procesado correctamente.'),
            const SizedBox(height: 8),
            const Text(
              'Recibirás un correo con tu comprobante digital.',
              style: TextStyle(fontSize: 14),
            ),
            if (pdfPath != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await OpenFile.open(pdfPath);
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Ver comprobante PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
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

// Widget del formulario de pago de MercadoPago
class _FormularioPagoMercadoPago extends StatefulWidget {
  final double monto;
  final String concepto;

  const _FormularioPagoMercadoPago({
    required this.monto,
    required this.concepto,
  });

  @override
  State<_FormularioPagoMercadoPago> createState() => _FormularioPagoMercadoPagoState();
}

class _FormularioPagoMercadoPagoState extends State<_FormularioPagoMercadoPago> {
  final _formKey = GlobalKey<FormState>();
  final _numeroTarjetaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _vencimientoController = TextEditingController();
  final _cvvController = TextEditingController();
  final _dniController = TextEditingController();
  
  bool _procesando = false;
  String _tipoTarjeta = '';

  @override
  void dispose() {
    _numeroTarjetaController.dispose();
    _nombreController.dispose();
    _vencimientoController.dispose();
    _cvvController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  void _detectarTipoTarjeta(String numero) {
    final numeroLimpio = numero.replaceAll(' ', '');
    if (numeroLimpio.startsWith('4')) {
      setState(() => _tipoTarjeta = 'visa');
    } else if (numeroLimpio.startsWith('5')) {
      setState(() => _tipoTarjeta = 'mastercard');
    } else if (numeroLimpio.startsWith('3')) {
      setState(() => _tipoTarjeta = 'amex');
    } else {
      setState(() => _tipoTarjeta = '');
    }
  }

  String _formatearNumeroTarjeta(String value) {
    final numero = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < numero.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(numero[i]);
    }
    return buffer.toString();
  }

  String _formatearVencimiento(String value) {
    final numero = value.replaceAll('/', '');
    if (numero.length >= 2) {
      return '${numero.substring(0, 2)}/${numero.substring(2)}';
    }
    return numero;
  }

  Future<void> _procesarPago() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _procesando = true);

    // Simular procesamiento de pago
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _procesando = false);
      Navigator.of(context).pop(true); // Retornar true = pago exitoso
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con logo de MercadoPago
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF009EE3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'MP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'MercadoPago',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Monto a pagar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.concepto,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'S/. ${widget.monto.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF009EE3),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Número de tarjeta
                TextFormField(
                  controller: _numeroTarjetaController,
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                  decoration: InputDecoration(
                    labelText: 'Número de tarjeta',
                    hintText: '1234 5678 9012 3456',
                    prefixIcon: const Icon(Icons.credit_card),
                    suffixIcon: _tipoTarjeta.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: _buildLogoTarjeta(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    counterText: '',
                  ),
                  onChanged: (value) {
                    final formatted = _formatearNumeroTarjeta(value);
                    if (formatted != value) {
                      _numeroTarjetaController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                    _detectarTipoTarjeta(value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese el número de tarjeta';
                    final limpio = value.replaceAll(' ', '');
                    if (limpio.length < 13) return 'Número de tarjeta inválido';
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Nombre del titular
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Nombre del titular',
                    hintText: 'JUAN PEREZ',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese el nombre del titular';
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Vencimiento y CVV
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _vencimientoController,
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        decoration: InputDecoration(
                          labelText: 'Vencimiento',
                          hintText: 'MM/AA',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          counterText: '',
                        ),
                        onChanged: (value) {
                          final formatted = _formatearVencimiento(value);
                          if (formatted != value) {
                            _vencimientoController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          if (!value.contains('/') || value.length != 5) return 'Formato MM/AA';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          if (value.length < 3) return 'Inválido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // DNI
                TextFormField(
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: InputDecoration(
                    labelText: 'DNI del titular',
                    hintText: '12345678',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese el DNI';
                    if (value.length != 8) return 'DNI inválido';
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Botón de pagar
                ElevatedButton(
                  onPressed: _procesando ? null : _procesarPago,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009EE3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _procesando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Pagar S/. ${widget.monto.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Mensaje de seguridad
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Pago seguro con MercadoPago',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoTarjeta() {
    switch (_tipoTarjeta) {
      case 'visa':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1434CB),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'VISA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      case 'mastercard':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEB001B),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'MC',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      case 'amex':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF006FCF),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'AMEX',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
