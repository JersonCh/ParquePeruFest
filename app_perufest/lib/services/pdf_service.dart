import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/ticket.dart';
import 'package:intl/intl.dart';

class PdfService {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _timeFormat = DateFormat('HH:mm');

  /// Genera el comprobante según el tipo de entrada
  static Future<Uint8List> generarComprobante({
    required Ticket ticket,
    required String nombreTitular,
    required String dniTitular,
    required String emailTitular,
    String? telefonoTitular,
    String? placaVehiculo,
    TipoVehiculo? tipoVehiculo,
    required DateTime fechaVisita,
    required double totalPagado,
    int cantidadAdultos = 0,
    int cantidadNinos = 0,
    int cantidadAdultosMayor = 0,
    String? metodoPago,
  }) async {
    switch (ticket.tipo) {
      case TipoEntrada.entrada:
        return await _generarComprobanteEntrada(
          ticket: ticket,
          nombreTitular: nombreTitular,
          dniTitular: dniTitular,
          emailTitular: emailTitular,
          telefonoTitular: telefonoTitular,
          fechaVisita: fechaVisita,
          totalPagado: totalPagado,
          cantidadAdultos: cantidadAdultos,
          cantidadNinos: cantidadNinos,
          cantidadAdultosMayor: cantidadAdultosMayor,
          metodoPago: metodoPago,
        );
      case TipoEntrada.cochera:
        return await _generarComprobanteCochera(
          ticket: ticket,
          nombreTitular: nombreTitular,
          dniTitular: dniTitular,
          telefonoTitular: telefonoTitular,
          placaVehiculo: placaVehiculo ?? '',
          tipoVehiculo: tipoVehiculo ?? TipoVehiculo.automovil,
          fechaVisita: fechaVisita,
          totalPagado: totalPagado,
          metodoPago: metodoPago,
        );
      case TipoEntrada.combo:
        return await _generarComprobanteCombo(
          ticket: ticket,
          nombreTitular: nombreTitular,
          dniTitular: dniTitular,
          emailTitular: emailTitular,
          telefonoTitular: telefonoTitular,
          placaVehiculo: placaVehiculo ?? '',
          tipoVehiculo: tipoVehiculo ?? TipoVehiculo.automovil,
          fechaVisita: fechaVisita,
          totalPagado: totalPagado,
          cantidadAdultos: cantidadAdultos,
          cantidadNinos: cantidadNinos,
          cantidadAdultosMayor: cantidadAdultosMayor,
          metodoPago: metodoPago,
        );
    }
  }

  /// COMPROBANTE DE ENTRADA
  static Future<Uint8List> _generarComprobanteEntrada({
    required Ticket ticket,
    required String nombreTitular,
    required String dniTitular,
    required String emailTitular,
    String? telefonoTitular,
    required DateTime fechaVisita,
    required double totalPagado,
    required int cantidadAdultos,
    required int cantidadNinos,
    required int cantidadAdultosMayor,
    String? metodoPago,
  }) async {
    final pdf = pw.Document();
    final qrData = 'ENTRADA-${ticket.id}';
    final cantidadTotal = cantidadAdultos + cantidadNinos + cantidadAdultosMayor;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeader('COMPROBANTE DE ENTRADA'),
              pw.SizedBox(height: 15),
              
              pw.Container(
                height: 80,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'PARQUE PERUFEST 2025',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 15),
              _buildInfoBox([
                'Código: #${ticket.id.substring(0, 10).toUpperCase()}',
                'Fecha emisión: ${_dateFormat.format(ticket.fechaCompra)} ${_timeFormat.format(ticket.fechaCompra)}',
              ]),

              pw.SizedBox(height: 15),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 2),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrData,
                      width: 150,
                      height: 150,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Escanea en la entrada',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue700,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),
              _buildSectionTitle('DATOS DE LA ENTRADA'),
              _buildInfoBox([
                'Tipo: Entrada General',
                'Modalidad: ${ticket.tipoTicket == TipoTicket.grupal ? "Ticket Grupal" : "Tickets Individuales"}',
                'Cantidad personas: $cantidadTotal',
                if (cantidadAdultos > 0) '  • Adultos: $cantidadAdultos',
                if (cantidadNinos > 0) '  • Niños: $cantidadNinos',
                if (cantidadAdultosMayor > 0) '  • Adultos mayores: $cantidadAdultosMayor',
                '',
                'Fecha visita: ${_formatearFechaLarga(fechaVisita)}',
                'Válido: Solo fecha indicada',
              ]),

              pw.SizedBox(height: 12),
              _buildSectionTitle('DATOS DEL TITULAR'),
              _buildInfoBox([
                'Nombre: $nombreTitular',
                'DNI: $dniTitular',
                'Email: $emailTitular',
                if (telefonoTitular != null) 'Teléfono: $telefonoTitular',
              ]),

