# Sistema de Venta de Tickets - Parque Perú Fest

## ✅ Funcionalidades Implementadas

### 1. Dashboard de Estadísticas (Admin)
**Ubicación:** `lib/views/admin/dashboard_ventas_page.dart`

**Características:**
- Selector de fecha para estadísticas diarias
- Visualización de 4 métricas principales:
  - Tickets vendidos
  - Personas esperadas
  - Cocheras reservadas
  - Ingresos totales (S/.)
- Desglose por tipo de ticket (individual/grupal/múltiple)
- Promedios calculados automáticamente
- Diseño coherente con el resto de la app (color azul #1976D2)

**Uso:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DashboardVentasPage()),
);
```

---

### 2. Flujo de Compra (Visitantes)

#### 2.1 Selección de Entradas
**Ubicación:** `lib/views/visitante/comprar_entradas_page.dart`

**Características:**
- Tres tipos de entrada con colores distintivos:
  - 🟢 Entrada Normal (Verde - #4CAF50)
  - 🟠 Cochera (Naranja - #FF9800)
  - 🟣 Combo Entrada + Cochera (Morado - #9C27B0)
- Selector de cantidad
- Desglose de personas (adultos/niños/adultos mayores)
- Resumen de monto en tiempo real

#### 2.2 Formulario de Compra
**Ubicación:** `lib/views/visitante/formulario_compra_page.dart`

**Características adaptativas:**
- Selector de tipo de ticket (si 2+ personas):
  - **Grupal**: 1 QR para todo el grupo
  - **Múltiple**: 1 QR individual por persona
- Datos del comprador (nombre, DNI, email, teléfono)
- Datos del vehículo (solo si es cochera/combo):
  - Tipo de vehículo (auto/camioneta/moto)
  - Placa
  - Cantidad de vehículos
- Selector de fecha de visita
- Validaciones en tiempo real

#### 2.3 Resumen y Pago
**Ubicación:** `lib/views/visitante/resumen_compra_page.dart`

**Características:**
- Resumen completo de la compra
- Información del comprador
- Información del vehículo (si aplica)
- Desglose de precios
- Aceptación de términos y condiciones
- Integración con Culqi (simulada)
- Generación automática de PDF tras pago exitoso

**Flujo de navegación:**
```dart
// 1. Selección
Navigator.push(context, ComprarEntradasPage());

// 2. Formulario
Navigator.push(context, FormularioCompraPage(datosSeleccion));

// 3. Resumen y pago
Navigator.push(context, ResumenCompraPage(datosCompletos));
```

---

### 3. Mis Tickets (Visitantes)
**Ubicación:** `lib/views/visitante/mis_tickets_page.dart`

**Características:**
- Lista de todos los tickets del usuario
- Filtros:
  - Todos
  - Activos (pagados y no expirados)
  - Usados
  - Expirados
- Cards con información detallada:
  - Tipo de entrada con color distintivo
  - ID formateado
  - Fecha de visita
  - Cantidad de personas
  - Monto pagado
  - Placa de vehículo (si aplica)
  - Estado visual (chip con icono)
- Pull-to-refresh
- Botón "Mostrar QR" para tickets activos
- Vista de QR en diálogo

**Uso:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const MisTicketsPage()),
);
```

---

### 4. Validador de Tickets QR (Admin)
**Ubicación:** `lib/views/admin/validar_tickets_page.dart`

**Características:**
- Scanner de cámara en tiempo real
- Guías visuales para centrar el QR
- Controles de flash y cámara
- Validación automática al detectar QR
- Tres estados visuales:
  - **Instrucciones** (esperando QR)
  - **✅ Ticket Válido** (verde con información completa)
  - **❌ Ticket No Válido** (rojo con mensaje de error)
- Información del ticket validado:
  - Tipo de entrada
  - ID del ticket
  - Cantidad de personas
  - Placa (si aplica)
  - Fecha de validez
  - Hora de validación
- Indicador especial para tickets grupales
- Botón para escanear siguiente ticket

**Validaciones implementadas:**
- Formato de QR válido (con hash SHA256)
- Ticket pagado
- Ticket no usado previamente
- Ticket no expirado

