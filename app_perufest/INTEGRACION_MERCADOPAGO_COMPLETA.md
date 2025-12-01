# 🚀 Implementación de Pago Real con MercadoPago

## 📋 Estado Actual vs. Implementación Completa

### ✅ Lo que ya está implementado:
- Servicio de MercadoPago (`mercadopago_service.dart`)
- Configuración de credenciales (`mercadopago_config.dart`)
- UI actualizada con branding de MercadoPago
- Información de tarjetas de prueba en el diálogo
- Flujo simulado de pago exitoso

### 🔄 Lo que falta para pago real:
- Formulario de captura de datos de tarjeta
- Tokenización de tarjeta en el frontend
- Llamada real al API de MercadoPago
- Manejo de respuestas de aprobación/rechazo

---

## 🎯 Opción 1: Checkout Pro (Más Simple - Recomendado)

### Ventajas:
- ✅ MercadoPago maneja todo el formulario
- ✅ PCI Compliance automático
- ✅ Implementación rápida
- ✅ Soporte para múltiples métodos de pago

### Implementación:

#### Paso 1: Modificar `_procesarPago()` en `resumen_compra_page.dart`

```dart
Future<void> _procesarPago() async {
  setState(() => _procesando = true);
  
  try {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final mercadoPago = MercadoPagoService();
    
    // Generar ID temporal del ticket
    final ticketId = 'ticket_${DateTime.now().millisecondsSinceEpoch}';
    
    // 1. Crear preferencia de pago
    final preferencia = await mercadoPago.crearPreferencia(
      titulo: 'Entrada ${widget.tipoEntrada.name} - Parque Perú',
      descripcion: '${widget.cantidadPersonas} persona(s) - ${widget.fechaVisita.toString().split(' ')[0]}',
      precio: _total,
      cantidad: 1,
      email: widget.emailComprador,
      metadata: {
        'ticketId': ticketId,
        'userId': authViewModel.currentUser!.id,
        'tipoEntrada': widget.tipoEntrada.name,
        'cantidadPersonas': widget.cantidadPersonas,
        'fechaVisita': widget.fechaVisita.toIso8601String(),
        'nombreComprador': widget.nombreComprador,
        'dniComprador': widget.dniComprador,
      },
    );
    
    // 2. Obtener el link de pago (sandbox para pruebas)
    final checkoutUrl = preferencia['sandbox_init_point'];
    
    // 3. Abrir el checkout de MercadoPago
    // Opción A: En navegador externo
    if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
      await launchUrl(Uri.parse(checkoutUrl));
      
      // Informar al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se abrió el formulario de pago de MercadoPago'),
            backgroundColor: Color(0xFF009EE3),
          ),
        );
      }
    }
    
    // NOTA: El pago se completa en el navegador.
    // Debes implementar un webhook para recibir la notificación
    // cuando el pago se complete.
    
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _procesando = false);
    }
  }
}
```

#### Paso 2: Configurar Webhook (Backend necesario)

Necesitarás un servidor backend (Firebase Cloud Functions, Node.js, etc.) para recibir las notificaciones:

```javascript
// Ejemplo con Firebase Cloud Functions
exports.mercadopagoWebhook = functions.https.onRequest(async (req, res) => {
  const { type, data } = req.body;
  
  if (type === 'payment') {
    const paymentId = data.id;
    
    // Verificar el pago con MercadoPago API
    const payment = await verificarPago(paymentId);
    
    if (payment.status === 'approved') {
      // Obtener metadata
      const metadata = payment.metadata;
      
      // Crear ticket en Firestore
      await crearTicketEnFirestore(metadata);
      
      // Generar y enviar PDF
      await generarYEnviarPDF(metadata);
    }
  }
  
  res.status(200).send('OK');
});
```

---

## 🎯 Opción 2: Formulario Personalizado (Más Control)

### Ventajas:
- ✅ Control total de la UI
- ✅ Experiencia integrada
- ✅ No sale de la app

### Desventajas:
- ⚠️ Más complejo de implementar
- ⚠️ Debes manejar PCI Compliance
- ⚠️ Más código a mantener