              pw.SizedBox(height: 12),
              _buildSectionTitle('RESUMEN DE PAGO'),
              _buildPagoBox(
                items: [
                  if (cantidadAdultos > 0) 'Entrada adulto x$cantidadAdultos: S/. ${(cantidadAdultos * 10.0).toStringAsFixed(2)}',
                  if (cantidadNinos > 0) 'Entrada niño x$cantidadNinos: S/. ${(cantidadNinos * 5.0).toStringAsFixed(2)}',
                  if (cantidadAdultosMayor > 0) 'Entrada adulto mayor x$cantidadAdultosMayor: S/. ${(cantidadAdultosMayor * 7.0).toStringAsFixed(2)}',
                ],
                total: totalPagado,
                metodoPago: metodoPago,
              ),

              pw.SizedBox(height: 12),
              _buildSectionTitle('INSTRUCCIONES'),
              _buildInfoBox([
                '✓ Presenta este QR en la entrada',
                '✓ Válido solo para la fecha indicada',
                '✓ No se permiten reembolsos',
                '✓ Llegada sugerida: 30 min antes',
              ]),

              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// COMPROBANTE DE COCHERA
  static Future<Uint8List> _generarComprobanteCochera({
    required Ticket ticket,
    required String nombreTitular,
    required String dniTitular,
    String? telefonoTitular,
    required String placaVehiculo,
    required TipoVehiculo tipoVehiculo,
    required DateTime fechaVisita,
    required double totalPagado,
    String? metodoPago,
  }) async {
    final pdf = pw.Document();
    final qrData = 'COCHERA-${ticket.id}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeader('COMPROBANTE DE COCHERA'),
              pw.SizedBox(height: 15),

              pw.Container(
                height: 80,
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'ESTACIONAMIENTO SEGURO',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 15),
              _buildInfoBox([
                'Código: #${ticket.id.substring(0, 10).toUpperCase()}',
                'Fecha emisión: ${_dateFormat.format(ticket.fechaCompra)}',
              ]),

              pw.SizedBox(height: 15),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 2),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrData,
                      width: 150,
                      height: 150,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Escanea al ingresar',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange700,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),
              _buildSectionTitle('DATOS DEL VEHÍCULO'),
              _buildInfoBox([
                'Tipo: ${_tipoVehiculoToString(tipoVehiculo)}',
                'Placa: $placaVehiculo',
                '',
                'Fecha visita: ${_formatearFechaLarga(fechaVisita)}',
                'Horario: Todo el día',
              ]),

              pw.SizedBox(height: 12),
              _buildSectionTitle('DATOS DEL TITULAR'),
              _buildInfoBox([
                'Nombre: $nombreTitular',
                'DNI: $dniTitular',
                if (telefonoTitular != null) 'Teléfono: $telefonoTitular',
              ]),

              pw.SizedBox(height: 12),
              _buildSectionTitle('RESUMEN DE PAGO'),
              _buildPagoBox(
                items: [
                  'Cochera ${_tipoVehiculoToString(tipoVehiculo).toLowerCase()}: S/. ${totalPagado.toStringAsFixed(2)}',
                ],
                total: totalPagado,
                metodoPago: metodoPago,
              ),