**Uso:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ValidarTicketsPage()),
);
```

---

## 📦 Modelos de Datos

### Ticket
**Ubicación:** `lib/models/ticket.dart`

**Enums incluidos:**
```dart
enum TipoEntrada { entrada, cochera, combo }
enum TipoTicket { individual, grupal, multiple }
enum EstadoTicket { pendiente, pagado, usado, cancelado, expirado }
enum TipoPersona { adulto, nino, adultoMayor }
enum TipoVehiculo { auto, camioneta, moto }
```

**Propiedades principales:**
- `id`, `ordenId`, `userId`
- `tipo` (TipoEntrada)
- `tipoTicket` (TipoTicket)
- `estado` (EstadoTicket)
- `cantidadPersonas`, `personas` (List<PersonaTicket>)
- `cantidadVehiculos`, `tipoVehiculo`, `placaVehiculo`
- `monto`, `moneda`
- `fechaCompra`, `fechaValidez`, `fechaUso`
- `qrData`, `qrHash`
- `transactionId`

**Getters útiles:**
- `colorTema` - Color según tipo de entrada
- `icono` - IconData según tipo de entrada
- `titulo` - Nombre descriptivo
- `idFormateado` - ID en formato TKT-XXXXXX
- `estaActivo` - bool (pagado y no expirado)
- `estaExpirado` - bool (fecha pasada)

### OrdenCompra
**Ubicación:** `lib/models/orden_compra.dart`

**Propiedades:**
- `id`, `userId`
- `numeroOrden`, `transactionId`
- `ticketsIds` (lista de IDs de tickets)
- `montoTotal`, `moneda`
- `cantidadEntradas`, `cantidadCocheras`, `totalPersonas`
- `fechaCompra`, `fechaVisita`
- `estado` (EstadoTicket)
- Datos del comprador (nombre, DNI, email, teléfono)

---

## 🔧 Servicios

### TicketsService
**Ubicación:** `lib/services/tickets_service.dart`

**Métodos principales:**
```dart
// Consultas
Future<List<Ticket>> obtenerTicketsPorFecha(DateTime fecha)
Future<List<Ticket>> obtenerTicketsPorUsuario(String userId)

// Validación
Future<bool> validarTicket(String qrData, String validadorId)

// Creación
Future<OrdenCompra> crearOrdenCompleta({...})

// Cancelación
Future<bool> cancelarOrden(String ordenId)
```

### QRService
**Ubicación:** `lib/services/qr_service.dart`

**Métodos:**
```dart
// Generar QR con firma SHA256
String generarQRData(Ticket ticket, String secretKey)

// Validar integridad del QR
bool validarQRData(String qrData, String secretKey)

// Extraer datos del QR
Map<String, String>? extraerDatosQR(String qrData)
```

**Formato del QR:**
```
TKT|ID|TIPO|FECHA|PERSONAS|HASH
Ejemplo: TKT|abc123|grupal|2024-01-15|4|sha256hash...
```

### PdfGeneratorService
**Ubicación:** `lib/services/pdf_generator_service.dart`

**Métodos:**
```dart
// Generar comprobante diferenciado por tipo
Future<File> generarComprobante(OrdenCompra orden, List<Ticket> tickets)
```

**Características:**
- Diseños diferenciados por color según tipo
- Logo del parque
- Información de la orden
- Lista de tickets con QR
- Footer con instrucciones

### CulqiService
**Ubicación:** `lib/services/culqi_service.dart`

**Métodos:**
```dart
// Flujo de pago en 2 pasos
Future<String> crearToken(CulqiTokenRequest request)
Future<CulqiCargo> crearCargo(CulqiCargoRequest request)

// Método combinado
Future<CulqiCargo> procesarPago({...})

// Verificación
Future<CulqiCargo> verificarCargo(String cargoId)
```

**Configuración necesaria:**
```dart
// Reemplazar con claves reales de Culqi
static const String _publicKey = 'pk_test_TU_PUBLIC_KEY';
static const String _secretKey = 'sk_test_TU_SECRET_KEY';
```

---

## 🎨 ViewModel

### TicketsViewModel
**Ubicación:** `lib/viewmodels/tickets_viewmodel.dart`

**Estado:**
```dart
List<Ticket> tickets
List<OrdenCompra> ordenes
bool isLoading
String? error
```

**Estadísticas (calculadas automáticamente):**
```dart
int ticketsVendidosHoy
int personasEsperadasHoy
int cocherasReservadasHoy
double ingresosHoy

