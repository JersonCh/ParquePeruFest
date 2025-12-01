import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/mercadopago_config.dart';

class MercadoPagoService {
  // Usar credenciales desde la configuración
  String get _publicKey => MercadoPagoConfig.publicKey;
  String get _accessToken => MercadoPagoConfig.accessToken;
  static const String _baseUrl = 'https://api.mercadopago.com/v1';

  /// Crear preferencia de pago
  /// 
  /// Esto crea una preferencia que se puede usar para generar
  /// un link de pago o usar con el SDK de MercadoPago
  Future<Map<String, dynamic>> crearPreferencia({
    required String titulo,
    required String descripcion,
    required double precio,
    required int cantidad,
    required String email,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/checkout/preferences'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'items': [
            {
              'title': titulo,
              'description': descripcion,
              'quantity': cantidad,
              'currency_id': 'PEN', // Soles peruanos
              'unit_price': precio,
            }
          ],
          'payer': {
            'email': email,
          },
          'back_urls': {
            'success': MercadoPagoConfig.successUrl,
            'failure': MercadoPagoConfig.failureUrl,
            'pending': MercadoPagoConfig.pendingUrl,
          },
          'auto_return': 'approved',
          'statement_descriptor': 'PARQUE PERU',
          'external_reference': metadata?['ticketId'] ?? '',
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (kDebugMode) {
          debugPrint('✅ Preferencia creada: ${data['id']}');
          debugPrint('📱 Init Point: ${data['init_point']}');
          debugPrint('💳 Sandbox Init Point: ${data['sandbox_init_point']}');
        }
        
        return data;
      } else {
        final errorBody = response.body;
        if (kDebugMode) {
          debugPrint('❌ Error al crear preferencia: ${response.statusCode}');
          debugPrint('❌ Respuesta: $errorBody');
          debugPrint('❌ URL: $_baseUrl/checkout/preferences');
          debugPrint('❌ Access Token usado: ${_accessToken.substring(0, 20)}...');
        }
        throw Exception('Error al crear preferencia: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error en crearPreferencia: $e');
      }
      rethrow;
    }
  }

  /// Crear pago directo con tarjeta de prueba
  /// 
  /// Este método permite crear un pago directo usando los datos de la tarjeta
  /// Útil para modo de pruebas con tarjetas de prueba de MercadoPago
  Future<Map<String, dynamic>> crearPagoDirecto({
    required String token,
    required double monto,
    required int installments,
    required String email,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'X-Idempotency-Key': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        body: jsonEncode({
          'transaction_amount': monto,
          'token': token,
          'description': description,
          'installments': installments,
          'payment_method_id': 'visa', // Cambiar según la tarjeta
          'payer': {
            'email': email,
          },
          'external_reference': metadata?['ticketId'] ?? '',
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (kDebugMode) {
          debugPrint('✅ Pago creado: ${data['id']}');
          debugPrint('📊 Status: ${data['status']}');
          debugPrint('💰 Monto: ${data['transaction_amount']}');
        }
        
        return data;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Error al crear pago: ${response.body}');
        }
        throw Exception('Error al crear pago: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error en crearPagoDirecto: $e');
      }
      rethrow;
    }
  }

  /// Crear token de tarjeta
  /// 
  /// Tokeniza los datos de la tarjeta para crear un pago seguro
  Future<String?> crearTokenTarjeta({
    required String cardNumber,
    required String cardholderName,
    required String expirationMonth,
    required String expirationYear,
    required String securityCode,
    required String identificationType,
    required String identificationNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.mercadopago.com/v1/card_tokens'),
        headers: {
          'Authorization': 'Bearer $_publicKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'card_number': cardNumber,
          'cardholder': {
            'name': cardholderName,
            'identification': {
              'type': identificationType, // DNI, CE, RUC, etc
              'number': identificationNumber,
            },
          },
          'security_code': securityCode,
          'expiration_month': int.parse(expirationMonth),
          'expiration_year': int.parse(expirationYear),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as String;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Error al crear token: ${response.body}');
        }
        throw Exception('Error al crear token de tarjeta');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error en crearTokenTarjeta: $e');
      }
      rethrow;
    }
  }

  /// Verificar estado de pago
  Future<Map<String, dynamic>> verificarPago(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al verificar pago: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error en verificarPago: $e');
      }
      rethrow;
    }
  }

  /// Validar si el pago fue exitoso
  bool esPagoAprobado(Map<String, dynamic> pago) {
    return pago['status'] == 'approved';
  }

  /// Validar si el pago está pendiente
  bool esPagoPendiente(Map<String, dynamic> pago) {
    return pago['status'] == 'pending' || pago['status'] == 'in_process';
  }

  /// Validar si el pago fue rechazado
  bool esPagoRechazado(Map<String, dynamic> pago) {
    return pago['status'] == 'rejected' || pago['status'] == 'cancelled';
  }

  /// Obtener el ID de transacción
  String? obtenerTransactionId(Map<String, dynamic> pago) {
    return pago['id']?.toString();
  }

  /// Obtener mensaje de error si el pago falló
  String obtenerMensajeError(Map<String, dynamic> pago) {
    if (pago['status_detail'] != null) {
      return _traducirStatusDetail(pago['status_detail']);
    }
    return 'Error desconocido en el pago';
  }

  /// Traducir códigos de estado a mensajes en español
  String _traducirStatusDetail(String statusDetail) {
    const traducciones = {
      'cc_rejected_insufficient_amount': 'Fondos insuficientes',
      'cc_rejected_bad_filled_security_code': 'Código de seguridad inválido',
      'cc_rejected_bad_filled_date': 'Fecha de vencimiento inválida',
      'cc_rejected_bad_filled_card_number': 'Número de tarjeta inválido',
      'cc_rejected_card_disabled': 'Tarjeta deshabilitada',
      'cc_rejected_duplicated_payment': 'Pago duplicado',
      'cc_rejected_high_risk': 'Pago rechazado por riesgo',
      'cc_rejected_other_reason': 'Tarjeta rechazada',
      'cc_rejected_call_for_authorize': 'Debe autorizar el pago con el banco',
    };

    return traducciones[statusDetail] ?? statusDetail;
  }

  /// Obtener Public Key (para usar en el frontend)
  String get publicKey => _publicKey;

  /// Información de tarjetas de prueba de MercadoPago
  /// 
  /// Estas tarjetas puedes usarlas en modo de pruebas:
  /// 
  /// VISA (Aprobada):
  ///   - Número: 4509 9535 6623 3704
  ///   - CVV: 123
  ///   - Fecha: 11/25
  /// 
  /// MASTERCARD (Aprobada):
  ///   - Número: 5031 7557 3453 0604
  ///   - CVV: 123
  ///   - Fecha: 11/25
  /// 
  /// VISA (Rechazada):
  ///   - Número: 4013 5406 8274 6260
  ///   - CVV: 123
  ///   - Fecha: 11/25
  /// 
  /// MASTERCARD (Fondos insuficientes):
  ///   - Número: 5031 4332 1540 6351
  ///   - CVV: 123
  ///   - Fecha: 11/25
  /// 
  /// Nombre del titular: APRO (para aprobado) o cualquier nombre
  /// DNI: Cualquier número de 8 dígitos
  static const Map<String, dynamic> tarjetasPrueba = {
    'visa_aprobada': {
      'numero': '4509 9535 6623 3704',
      'cvv': '123',
      'vencimiento': '11/25',
      'titular': 'APRO',
    },
    'mastercard_aprobada': {
      'numero': '5031 7557 3453 0604',
      'cvv': '123',
      'vencimiento': '11/25',
      'titular': 'APRO',
    },
    'visa_rechazada': {
      'numero': '4013 5406 8274 6260',
      'cvv': '123',
      'vencimiento': '11/25',
      'titular': 'OTHE',
    },
    'mastercard_insuficientes': {
      'numero': '5031 4332 1540 6351',
      'cvv': '123',
      'vencimiento': '11/25',
      'titular': 'FUND',
    },
  };
}
