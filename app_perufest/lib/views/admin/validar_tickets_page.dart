import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/tickets_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/ticket.dart';
import '../../services/qr_service.dart';

class ValidarTicketsPage extends StatefulWidget {
  const ValidarTicketsPage({super.key});

  @override
  State<ValidarTicketsPage> createState() => _ValidarTicketsPageState();
}

class _ValidarTicketsPageState extends State<ValidarTicketsPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  final QRService _qrService = QRService();
  
  bool _scannerActivo = false;
  bool _procesandoQR = false;
  Ticket? _ultimoTicketValidado;
  String? _mensajeError;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validar Tickets'),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            icon: Icon(_scannerActivo ? Icons.flash_off : Icons.flash_on),
            onPressed: () {
              _scannerController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () {
              _scannerController.switchCamera();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Área de scanner
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Scanner
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetectQR,
                ),
                
                // Overlay de guías
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                // Indicador de procesamiento
                if (_procesandoQR)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Validando...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Área de información
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(16),
              child: _buildInfoArea(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoArea() {
    if (_mensajeError != null) {
      return _buildMensajeError();
    }
    
    if (_ultimoTicketValidado != null) {
      return _buildTicketValidado();
    }
    
    return _buildInstrucciones();
  }

  Widget _buildInstrucciones() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Apunta la cámara al código QR',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'El ticket se validará automáticamente',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMensajeError() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cancel,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ticket NO Válido',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _mensajeError!,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _reiniciarScanner,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Escanear otro',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketValidado() {
    final ticket = _ultimoTicketValidado!;
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final formatoHora = DateFormat('HH:mm:ss');
    
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50), width: 2),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ticket Válido',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Información del ticket
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Tipo:', ticket.titulo, ticket.colorTema),
                  const Divider(),
                  _buildInfoRow('ID:', ticket.idFormateado, Colors.grey.shade700),
                  const Divider(),
                  _buildInfoRow('Personas:', '${ticket.cantidadPersonas}', Colors.grey.shade700),
                  
                  if (ticket.placaVehiculo != null) ...[
                    const Divider(),
                    _buildInfoRow('Placa:', ticket.placaVehiculo!, Colors.grey.shade700),
                  ],
                  
                  const Divider(),
                  _buildInfoRow('Fecha Validez:', formatoFecha.format(ticket.fechaValidez), Colors.grey.shade700),
                  const Divider(),
                  _buildInfoRow('Validado:', formatoHora.format(DateTime.now()), Colors.grey.shade700),
                ],
              ),
            ),
            
            // Información adicional
            if (ticket.tipoTicket == TipoTicket.grupal)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ticket.colorTema.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: ticket.colorTema),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ticket grupal: válido para ${ticket.cantidadPersonas} personas',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _reiniciarScanner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Validar siguiente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String valor, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _onDetectQR(BarcodeCapture capture) async {
    if (_procesandoQR) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() {
      _procesandoQR = true;
      _mensajeError = null;
      _ultimoTicketValidado = null;
    });

    try {
      // Obtener el validador ID
      final authViewModel = context.read<AuthViewModel>();
      final validadorId = authViewModel.currentUser?.id ?? 'admin';

      // Validar el ticket directamente
      final ticketsViewModel = context.read<TicketsViewModel>();
      final ticket = await ticketsViewModel.validarTicketPorQR(qrData, validadorId);

      setState(() {
        _ultimoTicketValidado = ticket;
        _mensajeError = null;
      });

      // Sonido/vibración de éxito (opcional)
      // HapticFeedback.heavyImpact();
      
    } catch (e) {
      setState(() {
        _mensajeError = e.toString().replaceAll('Exception: ', '');
        _ultimoTicketValidado = null;
      });

      // Sonido/vibración de error (opcional)
      // HapticFeedback.vibrate();
      
    } finally {
      setState(() {
        _procesandoQR = false;
      });
    }
  }

  void _reiniciarScanner() {
    setState(() {
      _mensajeError = null;
      _ultimoTicketValidado = null;
      _procesandoQR = false;
    });
  }
}