// Desglose por tipo
int ticketsIndividualesHoy
int personasIndividualesHoy
int ticketsGrupalesHoy
int personasGrupalesHoy
int ticketsMultiplesHoy
int personasMultiplesHoy

// Promedios
double promedioPersonasPorTicketGrupal
int ticketMasGrande
double montoPromedio
```

**Métodos:**
```dart
Future<void> cargarEstadisticasDia(DateTime fecha)
Future<void> cargarMisTickets(String userId)
Future<bool> validarTicket(String qrData, String validadorId)
Future<Ticket> validarTicketPorQR(String qrData, String validadorId)
Future<OrdenCompra?> crearOrden({...})
```

**Registrado en:** `lib/app.dart` (MultiProvider)

---

## 📋 Tareas Pendientes

### 1. Integración de Culqi Real
**Archivos a modificar:**
- `lib/services/culqi_service.dart` - Agregar claves de producción
- `lib/views/visitante/resumen_compra_page.dart` - Quitar simulación

**Pasos:**
1. Registrarse en https://culqi.com/
2. Obtener claves API (público y secreto)
3. Reemplazar en `CulqiService`:
```dart
static const String _publicKey = 'pk_live_TU_PUBLIC_KEY';
static const String _secretKey = 'sk_live_TU_SECRET_KEY';
```
4. Probar con tarjetas de prueba primero
5. Implementar webhook para confirmación de pagos

### 2. Servicio de Email
**Crear:** `lib/services/email_service.dart`

**Opciones:**
- **Firebase Cloud Functions** (recomendado):
  - Crear función que se dispare tras compra exitosa
  - Enviar email con PDF adjunto usando SendGrid/Mailgun
  - Ejemplo: `functions/src/sendTicketEmail.ts`

- **SMTP directo** (alternativa):
  - Package: `mailer` (^6.0.0)
  - Configurar SMTP (Gmail, SendGrid, etc.)
  - Enviar desde el cliente (menos seguro)

**Implementación sugerida:**
```dart
Future<void> enviarTicketsPorEmail({
  required String destinatario,
  required OrdenCompra orden,
  required File pdfFile,
}) async {
  // Llamar a Cloud Function o enviar vía SMTP
}
```

### 3. Renderizado Real de QR
**Archivos a modificar:**
- `lib/views/visitante/mis_tickets_page.dart` - Método `_mostrarQR`
- `lib/services/pdf_generator_service.dart` - Generar QR en PDF

**Implementación:**
```dart
// En mis_tickets_page.dart
import 'package:qr_flutter/qr_flutter.dart';

// Reemplazar placeholder con:
QrImageView(
  data: ticket.qrData,
  version: QrVersions.auto,
  size: 250,
  backgroundColor: Colors.white,
)

// En pdf_generator_service.dart
final qrWidget = pw.BarcodeWidget(
  data: ticket.qrData,
  barcode: pw.Barcode.qrCode(),
  width: 100,
  height: 100,
);
```

### 4. Precios Reales
**Archivo a crear:** `lib/config/precios.dart`

```dart
class PreciosConfig {
  // Entrada normal
  static const double entradaAdulto = 15.0;
  static const double entradaNino = 8.0;
  static const double entradaAdultoMayor = 10.0;
  
  // Cochera
  static const double cocheraAuto = 20.0;
  static const double cocheraCamioneta = 25.0;
  static const double cocheraMoto = 10.0;
  
  // Combo (entrada + cochera)
  static double calcularCombo(double entrada, double cochera) {
    return (entrada + cochera) * 0.9; // 10% descuento
  }
}
```

**Modificar:**
- `lib/views/visitante/comprar_entradas_page.dart` - Usar precios reales
- `lib/views/visitante/formulario_compra_page.dart` - Calcular total correcto

### 5. Navegación en el Menú
**Archivo a modificar:** Buscar el drawer/menú principal

**Agregar opciones:**

Para **Visitantes**:
```dart
ListTile(
  leading: Icon(Icons.shopping_cart),
  title: Text('Comprar Entradas'),
  onTap: () => Navigator.push(context, ComprarEntradasPage()),
),
ListTile(
  leading: Icon(Icons.confirmation_number),
  title: Text('Mis Tickets'),
  onTap: () => Navigator.push(context, MisTicketsPage()),
),
```

Para **Admin**:
```dart
ListTile(
  leading: Icon(Icons.bar_chart),
  title: Text('Dashboard Ventas'),
  onTap: () => Navigator.push(context, DashboardVentasPage()),
),
ListTile(
  leading: Icon(Icons.qr_code_scanner),
  title: Text('Validar Tickets'),
  onTap: () => Navigator.push(context, ValidarTicketsPage()),
),
```

### 6. Testing
**Crear tests:**
```
test/
  models/
    ticket_test.dart
    orden_compra_test.dart
  services/
    qr_service_test.dart
    tickets_service_test.dart
  viewmodels/
    tickets_viewmodel_test.dart