### Implementación:

#### Paso 1: Crear Widget de Formulario de Tarjeta

```dart
// lib/widgets/formulario_tarjeta_widget.dart
class FormularioTarjetaWidget extends StatefulWidget {
  final Function(Map<String, String>) onSubmit;
  
  const FormularioTarjetaWidget({required this.onSubmit});
  
  @override
  _FormularioTarjetaWidgetState createState() => _FormularioTarjetaWidgetState();
}

class _FormularioTarjetaWidgetState extends State<FormularioTarjetaWidget> {
  final _formKey = GlobalKey<FormState>();
  final _numeroTarjetaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _vencimientoController = TextEditingController();
  final _cvvController = TextEditingController();
  final _dniController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Campo número de tarjeta
          TextFormField(
            controller: _numeroTarjetaController,
            decoration: InputDecoration(
              labelText: 'Número de tarjeta',
              hintText: '4509 9535 6623 3704',
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              CardNumberInputFormatter(),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el número de tarjeta';
              }
              if (value.replaceAll(' ', '').length < 13) {
                return 'Número de tarjeta inválido';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Campo titular
          TextFormField(
            controller: _nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre del titular',
              hintText: 'APRO',
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el nombre del titular';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Vencimiento
              Expanded(
                child: TextFormField(
                  controller: _vencimientoController,
                  decoration: InputDecoration(
                    labelText: 'Vencimiento',
                    hintText: 'MM/AA',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    CardExpirationFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    if (!value.contains('/') || value.length != 5) {
                      return 'MM/AA';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // CVV
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    if (value.length < 3) {
                      return 'Inválido';
                    }
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
            decoration: InputDecoration(
              labelText: 'DNI',
              hintText: '12345678',
              prefixIcon: Icon(Icons.badge),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese su DNI';
              }
              if (value.length != 8) {
                return 'DNI debe tener 8 dígitos';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final datos = {
                  'numeroTarjeta': _numeroTarjetaController.text.replaceAll(' ', ''),
                  'titular': _nombreController.text,
                  'vencimiento': _vencimientoController.text,
                  'cvv': _cvvController.text,
                  'dni': _dniController.text,
                };
                widget.onSubmit(datos);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF009EE3),
              padding: EdgeInsets.symmetric(vertical: 16),
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text('Pagar S/. ${widget.total.toStringAsFixed(2)}'),
          ),
        ],
      ),
    );
  }
}

// Formateador para número de tarjeta (4 dígitos con espacio)
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Formateador para vencimiento (MM/AA)
class CardExpirationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    
    if (text.length >= 2) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    }
    
    return newValue;
  }
}
```

#### Paso 2: Usar el Formulario en el Diálogo

