# 🔵 Configuración de MercadoPago - Modo de Pruebas

## 📋 Resumen de Cambios Implementados

Se ha reemplazado completamente la simulación de Culqi por la integración real de **MercadoPago** en modo de pruebas. Ahora puedes usar tarjetas de prueba de MercadoPago para validar el flujo completo de pagos.

---

## 🚀 Pasos para Configurar

### 1️⃣ Obtener Credenciales de MercadoPago

1. Ve a [https://www.mercadopago.com.pe](https://www.mercadopago.com.pe)
2. **Inicia sesión** o crea una cuenta si no tienes una
3. Ve a **"Tu negocio"** > **"Configuración"** > **"Credenciales"**
4. Selecciona la pestaña **"Credenciales de prueba"** (Test)
5. Copia las dos credenciales:
   - **Public Key** (empieza con `TEST-...`)
   - **Access Token** (empieza con `TEST-...`)

### 2️⃣ Configurar las Credenciales en la App

1. Abre el archivo: `lib/config/mercadopago_config.dart`
2. Busca estas líneas:

```dart
static const String publicKeyTest = 'TEST-TU_PUBLIC_KEY_AQUI';
static const String accessTokenTest = 'TEST-TU_ACCESS_TOKEN_AQUI';
```

3. Reemplaza con tus credenciales:

```dart
static const String publicKeyTest = 'TEST-1234567890-abcdef...'; // Tu Public Key
static const String accessTokenTest = 'TEST-1234567890-abcdef...'; // Tu Access Token
```

4. Guarda el archivo

---

## 💳 Tarjetas de Prueba de MercadoPago

### ✅ Tarjetas que APRUEBAN el pago:

#### VISA - Aprobada
```
Número:      4509 9535 6623 3704
CVV:         123
Vencimiento: 11/25
Titular:     APRO
DNI:         12345678 (cualquier número de 8 dígitos)
```

#### MASTERCARD - Aprobada
```
Número:      5031 7557 3453 0604
CVV:         123
Vencimiento: 11/25
Titular:     APRO
DNI:         12345678 (cualquier número de 8 dígitos)
```

### ❌ Tarjetas que RECHAZAN el pago:

#### VISA - Fondos Insuficientes
```
Número:      4013 5406 8274 6260
CVV:         123
Vencimiento: 11/25
Titular:     FUND
DNI:         12345678
```

#### MASTERCARD - Fondos Insuficientes
```
Número:      5031 4332 1540 6351
CVV:         123
Vencimiento: 11/25
Titular:     FUND
DNI:         12345678
```

---

## 🧪 Cómo Probar

### Opción 1: Simulación Rápida (Actual)
Por ahora, el flujo está configurado para simular el pago exitoso al presionar el botón. Esto permite:
- ✅ Crear el ticket en Firestore
- ✅ Generar el PDF del comprobante
- ✅ Guardar el PDF localmente
- ✅ Enviar notificación por email (simulado)

### Opción 2: Integración Real con MercadoPago (Próximo)
Para implementar el flujo completo con formulario de tarjeta:

1. **Instalar dependencias adicionales** (si se necesita UI):
```yaml
# En pubspec.yaml
dependencies:
  mercadopago_sdk: ^1.0.0
  # O usar webview para cargar el checkout de MercadoPago
  webview_flutter: ^4.0.0
```

2. **Crear flujo de pago real**:
   - Mostrar formulario de tarjeta
   - Tokenizar los datos con MercadoPago
   - Crear el pago
   - Validar la respuesta

---

## 📱 Flujo de Pago Actual

1. Usuario llena los datos de la compra
2. Presiona "Pagar S/. XX.XX"
3. Se muestra un diálogo con:
   - Información de tarjetas de prueba
   - Instrucciones del modo de pruebas
   - Botón "Procesar pago de prueba"
4. Al confirmar:
   - Se crea el ticket en Firestore
   - Se genera el PDF
   - Se guarda localmente
   - Se simula envío por email

---

## 🔧 Archivos Modificados

### Nuevos archivos creados:
- `lib/services/mercadopago_service.dart` - Servicio de integración con MercadoPago
- `lib/config/mercadopago_config.dart` - Configuración de credenciales
- `CONFIGURACION_MERCADOPAGO.md` - Esta guía

### Archivos modificados:
- `lib/views/visitante/resumen_compra_page.dart` - UI actualizada con MercadoPago
- `pubspec.yaml` - Dependencia de MercadoPago agregada

### Archivos eliminados/reemplazados:
- ~~`lib/services/culqi_service.dart`~~ - Ya no se usa (puedes eliminarlo)

---

## 🎯 Próximos Pasos (Opcional)

Si deseas implementar el flujo completo con formulario de tarjeta:

### Opción A: Usar Checkout Pro (Recomendado para empezar)
```dart
// Crear preferencia y abrir en navegador
final mercadoPago = MercadoPagoService();
final preferencia = await mercadoPago.crearPreferencia(
  titulo: 'Entrada al Parque Perú',
  descripcion: 'Ticket #$ticketId',
  precio: _total,
  cantidad: 1,
  email: widget.emailComprador,
);

// Abrir el link de pago en el navegador
final url = preferencia['init_point']; // Para producción
final urlTest = preferencia['sandbox_init_point']; // Para pruebas
// Usar url_launcher para abrir
```

### Opción B: Crear Formulario Personalizado
```dart
// 1. Crear formulario con campos de tarjeta
// 2. Tokenizar con MercadoPago
final token = await mercadoPago.crearTokenTarjeta(
  cardNumber: '4509953566233704',
  cardholderName: 'APRO',
  expirationMonth: '11',
  expirationYear: '25',
  securityCode: '123',
  identificationType: 'DNI',
  identificationNumber: '12345678',
);

// 3. Crear pago
final pago = await mercadoPago.crearPagoDirecto(
  token: token!,
  monto: _total,
  installments: 1,
  email: widget.emailComprador,
  description: 'Ticket #$ticketId',
);

// 4. Verificar resultado
if (mercadoPago.esPagoAprobado(pago)) {
  // Pago exitoso
}
```

---

## 🔒 Seguridad

### ⚠️ IMPORTANTE:
- **NUNCA** subas las credenciales de producción a Git
- Las credenciales de prueba (TEST-...) son seguras para desarrollo
- Cuando pases a producción:
  1. Cambia `isProduction = true` en `mercadopago_config.dart`
  2. Configura las credenciales de producción
  3. Usa variables de entorno o Firebase Remote Config

### Buenas Prácticas:
```dart
// NO HACER (credenciales en código):
const publicKey = 'APP_USR-123456789-abcdef...';

// SÍ HACER (usar configuración externa):
final publicKey = const String.fromEnvironment('MP_PUBLIC_KEY');
// O Firebase Remote Config
// O archivo de configuración no versionado
```

---

## 📞 Soporte

### Documentación Oficial de MercadoPago:
- [Documentación Perú](https://www.mercadopago.com.pe/developers/es/docs)
- [Credenciales de prueba](https://www.mercadopago.com.pe/developers/es/docs/credentials)
- [Tarjetas de prueba](https://www.mercadopago.com.pe/developers/es/docs/test-cards)
- [API Reference](https://www.mercadopago.com.pe/developers/es/reference)

### ¿Problemas?
1. Verifica que las credenciales sean correctas
2. Asegúrate de que sean credenciales de PRUEBA (empiezan con TEST-)
3. Revisa la consola de debug para mensajes de error
4. Consulta la documentación oficial

---

## ✅ Checklist de Configuración

- [ ] Crear cuenta en MercadoPago
- [ ] Obtener credenciales de prueba
- [ ] Configurar `mercadopago_config.dart`
- [ ] Instalar dependencias (`flutter pub get`)
- [ ] Probar con tarjeta de prueba aprobada
- [ ] Probar con tarjeta de prueba rechazada
- [ ] Verificar que se cree el ticket en Firestore
- [ ] Verificar que se genere el PDF correctamente

---

## 🎉 ¡Listo!

Ahora tu app usa MercadoPago en modo de pruebas. Puedes:
- ✅ Probar con tarjetas de prueba
- ✅ Ver el flujo completo de pago
- ✅ Validar la creación de tickets
- ✅ Generar PDFs de comprobantes

Cuando estés listo para producción, solo necesitas:
1. Cambiar a credenciales de producción
2. Cambiar `isProduction = true`
3. ¡Lanzar tu app!
