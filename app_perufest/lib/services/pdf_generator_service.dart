import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart' show Color;
import '../models/ticket.dart';
import 'qr_service.dart';

class PdfGeneratorService {
  final QRService _qrService = QRService();

  /// Generar PDF del comprobante de ticket
  Future<Uint8List> generarComprobante(Ticket ticket) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Encabezado
                _buildEncabezado(ticket),
                
                pw.SizedBox(height: 20),
                
                // Separador
                _buildSeparador(_getPdfColor(ticket.colorTema)),
                
                pw.SizedBox(height: 20),
                
                // Datos del comprador
                _buildDatosComprador(ticket),
                
                pw.SizedBox(height: 20),
                
                // Monto
                _buildMonto(ticket),
                
                pw.SizedBox(height: 20),
                
                // Separador
                _buildSeparador(_getPdfColor(ticket.colorTema)),
                
                pw.SizedBox(height: 20),
                
                // QR Code (simulado con texto por ahora)
                _buildQRPlaceholder(ticket),
                
                pw.SizedBox(height: 10),
                
                // ID del ticket
                pw.Text(
                  ticket.idFormateado,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Separador
                _buildSeparador(_getPdfColor(ticket.colorTema)),
                
                pw.SizedBox(height: 10),
                
                // Beneficios según tipo
                _buildBeneficios(ticket),
                
                pw.SizedBox(height: 20),
                
                // Información del vehículo (si aplica)
                if (ticket.placaVehiculo != null)
                  _buildInfoVehiculo(ticket),
                
                pw.Spacer(),
                
                // Footer
                _buildFooter(ticket),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildEncabezado(Ticket ticket) {
    return pw.Column(
      children: [
        // Logo (texto por ahora)
        pw.Container(
          height: 60,
          child: pw.Center(
            child: pw.Text(
              '🌳 PARQUE PERÚ',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
        
        pw.SizedBox(height: 10),
        
        // Título del ticket
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: pw.BoxDecoration(
            color: _getPdfColor(ticket.colorTema),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(
            ticket.titulo,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        
        // Subtítulo para tickets grupales
        if (ticket.tipoTicket == TipoTicket.grupal)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              '${ticket.cantidadPersonas} personas',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _getPdfColor(ticket.colorTema),
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildSeparador(PdfColor color) {
    return pw.Container(
      height: 2,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: color,
            width: 2,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildDatosComprador(Ticket ticket) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final formatoHora = DateFormat('HH:mm');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildDatoRow('Nombre:', ticket.nombreComprador),
        _buildDatoRow('DNI:', ticket.dniComprador),
        if (ticket.placaVehiculo != null)
          _buildDatoRow('Placa:', '${ticket.placaVehiculo} 🚙'),
        _buildDatoRow('Fecha visita:', formatoFecha.format(ticket.fechaValidez)),
        _buildDatoRow('Hora compra:', formatoHora.format(ticket.fechaCompra)),
      ],
    );
  }

  pw.Widget _buildDatoRow(String label, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(valor)),
        ],
      ),
    );
  }

  pw.Widget _buildMonto(Ticket ticket) {
    final pdfColor = _getPdfColor(ticket.colorTema);
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor(pdfColor.red, pdfColor.green, pdfColor.blue, 0.1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'MONTO PAGADO',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'S/. ${ticket.monto.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _getPdfColor(ticket.colorTema),
            ),
          ),
          if (ticket.tipo == TipoEntrada.combo && ticket.tipoTicket == TipoTicket.grupal)
            pw.Text(
              '(${ticket.cantidadPersonas} entrada${ticket.cantidadPersonas > 1 ? 's' : ''} + cochera)',
              style: const pw.TextStyle(fontSize: 10),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildQRPlaceholder(Ticket ticket) {
    // QR Code real usando pw.BarcodeWidget
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.BarcodeWidget(
        data: ticket.qrData,
        barcode: pw.Barcode.qrCode(),
        width: 180,
        height: 180,
        drawText: false,
      ),
    );
  }

  pw.Widget _buildBeneficios(Ticket ticket) {
    List<String> beneficios;
    
    switch (ticket.tipo) {
      case TipoEntrada.entrada:
        if (ticket.tipoTicket == TipoTicket.grupal) {
          beneficios = [
            '✓ Ingreso de ${ticket.cantidadPersonas} personas',
            '✓ Acceso a todas las zonas',
            '✓ Válido un solo día',
            '✓ Todos deben ingresar juntos',
          ];
        } else {
          beneficios = [
            '✓ Ingreso al parque',
            '✓ Acceso a todas las zonas',
            '✓ Válido un solo día',
          ];
        }
        break;
      case TipoEntrada.cochera:
        beneficios = [
          '✓ Estacionamiento incluido',
          '✓ Válido todo el día',
          '✓ Espacio asegurado',
        ];
        break;
      case TipoEntrada.combo:
        if (ticket.tipoTicket == TipoTicket.grupal) {
          beneficios = [
            '✓ Ingreso de ${ticket.cantidadPersonas} personas',
            '✓ Estacionamiento incluido',
            '✓ Acceso completo',
            '✓ Válido todo el día',
          ];
        } else {
          beneficios = [
            '✓ Ingreso al parque',
            '✓ Estacionamiento incluido',
            '✓ Acceso completo',
            '✓ Válido todo el día',
          ];
        }
        break;
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: beneficios.map((b) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Text(b, style: const pw.TextStyle(fontSize: 12)),
      )).toList(),
    );
  }

  pw.Widget _buildInfoVehiculo(Ticket ticket) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Información del vehículo:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Placa: ${ticket.placaVehiculo}'),
          pw.Text('Tipo: ${_getNombreTipoVehiculo(ticket.tipoVehiculo)}'),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(Ticket ticket) {
    String instruccion;
    
    switch (ticket.tipo) {
      case TipoEntrada.entrada:
        instruccion = 'Presente este QR en puerta';
        break;
      case TipoEntrada.cochera:
        instruccion = 'Presente este QR al ingreso del estacionamiento';
        break;
      case TipoEntrada.combo:
        instruccion = 'Presente este QR único en puerta y estacionamiento';
        break;
    }
    
    return pw.Column(
      children: [
        _buildSeparador(_getPdfColor(ticket.colorTema)),
        pw.SizedBox(height: 8),
        pw.Text(
          instruccion,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Tacna - Perú 🇵🇪',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Parque Perú - Disfruta en familia',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }

  // Helpers
  PdfColor _getPdfColor(Color color) {
    return PdfColor(
      color.red / 255,
      color.green / 255,
      color.blue / 255,
    );
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
}