```

**Ejecutar:**
```bash
flutter test
```

### 7. Permisos y Configuración

**iOS (si aplica):**
Agregar a `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para escanear códigos QR</string>
```

**Android:** ✅ Ya configurado en `AndroidManifest.xml`

---

## 🚀 Compilar y Ejecutar

### Desarrollo
```bash
flutter pub get
flutter run
```

### Release (Android)
```bash
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

### Release (iOS)
```bash
flutter build ios --release
```

---

## 📱 Flujo de Usuario Completo

### Visitante:
1. **Comprar Entradas**
   - Seleccionar tipo (entrada/cochera/combo)
   - Elegir cantidad y desglose de personas
   - Ver resumen de monto

2. **Formulario**
   - Ingresar datos personales
   - Seleccionar tipo de ticket (grupal vs múltiple)
   - Agregar datos de vehículo si aplica
   - Elegir fecha de visita

3. **Pago**
   - Revisar resumen
   - Aceptar términos
   - Pagar con Culqi
   - Recibir confirmación y PDF

4. **Mis Tickets**
   - Ver todos los tickets
   - Filtrar por estado
   - Mostrar QR para entrada

### Admin/Validador:
1. **Dashboard**
   - Ver estadísticas del día
   - Analizar ventas por tipo
   - Revisar promedios

2. **Validar Tickets**
   - Abrir scanner
   - Apuntar a QR del visitante
   - Ver validación en tiempo real
   - Confirmar ingreso

---

## 🔒 Seguridad

### QR Code
- Hash SHA256 para evitar falsificaciones
- Validación de integridad en cada escaneo
- Secret key configurable

### Pagos
- Integración con Culqi (PCI compliant)
- Tokens de un solo uso
- Verificación de cargos

### Base de Datos
- Reglas de Firestore para acceso controlado
- Validación de permisos por rol (admin/user)

---

## 📚 Dependencias Clave

```yaml
dependencies:
  provider: ^6.0.0          # State management
  cloud_firestore: ^5.4.4   # Base de datos
  pdf: ^3.10.0              # Generación de PDFs
  qr_flutter: ^4.1.0        # Generación de QR
  mobile_scanner: ^3.5.0    # Escaneo de QR
  printing: ^5.11.0         # Impresión/compartir PDF
  http: ^1.1.0              # API calls (Culqi)
  intl: ^0.18.0             # Formatos de fecha/número
```

---

## 💡 Notas Importantes

1. **Fechas de validez**: Los tickets se validan por fecha, no por hora
2. **Tickets grupales**: Un solo QR sirve para todo el grupo
3. **Tickets múltiples**: Se generan QRs individuales por persona
4. **Expiración**: Los tickets expiran automáticamente después de la fecha de visita
5. **Colores consistentes**: Se usan los mismos colores en toda la app (#1976D2, #4CAF50, #FF9800, #9C27B0)

---

## 🐛 Debug

**Ver logs de Firebase:**
```bash
flutter logs
```

**Verificar configuración:**
```bash
flutter doctor -v
```

**Limpiar build:**
```bash
flutter clean
flutter pub get
```

---

## 📞 Contacto y Soporte

Para cualquier duda o mejora, referirse a:
- Documentación de Culqi: https://docs.culqi.com/
- Documentación de mobile_scanner: https://pub.dev/packages/mobile_scanner
- Firebase Firestore: https://firebase.google.com/docs/firestore

---

**Versión:** 1.0.0  
**Última actualización:** 2024  
**Estado:** ✅ Funcionalidades principales implementadas
