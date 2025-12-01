/// Configuración de precios del sistema de tickets
/// 
/// Todos los precios están en soles peruanos (PEN)
class PreciosConfig {
  // ===== ENTRADAS NORMALES =====
  
  /// Precio entrada adulto
  static const double entradaAdulto = 10.0;
  
  /// Precio entrada niño (menores de 12 años)
  static const double entradaNino = 10.0;
  
  /// Precio entrada adulto mayor (60+ años)
  static const double entradaAdultoMayor = 10.0;

  // ===== COCHERAS =====
  
  /// Precio cochera para auto
  static const double cocheraAuto = 10.0;
  
  /// Precio cochera para camioneta
  static const double cocheraCamioneta = 10.0;
  
  /// Precio cochera para moto
  static const double cocheraMoto = 10.0;

  // ===== DESCUENTOS =====
  
  /// Descuento para combo (entrada + cochera)
  /// Valor entre 0.0 y 1.0 (0.1 = 10% de descuento)
  static const double descuentoCombo = 0.10;
  
  /// Descuento para grupos grandes (5+ personas)
  static const double descuentoGrupoGrande = 0.05;
  
  /// Cantidad mínima de personas para descuento de grupo
  static const int minimoPersonasDescuento = 5;

  // ===== MÉTODOS DE CÁLCULO =====
  
  /// Calcular precio de entrada según tipo de persona
  static double calcularPrecioEntrada({
    int adultos = 0,
    int ninos = 0,
    int adultosMayor = 0,
  }) {
    return (adultos * entradaAdulto) +
           (ninos * entradaNino) +
           (adultosMayor * entradaAdultoMayor);
  }
  
  /// Calcular precio de cochera según tipo de vehículo
  static double calcularPrecioCochera({
    required String tipoVehiculo,
    int cantidad = 1,
  }) {
    double precioPorVehiculo;
    
    switch (tipoVehiculo.toLowerCase()) {
      case 'auto':
        precioPorVehiculo = cocheraAuto;
        break;
      case 'camioneta':
        precioPorVehiculo = cocheraCamioneta;
        break;
      case 'moto':
        precioPorVehiculo = cocheraMoto;
        break;
      default:
        precioPorVehiculo = cocheraAuto;
    }
    
    return precioPorVehiculo * cantidad;
  }
  
  /// Calcular precio de combo (entrada + cochera) con descuento
  static double calcularPrecioCombo({
    required double precioEntrada,
    required double precioCochera,
  }) {
    final total = precioEntrada + precioCochera;
    return total * (1 - descuentoCombo);
  }
  
  /// Aplicar descuento por grupo grande si aplica
  static double aplicarDescuentoGrupo({
    required double precioBase,
    required int cantidadPersonas,
  }) {
    if (cantidadPersonas >= minimoPersonasDescuento) {
      return precioBase * (1 - descuentoGrupoGrande);
    }
    return precioBase;
  }
  
  /// Calcular precio total de una compra
  static PrecioCalculado calcularPrecioTotal({
    required String tipoEntrada, // 'entrada', 'cochera', 'combo'
    int adultos = 0,
    int ninos = 0,
    int adultosMayor = 0,
    String? tipoVehiculo,
    int cantidadVehiculos = 0,
  }) {
    final totalPersonas = adultos + ninos + adultosMayor;
    double precioEntrada = 0;
    double precioCochera = 0;
    double descuentoAplicado = 0;
    double subtotal = 0;
    
    switch (tipoEntrada.toLowerCase()) {
      case 'entrada':
        precioEntrada = calcularPrecioEntrada(
          adultos: adultos,
          ninos: ninos,
          adultosMayor: adultosMayor,
        );
        subtotal = precioEntrada;
        
        // Aplicar descuento por grupo grande
        final precioConDescuento = aplicarDescuentoGrupo(
          precioBase: subtotal,
          cantidadPersonas: totalPersonas,
        );
        descuentoAplicado = subtotal - precioConDescuento;
        subtotal = precioConDescuento;
        break;
        
      case 'cochera':
        if (tipoVehiculo != null) {
          precioCochera = calcularPrecioCochera(
            tipoVehiculo: tipoVehiculo,
            cantidad: cantidadVehiculos,
          );
        }
        subtotal = precioCochera;
        break;
        
      case 'combo':
        precioEntrada = calcularPrecioEntrada(
          adultos: adultos,
          ninos: ninos,
          adultosMayor: adultosMayor,
        );
        
        if (tipoVehiculo != null) {
          precioCochera = calcularPrecioCochera(
            tipoVehiculo: tipoVehiculo,
            cantidad: cantidadVehiculos,
          );
        }
        
        final precioSinDescuento = precioEntrada + precioCochera;
        subtotal = calcularPrecioCombo(
          precioEntrada: precioEntrada,
          precioCochera: precioCochera,
        );
        descuentoAplicado = precioSinDescuento - subtotal;
        
        // Aplicar descuento adicional por grupo grande
        final precioConDescuentoGrupo = aplicarDescuentoGrupo(
          precioBase: subtotal,
          cantidadPersonas: totalPersonas,
        );
        
        if (precioConDescuentoGrupo < subtotal) {
          descuentoAplicado += subtotal - precioConDescuentoGrupo;
          subtotal = precioConDescuentoGrupo;
        }
        break;
    }
    
    return PrecioCalculado(
      precioEntrada: precioEntrada,
      precioCochera: precioCochera,
      descuentoAplicado: descuentoAplicado,
      subtotal: subtotal,
      total: subtotal, // Aquí se pueden agregar impuestos si es necesario
    );
  }
}

/// Clase para retornar el resultado del cálculo de precios
class PrecioCalculado {
  final double precioEntrada;
  final double precioCochera;
  final double descuentoAplicado;
  final double subtotal;
  final double total;
  
  const PrecioCalculado({
    required this.precioEntrada,
    required this.precioCochera,
    required this.descuentoAplicado,
    required this.subtotal,
    required this.total,
  });
  
  /// Porcentaje de descuento aplicado
  double get porcentajeDescuento {
    final precioSinDescuento = precioEntrada + precioCochera;
    if (precioSinDescuento == 0) return 0;
    return (descuentoAplicado / precioSinDescuento) * 100;
  }
  
  /// Si se aplicó algún descuento
  bool get tieneDescuento => descuentoAplicado > 0;
  
  @override
  String toString() {
    return 'PrecioCalculado(entrada: S/. ${precioEntrada.toStringAsFixed(2)}, '
           'cochera: S/. ${precioCochera.toStringAsFixed(2)}, '
           'descuento: S/. ${descuentoAplicado.toStringAsFixed(2)}, '
           'total: S/. ${total.toStringAsFixed(2)})';
  }
}
