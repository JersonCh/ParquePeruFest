import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import 'formulario_compra_page.dart';
import '../../config/precios_config.dart';

class ComprarEntradasPage extends StatefulWidget {
  const ComprarEntradasPage({super.key});

  @override
  State<ComprarEntradasPage> createState() => _ComprarEntradasPageState();
}

class _ComprarEntradasPageState extends State<ComprarEntradasPage> {
  TipoEntrada? _tipoSeleccionado;
  int _cantidadPersonas = 1;
  int _cantidadAdultos = 1;
  int _cantidadNinos = 0;
  int _cantidadAdultosMayor = 0;
  
  bool _mostrarDetalle = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprar Entradas'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            const Text(
              '¿Qué deseas adquirir?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Selecciona el tipo de entrada y la cantidad de personas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Opción Entrada
            _buildOpcionTicket(
              tipo: TipoEntrada.entrada,
              titulo: 'Entrada al Parque',
              precio: PreciosConfig.entradaAdulto, // Precio real
              icono: Icons.confirmation_number,
              color: const Color(0xFF4CAF50),
              descripcion: 'Acceso completo al parque',
            ),
            
            const SizedBox(height: 16),
            
            // Opción Cochera
            _buildOpcionTicket(
              tipo: TipoEntrada.cochera,
              titulo: 'Cochera',
              precio: PreciosConfig.cocheraAuto, // Precio real
              icono: Icons.local_parking,
              color: const Color(0xFFFF9800),
              descripcion: 'Estacionamiento seguro',
            ),
            
            const SizedBox(height: 16),
            
            // Opción Combo
            _buildOpcionTicket(
              tipo: TipoEntrada.combo,
              titulo: 'Combo (Entrada + Cochera)',
              precio: PreciosConfig.calcularPrecioCombo(
                precioEntrada: PreciosConfig.entradaAdulto,
                precioCochera: PreciosConfig.cocheraAuto,
              ), // Precio real con descuento
              icono: Icons.card_giftcard,
              color: const Color(0xFF9C27B0),
              descripcion: 'Paquete completo - Ahorra tiempo',
              destacado: true,
            ),
            
            const SizedBox(height: 24),
            
            // Selector de cantidad (solo si es entrada o combo)
            if (_tipoSeleccionado == TipoEntrada.entrada || 
                _tipoSeleccionado == TipoEntrada.combo)
              _buildSelectorCantidad(),
            
            const SizedBox(height: 24),
            
            // Resumen
            if (_tipoSeleccionado != null)
              _buildResumen(),
            
            const SizedBox(height: 24),
            
