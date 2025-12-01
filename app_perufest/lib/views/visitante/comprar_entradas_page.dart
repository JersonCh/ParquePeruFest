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
      backgroundColor: const Color(0xFFF7F7FF),
      body: CustomScrollView(
        slivers: [
          // AppBar con estilo personalizado
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color.fromARGB(255, 122, 0, 37),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 122, 0, 37),
                      Color(0xFF8B1538),
                      Color(0xFFB91C3C),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(
                        Icons.shopping_cart,
                        size: 150,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.confirmation_number_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Comprar Entradas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Adquiere tu acceso al evento',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Contenido principal
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Contenedor con bordes redondeados
                  Container(
                    margin: const EdgeInsets.only(top: 0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Título elegante
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_rounded,
                                  color: Color.fromARGB(255, 122, 0, 37),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¿Qué deseas adquirir?',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Selecciona el tipo de entrada y cantidad',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF666666),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
            
                          const SizedBox(height: 24),
            
                          // Opción Entrada
                          _buildOpcionTicket(
                            tipo: TipoEntrada.entrada,
                            titulo: 'Entrada al Parque',
                            precio: PreciosConfig.entradaAdulto,
                            icono: Icons.confirmation_number_rounded,
                            color: const Color.fromARGB(255, 122, 0, 37),
                            descripcion: 'Acceso completo al parque y actividades',
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Opción Cochera
                          _buildOpcionTicket(
                            tipo: TipoEntrada.cochera,
                            titulo: 'Cochera',
                            precio: PreciosConfig.cocheraAuto,
                            icono: Icons.local_parking_rounded,
                            color: const Color(0xFF0891B2),
                            descripcion: 'Estacionamiento seguro para tu vehículo',
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Opción Combo
                          _buildOpcionTicket(
                            tipo: TipoEntrada.combo,
                            titulo: 'Combo (Entrada + Cochera)',
                            precio: PreciosConfig.calcularPrecioCombo(
                              precioEntrada: PreciosConfig.entradaAdulto,
                              precioCochera: PreciosConfig.cocheraAuto,
                            ),
                            icono: Icons.card_giftcard_rounded,
                            color: const Color(0xFF059669),
                            descripcion: 'Paquete completo - ¡Ahorra más!',
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
            
                          // Botón continuar elegante
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: _tipoSeleccionado != null
                                  ? const LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 122, 0, 37),
                                        Color(0xFF8B1538),
                                      ],
                                    )
                                  : null,
                              color: _tipoSeleccionado == null ? Colors.grey.shade300 : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _tipoSeleccionado != null
                                  ? [
                                      BoxShadow(
                                        color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ElevatedButton(
                              onPressed: _tipoSeleccionado != null ? _continuarCompra : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: _tipoSeleccionado != null ? Colors.white : Colors.grey.shade500,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Continuar con la compra',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _tipoSeleccionado != null ? Colors.white : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: seleccionado ? color : Colors.grey.shade200,
            width: seleccionado ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: seleccionado 
                  ? color.withOpacity(0.2) 
                  : Colors.black.withOpacity(0.05),
              blurRadius: seleccionado ? 12 : 6,
              offset: Offset(0, seleccionado ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Radio button más elegante
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: seleccionado ? color : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: seleccionado ? color : Colors.transparent,
                  ),
                  child: seleccionado
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
                
                const SizedBox(width: 16),
                
                // Icono con mejor diseño
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: seleccionado 
                          ? [color.withOpacity(0.2), color.withOpacity(0.1)]
                          : [Colors.grey.shade100, Colors.grey.shade50],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icono,
                    color: seleccionado ? color : Colors.grey.shade600,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: seleccionado ? color : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Precio y badges en la parte inferior
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (destacado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '¡Popular!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
                
                // Precio
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'S/. ${precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'por ${tipo == TipoEntrada.cochera ? 'vehículo' : tipo == TipoEntrada.combo ? 'combo' : 'persona'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorCantidad() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Color.fromARGB(255, 122, 0, 37),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '¿Cuántas personas?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
            
            const SizedBox(height: 16),
            
            // Selector elegante
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cantidad de personas:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _cantidadPersonas > 1
                              ? () {
                                  setState(() {
                                    _cantidadPersonas--;
                                    _ajustarDetalle();
                                  });
                                }
                              : null,
                          icon: Icon(
                            Icons.remove_rounded,
                            color: _cantidadPersonas > 1 
                                ? const Color.fromARGB(255, 122, 0, 37) 
                                : Colors.grey.shade400,
                          ),
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '$_cantidadPersonas',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
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
                          icon: Icon(
                            Icons.add_rounded,
                            color: _cantidadPersonas < 20 
                                ? const Color.fromARGB(255, 122, 0, 37) 
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Opción de detalle
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _mostrarDetalle = !_mostrarDetalle;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 122, 0, 37),
              ),
              icon: Icon(
                _mostrarDetalle ? Icons.expand_less : Icons.expand_more,
                color: const Color.fromARGB(255, 122, 0, 37),
              ),
              label: Text(
                _mostrarDetalle ? 'Ocultar detalle' : 'Especificar edades',
                style: const TextStyle(
                  color: Color.fromARGB(255, 122, 0, 37),
                  fontWeight: FontWeight.w600,
                ),
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
          color: const Color.fromARGB(255, 122, 0, 37),
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
          color: const Color.fromARGB(255, 122, 0, 37),
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
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 122, 0, 37),
            Color(0xFF8B1538),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'RESUMEN DE COMPRA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTipoTexto(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$cantidad ${cantidad == 1 ? 'unidad' : 'unidades'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Precio unitario:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'S/. ${precioUnitario.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL A PAGAR:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'S/. ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Soles peruanos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