```dart
Future<bool?> _mostrarDialogoPago() async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.payment, color: Color(0xFF009EE3)),
          SizedBox(width: 8),
          Text('Datos de Tarjeta'),
        ],
      ),
      content: SingleChildScrollView(
        child: FormularioTarjetaWidget(
          total: _total,
          onSubmit: (datos) async {
            Navigator.pop(context); // Cerrar diálogo
            await _procesarPagoConTarjeta(datos);
          },
        ),
      ),
    ),
  );
}

Future<void> _procesarPagoConTarjeta(Map<String, String> datosTarjeta) async {
  setState(() => _procesando = true);
  
  try {
    final mercadoPago = MercadoPagoService();
    
    // 1. Tokenizar la tarjeta
    final vencimiento = datosTarjeta['vencimiento']!.split('/');
    final token = await mercadoPago.crearTokenTarjeta(
      cardNumber: datosTarjeta['numeroTarjeta']!,
      cardholderName: datosTarjeta['titular']!,
      expirationMonth: vencimiento[0],
      expirationYear: '20${vencimiento[1]}',
      securityCode: datosTarjeta['cvv']!,
      identificationType: 'DNI',
      identificationNumber: datosTarjeta['dni']!,
    );
    
    if (token == null) {
      throw Exception('Error al tokenizar la tarjeta');
    }
    
    // 2. Crear el pago
    final ticketId = 'ticket_${DateTime.now().millisecondsSinceEpoch}';
    final pago = await mercadoPago.crearPagoDirecto(
      token: token,
      monto: _total,
      installments: 1,
      email: widget.emailComprador,
      description: 'Entrada Parque Perú - Ticket #$ticketId',
      metadata: {
        'ticketId': ticketId,
        'tipoEntrada': widget.tipoEntrada.name,
        'cantidadPersonas': widget.cantidadPersonas,
      },
    );
    
    // 3. Verificar resultado
    if (mercadoPago.esPagoAprobado(pago)) {
      // PAGO APROBADO ✅
      final transactionId = mercadoPago.obtenerTransactionId(pago)!;
      
      // Crear ticket, generar PDF, etc.
      await _crearTicketYPDF(ticketId, transactionId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Pago exitoso! Ticket #$ticketId'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context); // Volver a la página anterior
      }
    } else if (mercadoPago.esPagoRechazado(pago)) {
      // PAGO RECHAZADO ❌
      final mensaje = mercadoPago.obtenerMensajeError(pago);
      throw Exception(mensaje);
    } else {
      // PAGO PENDIENTE ⏳
      throw Exception('El pago está pendiente de aprobación');
    }
    
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en el pago: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _procesando = false);
    }
  }
}
```

---

## 🔐 Seguridad y Buenas Prácticas

### ❌ NO HACER:
```dart
// NUNCA guardes datos de tarjeta en tu base de datos
await firestore.collection('tarjetas').add({
  'numero': '4509953566233704', // ❌ NUNCA
  'cvv': '123', // ❌ NUNCA
});
```

### ✅ SÍ HACER:
```dart
// Solo guarda el token o ID de transacción
await firestore.collection('tickets').add({
  'transactionId': pago['id'], // ✅ OK
  'metodoPago': 'MercadoPago', // ✅ OK
  'ultimosDigitos': '3704', // ✅ OK (solo últimos 4)
  // NO guardar número completo, CVV, etc.
});
```

---

## 📊 Flujo Completo Recomendado

### Para Producción:

1. **Usuario completa formulario**
   - Datos personales
   - Selecciona fecha, cantidad, etc.

2. **Usuario procede al pago**
   - Opción A: Abre Checkout Pro en navegador
   - Opción B: Formulario personalizado en la app

3. **MercadoPago procesa el pago**
   - Valida la tarjeta
   - Autoriza el cargo

4. **MercadoPago notifica a tu backend (webhook)**
   - Envía confirmación del pago
   - Incluye status y detalles

5. **Tu backend procesa la notificación**
   - Verifica el pago con MercadoPago API
   - Crea el ticket en Firestore
   - Genera el PDF
   - Envía email al usuario

6. **Usuario recibe confirmación**
   - Ticket en la app
   - Email con PDF
   - Notificación push (opcional)

---

## 🧪 Testing

### Tarjetas de Prueba:
- Ya están documentadas en `CONFIGURACION_MERCADOPAGO.md`
- Usa credenciales de TEST
- Prueba escenarios de aprobación y rechazo

### Checklist de Pruebas:
- [ ] Pago aprobado funciona correctamente
- [ ] Pago rechazado muestra mensaje apropiado
- [ ] Se crea el ticket en Firestore
- [ ] Se genera el PDF correctamente
- [ ] El email se envía (si está implementado)
- [ ] Manejo de errores de red
- [ ] Validación de formulario funciona
- [ ] UI responsive en diferentes dispositivos

---

## 📞 Recursos

- [MercadoPago Docs](https://www.mercadopago.com.pe/developers/es/docs)
- [API Reference](https://www.mercadopago.com.pe/developers/es/reference)
- [Sandbox Testing](https://www.mercadopago.com.pe/developers/es/docs/test-cards)
- [Webhooks](https://www.mercadopago.com.pe/developers/es/docs/notifications/webhooks)

---

¿Preguntas o necesitas ayuda? Consulta la documentación oficial de MercadoPago.