            // Botón continuar
            ElevatedButton(
              onPressed: _tipoSeleccionado != null ? _continuarCompra : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionTicket({
    required TipoEntrada tipo,
    required String titulo,
    required double precio,
    required IconData icono,
    required Color color,
    required String descripcion,
    bool destacado = false,
  }) {
    final seleccionado = _tipoSeleccionado == tipo;
    
    return GestureDetector(
      onTap: () => setState(() => _tipoSeleccionado = tipo),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: seleccionado ? color : Colors.grey.shade300,
            width: seleccionado ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio button
            Icon(
              seleccionado ? Icons.radio_button_checked : Icons.radio_button_off,
              color: seleccionado ? color : Colors.grey,
              size: 24,
            ),
            
            const SizedBox(width: 12),
            
            // Icono
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: color, size: 32),
            ),
            
            const SizedBox(width: 12),
            
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: seleccionado ? color : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Precio
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'S/. ${precio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (destacado)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '¡Popular!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorCantidad() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Color(0xFF1976D2)),
                const SizedBox(width: 8),
                const Text(
                  '¿Cuántas personas?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Selector simple
            Row(
              children: [
                const Text(
                  'Cantidad:',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _cantidadPersonas > 1
                      ? () {
                          setState(() {
                            _cantidadPersonas--;
                            _ajustarDetalle();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFF1976D2),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_cantidadPersonas',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _cantidadPersonas < 20
                      ? () {
                          setState(() {
                            _cantidadPersonas++;
                            _ajustarDetalle();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF1976D2),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Opción de detalle
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _mostrarDetalle = !_mostrarDetalle;
                });
              },
              icon: Icon(
                _mostrarDetalle ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(
                _mostrarDetalle ? 'Ocultar detalle' : 'Especificar edades',
              ),
            ),
            
            if (_mostrarDetalle) ...[
              const Divider(),
              const SizedBox(height: 8),
              
              _buildContadorEdad('Adultos', _cantidadAdultos, (val) {
                setState(() {
                  _cantidadAdultos = val;
                  _actualizarTotal();
                });
              }),
              
              const SizedBox(height: 12),
              
              _buildContadorEdad('Niños', _cantidadNinos, (val) {
                setState(() {
                  _cantidadNinos = val;
                  _actualizarTotal();
                });
              }),
              
              const SizedBox(height: 12),
              
              _buildContadorEdad('Adultos mayores', _cantidadAdultosMayor, (val) {
                setState(() {
                  _cantidadAdultosMayor = val;
                  _actualizarTotal();
                });
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContadorEdad(String label, int valor, Function(int) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        IconButton(
          onPressed: valor > 0
              ? () => onChanged(valor - 1)
              : null,
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          color: const Color(0xFF1976D2),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$valor',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => onChanged(valor + 1),
          icon: const Icon(Icons.add_circle_outline, size: 20),
          color: const Color(0xFF1976D2),
        ),
      ],
    );
  }

  Widget _buildResumen() {
    // Calcular precio usando la configuración
    double precioUnitario;
    int cantidad;
    
    if (_tipoSeleccionado == TipoEntrada.entrada) {
      precioUnitario = PreciosConfig.calcularPrecioEntrada(
        adultos: _cantidadAdultos,
        ninos: _cantidadNinos,
        adultosMayor: _cantidadAdultosMayor,
      ) / _cantidadPersonas; // Precio promedio por persona
      cantidad = _cantidadPersonas;
    } else if (_tipoSeleccionado == TipoEntrada.cochera) {
      precioUnitario = PreciosConfig.cocheraAuto;
      cantidad = 1;
    } else {
      // Combo
      final precioEntrada = PreciosConfig.calcularPrecioEntrada(
        adultos: _cantidadAdultos,
        ninos: _cantidadNinos,
        adultosMayor: _cantidadAdultosMayor,
      );
      final precioCochera = PreciosConfig.cocheraAuto;
      precioUnitario = PreciosConfig.calcularPrecioCombo(
        precioEntrada: precioEntrada,
        precioCochera: precioCochera,
      );
      cantidad = 1;
    }
    
    double total = precioUnitario * cantidad;
    
    return Card(
      elevation: 2,
      color: const Color(0xFF1976D2).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RESUMEN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const Divider(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTipoTexto(),
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  '$cantidad',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Precio unitario:',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  'S/. ${precioUnitario.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const Divider(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'S/. ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTipoTexto() {
    switch (_tipoSeleccionado!) {
      case TipoEntrada.entrada:
        return _cantidadPersonas == 1 ? 'Entrada' : 'Entradas';
      case TipoEntrada.cochera:
        return 'Cochera';
      case TipoEntrada.combo:
        return _cantidadPersonas == 1 ? 'Combo' : 'Combos';
    }
  }

  void _ajustarDetalle() {
    if (!_mostrarDetalle) return;
    
    // Mantener la suma de edades igual a la cantidad total
    final total = _cantidadAdultos + _cantidadNinos + _cantidadAdultosMayor;
    if (total != _cantidadPersonas) {
      _cantidadAdultos = _cantidadPersonas;
      _cantidadNinos = 0;
      _cantidadAdultosMayor = 0;
    }
  }

  void _actualizarTotal() {
    _cantidadPersonas = _cantidadAdultos + _cantidadNinos + _cantidadAdultosMayor;
    if (_cantidadPersonas < 1) {
      _cantidadPersonas = 1;
      _cantidadAdultos = 1;
    }
  }

  void _continuarCompra() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioCompraPage(
          tipoEntrada: _tipoSeleccionado!,
          cantidadPersonas: (_tipoSeleccionado == TipoEntrada.cochera) ? 1 : _cantidadPersonas,
          cantidadAdultos: _cantidadAdultos,
          cantidadNinos: _cantidadNinos,
          cantidadAdultosMayor: _cantidadAdultosMayor,
        ),
      ),
    );
  }
}
