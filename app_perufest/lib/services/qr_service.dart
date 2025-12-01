import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/ticket.dart';

class QRService {
  // Clave secreta para firmar los QR (en producción debe estar en variables de entorno)
  static const String _secretKey = 'ParquePeruFest2025_SecretKey';

  /// Generar datos QR para un ticket
  String generarQRData(Ticket ticket) {
    final data = {
      'id': ticket.id,
      'tipo': ticket.tipo.name,
      'tipoTicket': ticket.tipoTicket.name,
      'cantidadPersonas': ticket.cantidadPersonas,
      'fechaValidez': ticket.fechaValidez.toIso8601String(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final jsonData = jsonEncode(data);
    final hash = _generarHash(jsonData);

    // Combinar datos + hash para verificación
    final qrData = {
      'data': jsonData,
      'hash': hash,
    };

    return jsonEncode(qrData);
  }

  /// Validar datos QR
  bool validarQRData(String qrData) {
    try {
      final decoded = jsonDecode(qrData) as Map<String, dynamic>;
      final data = decoded['data'] as String;
      final hash = decoded['hash'] as String;

      // Verificar que el hash coincida
      final hashCalculado = _generarHash(data);
      return hash == hashCalculado;
    } catch (e) {
      return false;
    }
  }

  /// Extraer información del QR
  Map<String, dynamic>? extraerDatosQR(String qrData) {
    try {
      if (!validarQRData(qrData)) {
        return null;
      }

      final decoded = jsonDecode(qrData) as Map<String, dynamic>;
      final data = decoded['data'] as String;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Generar hash de seguridad
  String _generarHash(String data) {
    final bytes = utf8.encode(data + _secretKey);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generar QR simple para ticket individual
  String generarQRSimple(String ticketId) {
    return 'TICKET:$ticketId';
  }

  /// Generar QR para ticket grupal
  String generarQRGrupal(String ticketId, int cantidadPersonas) {
    final data = {
      'ticketId': ticketId,
      'tipo': 'grupal',
      'personas': cantidadPersonas,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    final jsonData = jsonEncode(data);
    final hash = _generarHash(jsonData);
    
    return jsonEncode({
      'data': jsonData,
      'hash': hash,
    });
  }

  /// Verificar si un QR es válido y no ha expirado
  bool verificarValidezQR(String qrData, {int horasValidez = 24}) {
    try {
      final datos = extraerDatosQR(qrData);
      if (datos == null) return false;

      final timestamp = datos['timestamp'] as int;
      final fechaGeneracion = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final fechaExpiracion = fechaGeneracion.add(Duration(hours: horasValidez));

      return DateTime.now().isBefore(fechaExpiracion);
    } catch (e) {
      return false;
    }
  }
}
