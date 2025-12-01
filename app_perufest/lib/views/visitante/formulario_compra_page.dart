import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket.dart';
import '../../viewmodels/tickets_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'resumen_compra_page.dart';

class FormularioCompraPage extends StatefulWidget {
  final TipoEntrada tipoEntrada;
  final int cantidadPersonas;
  final int cantidadAdultos;
  final int cantidadNinos;
  final int cantidadAdultosMayor;

  const FormularioCompraPage({
    super.key,
    required this.tipoEntrada,
    required this.cantidadPersonas,
    this.cantidadAdultos = 0,
    this.cantidadNinos = 0,
    this.cantidadAdultosMayor = 0,
  });

  @override
  State<FormularioCompraPage> createState() => _FormularioCompraPageState();
}

class _FormularioCompraPageState extends State<FormularioCompraPage> {
  final _formKey = GlobalKey<FormState>();
  
  TipoTicket _tipoTicketSeleccionado = TipoTicket.grupal;
  
  // Datos del comprador
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _placaController = TextEditingController();
  
  TipoVehiculo _tipoVehiculo = TipoVehiculo.automovil;
  DateTime _fechaVisita = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _placaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos de la compra'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de tipo de ticket (solo si son 2+ personas)
              if (widget.cantidadPersonas > 1)
                _buildSelectorTipoTicket(),
              
              if (widget.cantidadPersonas > 1)
                const SizedBox(height: 24),
              
              // Datos del comprador
              _buildDatosComprador(),
              
              const SizedBox(height: 24),
              
              // Datos del vehículo (si aplica)
              if (widget.tipoEntrada == TipoEntrada.cochera ||
                  widget.tipoEntrada == TipoEntrada.combo)
                _buildDatosVehiculo(),
              
              if (widget.tipoEntrada == TipoEntrada.cochera ||
                  widget.tipoEntrada == TipoEntrada.combo)
                const SizedBox(height: 24),
              
              // Fecha de visita
              _buildSelectorFecha(),
              
              const SizedBox(height: 32),
              
              // Botón continuar
              ElevatedButton(
                onPressed: _continuarAResumen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continuar al resumen',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorTipoTicket() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Cómo recibirás tus entradas?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            RadioListTile<TipoTicket>(
              value: TipoTicket.grupal,
              groupValue: _tipoTicketSeleccionado,
              onChanged: (value) {
                setState(() {
                  _tipoTicketSeleccionado = value!;
                });
              },
              title: const Row(
                children: [
                  Icon(Icons.group, color: Color(0xFF1976D2)),
                  SizedBox(width: 8),
                  Text(
                    'Ticket Grupal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              subtitle: const Text(
                '• 1 QR para todo el grupo\n• Todos ingresan juntos\n• ⚡ Más rápido en puerta',
                style: TextStyle(fontSize: 12),
              ),
              activeColor: const Color(0xFF1976D2),
            ),
            
            const Divider(),
            
            RadioListTile<TipoTicket>(
              value: TipoTicket.multiple,
              groupValue: _tipoTicketSeleccionado,
              onChanged: (value) {
                setState(() {
                  _tipoTicketSeleccionado = value!;
                });
              },
              title: const Row(
                children: [
                  Icon(Icons.confirmation_number, color: Color(0xFF1976D2)),
                  SizedBox(width: 8),
                  Text(
                    'Tickets Individuales',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              subtitle: Text(
                '• ${widget.cantidadPersonas} QRs diferentes\n• Cada uno ingresa solo\n• Mayor flexibilidad',
                style: const TextStyle(fontSize: 12),
              ),
              activeColor: const Color(0xFF1976D2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosComprador() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tipoTicketSeleccionado == TipoTicket.grupal
                  ? 'Datos del responsable'
                  : 'Datos del comprador',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese su nombre completo';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _dniController,
              decoration: const InputDecoration(
                labelText: 'DNI',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese su DNI';
                }
                if (value.length != 8) {
                  return 'El DNI debe tener 8 dígitos';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                helperText: 'Recibirás tu comprobante aquí',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese su correo';
                }
                if (!value.contains('@')) {
                  return 'Ingrese un correo válido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosVehiculo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_parking, color: Color(0xFFFF9800)),
                SizedBox(width: 8),
                Text(
                  'Datos del vehículo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _placaController,
              decoration: const InputDecoration(
                labelText: 'Placa del vehículo',
                prefixIcon: Icon(Icons.directions_car),
                border: OutlineInputBorder(),
                hintText: 'ABC-123',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese la placa del vehículo';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            DropdownButtonFormField<TipoVehiculo>(
              value: _tipoVehiculo,
              decoration: const InputDecoration(
                labelText: 'Tipo de vehículo',
                prefixIcon: Icon(Icons.commute),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TipoVehiculo.automovil,
                  child: Text('Automóvil'),
                ),
                DropdownMenuItem(
                  value: TipoVehiculo.camioneta,
                  child: Text('Camioneta'),
                ),
                DropdownMenuItem(
                  value: TipoVehiculo.motocicleta,
                  child: Text('Motocicleta'),
                ),
                DropdownMenuItem(
                  value: TipoVehiculo.otro,
                  child: Text('Otro'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _tipoVehiculo = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorFecha() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _seleccionarFecha,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha de visita',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatearFecha(_fechaVisita),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    final dia = dias[fecha.weekday - 1];
    final mes = meses[fecha.month - 1];
    
    return '$dia, ${fecha.day} de $mes ${fecha.year}';
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaVisita,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _fechaVisita = picked;
      });
    }
  }

  void _continuarAResumen() {
    if (_formKey.currentState!.validate()) {
      // Navegar a resumen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResumenCompraPage(
            tipoEntrada: widget.tipoEntrada,
            tipoTicket: _tipoTicketSeleccionado,
            cantidadPersonas: widget.cantidadPersonas,
            nombreComprador: _nombreController.text,
            dniComprador: _dniController.text,
            emailComprador: _emailController.text,
            telefonoComprador: _telefonoController.text.isEmpty 
                ? null 
                : _telefonoController.text,
            placaVehiculo: _placaController.text.isEmpty 
                ? null 
                : _placaController.text,
            tipoVehiculo: (widget.tipoEntrada == TipoEntrada.cochera ||
                          widget.tipoEntrada == TipoEntrada.combo)
                ? _tipoVehiculo
                : null,
            fechaVisita: _fechaVisita,
          ),
        ),
      );
    }
  }
}
