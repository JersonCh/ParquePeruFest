/// Configuración de credenciales de MercadoPago
/// 
/// IMPORTANTE: En producción, estas credenciales deben estar en variables de entorno
/// o en un archivo de configuración seguro que NO se suba a Git.
/// 
/// Para obtener tus credenciales:
/// 1. Inicia sesión en https://www.mercadopago.com.pe
/// 2. Ve a "Tu negocio" > "Configuración" > "Credenciales"
/// 3. Copia las credenciales de PRUEBA (Test) para desarrollo
/// 4. Cuando estés listo para producción, usa las credenciales de PRODUCCIÓN
/// 
/// TARJETAS DE PRUEBA:
/// ==================
/// Puedes usar estas tarjetas en modo de pruebas:
/// 
/// VISA (Aprobada):
///   Número: 4509 9535 6623 3704
///   CVV: 123
///   Vencimiento: 11/25
///   Titular: APRO
///   DNI: Cualquier número de 8 dígitos
/// 
/// MASTERCARD (Aprobada):
///   Número: 5031 7557 3453 0604
///   CVV: 123
///   Vencimiento: 11/25
///   Titular: APRO
///   DNI: Cualquier número de 8 dígitos
/// 
/// VISA (Rechazada por fondos insuficientes):
///   Número: 4013 5406 8274 6260
///   CVV: 123
///   Vencimiento: 11/25
///   Titular: FUND
///   DNI: Cualquier número de 8 dígitos

class MercadoPagoConfig {
  // ============================================
  // CREDENCIALES DE PRUEBA (TEST)
  // ============================================
  // Estas credenciales son de la pestaña "Prueba" de MercadoPago
  // Nota: Algunas cuentas de MercadoPago Perú usan formato APP_USR- incluso en prueba
  
  static const String publicKeyTest = 'APP_USR-8138a93b-5b4d-4ca6-85d5-96f9466f92ca';
  static const String accessTokenTest = 'APP_USR-8631200904506416-120114-34fdfd51bcddbbb286f2383faefb5669-3032062835';
  
  // ============================================
  // CREDENCIALES DE PRODUCCIÓN
  // ============================================
  // Cuando estés listo para producción, descomenta y reemplaza:
  
  // static const String publicKeyProd = 'APP_USR-TU_PUBLIC_KEY_PRODUCCION';
  // static const String accessTokenProd = 'APP_USR-TU_ACCESS_TOKEN_PRODUCCION';
  
  // ============================================
  // CONFIGURACIÓN ACTUAL
  // ============================================
  // Cambia esto a true cuando uses producción
  static const bool isProduction = false;
  
  // Credenciales activas según el entorno
  static String get publicKey => isProduction 
      ? '' // publicKeyProd cuando esté en producción
      : publicKeyTest;
      
  static String get accessToken => isProduction 
      ? '' // accessTokenProd cuando esté en producción
      : accessTokenTest;
  
  // ============================================
  // OTRAS CONFIGURACIONES
  // ============================================
  
  /// URL base de la API de MercadoPago
  static const String apiBaseUrl = 'https://api.mercadopago.com/v1';
  
  /// Nombre que aparecerá en el estado de cuenta
  static const String statementDescriptor = 'PARQUE PERU';
  
  /// Moneda (PEN = Soles Peruanos)
  static const String currency = 'PEN';
  
  /// URLs de retorno después del pago
  /// IMPORTANTE: MercadoPago requiere URLs HTTPS para crear preferencias
  /// Usamos URLs temporales de ejemplo que luego se interceptan con Deep Links
  static const String successUrl = 'https://parqueperufest.com/payment/success';
  static const String failureUrl = 'https://parqueperufest.com/payment/failure';
  static const String pendingUrl = 'https://parqueperufest.com/payment/pending';
  
  /// Deep Links para interceptar las URLs de retorno
  static const String deepLinkSuccess = 'appperufest://payment/success';
  static const String deepLinkFailure = 'appperufest://payment/failure';
  static const String deepLinkPending = 'appperufest://payment/pending';
  
  /// URL para notificaciones de webhook
  static const String webhookUrl = 'https://parqueperu.com/webhook';
  
  /// Cuotas disponibles (1 = pago en una sola cuota)
  static const int defaultInstallments = 1;
  
  // ============================================
  // VALIDACIÓN
  // ============================================
  
  /// Verifica si las credenciales están configuradas
  static bool get areCredentialsConfigured {
    return publicKey.isNotEmpty && 
           accessToken.isNotEmpty &&
           !publicKey.contains('TU_PUBLIC_KEY') &&
           !accessToken.contains('TU_ACCESS_TOKEN');
  }
  
  /// Mensaje de ayuda si las credenciales no están configuradas
  static String get configurationHelp => '''
╔═══════════════════════════════════════════════════════════════╗
║  CONFIGURACIÓN DE MERCADOPAGO REQUERIDA                      ║
╚═══════════════════════════════════════════════════════════════╝

Para usar MercadoPago, sigue estos pasos:

1. Ve a: https://www.mercadopago.com.pe
2. Inicia sesión o crea una cuenta
3. Ve a: Tu negocio > Configuración > Credenciales
4. Copia tu PUBLIC KEY de prueba
5. Copia tu ACCESS TOKEN de prueba
6. Pega las credenciales en:
   lib/config/mercadopago_config.dart

Archivo a editar:
  publicKeyTest = 'TEST-xxxxxxxx...'
  accessTokenTest = 'TEST-xxxxxxxx...'

¡Importante! 
- Usa credenciales de PRUEBA para desarrollo
- NUNCA subas las credenciales de producción a Git
- Las credenciales de TEST empiezan con "TEST-"
''';
}
