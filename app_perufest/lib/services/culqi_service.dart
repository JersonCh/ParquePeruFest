import 'dart:convert';
import 'package:http/http.dart' as http;

class CulqiService {
  // En producción, estas claves deben estar en variables de entorno
  static const String _publicKey = 'pk_test_XXXXXXXXXXXXXXXX'; // Reemplazar con tu clave pública
  static const String _secretKey = 'sk_test_XXXXXXXXXXXXXXXX'; // Reemplazar con tu clave secreta
  static const String _baseUrl = 'https://api.culqi.com/v2';

  /// Crear un token de tarjeta
  Future<String?> crearToken({
    required String cardNumber,
    required String cvv,
    required String expirationMonth,
    required String expirationYear,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tokens'),
        headers: {
          'Authorization': 'Bearer $_publicKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'card_number': cardNumber,
          'cvv': cvv,
          'expiration_month': expirationMonth,
          'expiration_year': expirationYear,
          'email': email,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as String;
      } else {
        throw Exception('Error al crear token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en crearToken: $e');
    }
  }

  /// Crear un cargo (cobro)
  Future<Map<String, dynamic>> crearCargo({
    required String tokenId,
    required int amount, // Monto en centavos (ej: 1000 = 10.00 soles)
    required String currency, // 'PEN' para soles
    required String email,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/charges'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'currency_code': currency,
          'email': email,
          'source_id': tokenId,
          'description': description,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al crear cargo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en crearCargo: $e');
    }
  }

  /// Procesar pago completo (crear token + cargo)
  Future<Map<String, dynamic>> procesarPago({
    required String cardNumber,
    required String cvv,
    required String expirationMonth,
    required String expirationYear,
    required String email,
    required double monto, // Monto en soles
    required String descripcion,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 1. Crear token
      final tokenId = await crearToken(
        cardNumber: cardNumber,
        cvv: cvv,
        expirationMonth: expirationMonth,
        expirationYear: expirationYear,
        email: email,
      );

      if (tokenId == null) {
        throw Exception('No se pudo crear el token de pago');
      }

      // 2. Crear cargo
      final montoEnCentavos = (monto * 100).round();
      final cargo = await crearCargo(
        tokenId: tokenId,
        amount: montoEnCentavos,
        currency: 'PEN',
        email: email,
        description: descripcion,
        metadata: metadata,
      );

      return cargo;
    } catch (e) {
      throw Exception('Error al procesar pago: $e');
    }
  }

  /// Verificar estado de un cargo
  Future<Map<String, dynamic>> verificarCargo(String chargeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/charges/$chargeId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al verificar cargo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en verificarCargo: $e');
    }
  }

  /// Validar respuesta de pago
  bool validarPagoExitoso(Map<String, dynamic> cargo) {
    return cargo['object'] == 'charge' && 
           cargo['outcome']?['type'] == 'venta_exitosa';
  }

  /// Obtener ID de transacción
  String? obtenerTransactionId(Map<String, dynamic> cargo) {
    return cargo['id'] as String?;
  }

  /// Formatear monto para Culqi (soles a centavos)
  int formatearMonto(double monto) {
    return (monto * 100).round();
  }

  /// Formatear monto de Culqi (centavos a soles)
  double formatearMontoDesdeCulqi(int montoCentavos) {
    return montoCentavos / 100;
  }
}