              pw.SizedBox(height: 12),
              _buildSectionTitle('CONDICIONES'),
              _buildInfoBox([
                '✓ Estacionamiento vigilado 24h',
                '✓ No nos hacemos responsables por',
                '  objetos dejados en el vehículo',
                '✓ Respeta señalización interna',
              ]),

              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// COMPROBANTE COMBO
  static Future<Uint8List> _generarComprobanteCombo({
    required Ticket ticket,
    required String nombreTitular,
    required String dniTitular,
    required String emailTitular,
    String? telefonoTitular,
    required String placaVehiculo,
    required TipoVehiculo tipoVehiculo,
    required DateTime fechaVisita,
    required double totalPagado,
    required int cantidadAdultos,
    required int cantidadNinos,
    required int cantidadAdultosMayor,
    String? metodoPago,
  }) async {
    final pdf = pw.Document();
    final qrEntrada = 'ENTRADA-${ticket.id}';
    final qrCochera = 'COCHERA-${ticket.id}';
    final cantidadTotal = cantidadAdultos + cantidadNinos + cantidadAdultosMayor;

    final precioEntrada = (cantidadAdultos * 10.0) + (cantidadNinos * 5.0) + (cantidadAdultosMayor * 7.0);
    final precioCochera = 15.0;
    final subtotal = precioEntrada + precioCochera;
    final descuento = subtotal * 0.05;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeader('COMPROBANTE COMBO COMPLETO'),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple700,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '⭐ PAQUETE PREMIUM',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 12),
              pw.Container(
                height: 70,
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'PARQUE PERUFEST 2025',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple800,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 12),
              _buildInfoBox([
                'Código: #${ticket.id.substring(0, 10).toUpperCase()}',
                'Fecha emisión: ${_dateFormat.format(ticket.fechaCompra)} ${_timeFormat.format(ticket.fechaCompra)}',
              ]),

              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 2),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: qrEntrada,
                            width: 100,
                            height: 100,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Entrada',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 2),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: qrCochera,
                            width: 100,
                            height: 100,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Cochera',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              _buildSectionTitle('🎫 ENTRADA AL PARQUE'),
              _buildInfoBox([
                'Modalidad: ${ticket.tipoTicket == TipoTicket.grupal ? "Ticket Grupal" : "Tickets Individuales"}',
                'Cantidad personas: $cantidadTotal',
                if (cantidadAdultos > 0) '  • Adultos: $cantidadAdultos',
                if (cantidadNinos > 0) '  • Niños: $cantidadNinos',
                if (cantidadAdultosMayor > 0) '  • Adultos mayores: $cantidadAdultosMayor',
                '',
                'Fecha visita: ${_formatearFechaLarga(fechaVisita)}',
              ]),

              pw.SizedBox(height: 8),
              _buildSectionTitle('🚗 ESTACIONAMIENTO'),
              _buildInfoBox([
                'Tipo vehículo: ${_tipoVehiculoToString(tipoVehiculo)}',
                'Placa: $placaVehiculo',
                'Espacio garantizado',
              ]),

              pw.SizedBox(height: 8),
              _buildSectionTitle('DATOS DEL TITULAR'),
              _buildInfoBox([
                'Nombre: $nombreTitular',
                'DNI: $dniTitular',
                'Email: $emailTitular',
                if (telefonoTitular != null) 'Teléfono: $telefonoTitular',
              ]),

              pw.SizedBox(height: 8),
              _buildSectionTitle('RESUMEN DE PAGO'),
              _buildPagoBox(
                items: [
                  if (cantidadAdultos > 0) 'Entrada adulto x$cantidadAdultos: S/. ${(cantidadAdultos * 10.0).toStringAsFixed(2)}',
                  if (cantidadNinos > 0) 'Entrada niño x$cantidadNinos: S/. ${(cantidadNinos * 5.0).toStringAsFixed(2)}',
                  if (cantidadAdultosMayor > 0) 'Entrada adulto mayor x$cantidadAdultosMayor: S/. ${(cantidadAdultosMayor * 7.0).toStringAsFixed(2)}',
                  'Cochera ${_tipoVehiculoToString(tipoVehiculo).toLowerCase()}: S/. ${precioCochera.toStringAsFixed(2)}',
                  'Subtotal: S/. ${subtotal.toStringAsFixed(2)}',
                  'Descuento combo (5%): - S/. ${descuento.toStringAsFixed(2)}',
                ],
                total: totalPagado,
                metodoPago: metodoPago,
                mostrarAhorro: true,
                ahorro: descuento,
              ),

              pw.SizedBox(height: 8),
              _buildSectionTitle('INSTRUCCIONES'),
              _buildInfoBox([
                '1. Presenta QR entrada en puerta',
                '2. Presenta QR cochera al pasar',
                '3. Ambos QRs son obligatorios',
                '4. Válido solo fecha indicada',
              ]),

              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ==================== WIDGETS AUXILIARES ====================

  static pw.Widget _buildHeader(String titulo) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue700,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Center(
            child: pw.Text(
              'PARQUE PERU FEST',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          titulo,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String titulo) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        titulo,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey900,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoBox(List<String> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items.map((item) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              item,
              style: const pw.TextStyle(fontSize: 9),
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildPagoBox({
    required List<String> items,
    required double total,
    String? metodoPago,
    bool mostrarAhorro = false,
    double ahorro = 0,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          ...items.map((item) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                item,
                style: const pw.TextStyle(fontSize: 9),
              ),
            );
          }),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL PAGADO:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'S/. ${total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
            ],
          ),
          if (metodoPago != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Método: $metodoPago',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
          if (mostrarAhorro && ahorro > 0) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              'Ahorraste: S/. ${ahorro.toStringAsFixed(2)} 🎉',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text(
          '¿Necesitas ayuda?',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'WhatsApp: +51 999 888 777 | Email: soporte@perufest.pe',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'www.parqueperufest.com',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
      ],
    );
  }

  // ==================== UTILIDADES ====================

  static String _formatearFechaLarga(DateTime fecha) {
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    
    final dia = dias[fecha.weekday - 1];
    final mes = meses[fecha.month - 1];
    
    return '$dia, ${fecha.day} de $mes ${fecha.year}';
  }

  static String _tipoVehiculoToString(TipoVehiculo tipo) {
    switch (tipo) {
      case TipoVehiculo.automovil:
        return 'Automóvil';
      case TipoVehiculo.camioneta:
        return 'Camioneta';
      case TipoVehiculo.motocicleta:
        return 'Motocicleta';
      case TipoVehiculo.otro:
        return 'Otro';
    }
  }
}
