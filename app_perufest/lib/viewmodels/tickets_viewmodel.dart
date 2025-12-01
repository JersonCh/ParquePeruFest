import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../models/orden_compra.dart';
import '../services/tickets_service.dart';

class TicketsViewModel extends ChangeNotifier {
  final TicketsService _ticketsService = TicketsService();
  
  bool _isLoading = false;
  String? _error;
  
  List<Ticket> _tickets = [];
  List<OrdenCompra> _ordenes = [];
  
  // Estadísticas del día
  int _ticketsVendidosHoy = 0;
  int _personasEsperadasHoy = 0;
  int _cocherasReservadasHoy = 0;
  double _ingresosHoy = 0.0;
  
  // Desglose por tipo
  int _ticketsIndividualesHoy = 0;
  int _personasIndividualesHoy = 0;
  int _ticketsGrupalesHoy = 0;
  int _personasGrupalesHoy = 0;
  int _ticketsMultiplesHoy = 0;
  int _personasMultiplesHoy = 0;
  
  // Promedios
  double _promedioPersonasPorTicketGrupal = 0.0;
  int _ticketMasGrande = 0;
  double _montoPromedio = 0.0;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Ticket> get tickets => _tickets;
  List<OrdenCompra> get ordenes => _ordenes;
  
  int get ticketsVendidosHoy => _ticketsVendidosHoy;
  int get personasEsperadasHoy => _personasEsperadasHoy;
  int get cocherasReservadasHoy => _cocherasReservadasHoy;
  double get ingresosHoy => _ingresosHoy;
  
  int get ticketsIndividualesHoy => _ticketsIndividualesHoy;
  int get personasIndividualesHoy => _personasIndividualesHoy;
  int get ticketsGrupalesHoy => _ticketsGrupalesHoy;
  int get personasGrupalesHoy => _personasGrupalesHoy;
  int get ticketsMultiplesHoy => _ticketsMultiplesHoy;
  int get personasMultiplesHoy => _personasMultiplesHoy;
  
  double get promedioPersonasPorTicketGrupal => _promedioPersonasPorTicketGrupal;
  int get ticketMasGrande => _ticketMasGrande;
  double get montoPromedio => _montoPromedio;

  /// Cargar estadísticas de un día específico
  Future<void> cargarEstadisticasDia(DateTime fecha) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Cargar tickets del día
      _tickets = await _ticketsService.obtenerTicketsPorFecha(fecha);
      
      // Calcular estadísticas
      _calcularEstadisticas();
      
    } catch (e) {
      _error = 'Error al cargar estadísticas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar todos los tickets de un usuario
  Future<void> cargarMisTickets(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await _ticketsService.obtenerTicketsPorUsuario(userId);
    } catch (e) {
      _error = 'Error al cargar tus tickets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar todos los tickets (para encargado)
  Future<void> cargarTodosLosTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await _ticketsService.obtenerTodosLosTickets();
    } catch (e) {
      _error = 'Error al cargar todos los tickets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Getter para obtener todos los tickets
  List<Ticket> get allTickets => _tickets;

  /// Calcular todas las estadísticas
  void _calcularEstadisticas() {
    // Resetear contadores
    _ticketsVendidosHoy = 0;
    _personasEsperadasHoy = 0;
    _cocherasReservadasHoy = 0;
    _ingresosHoy = 0.0;
    
    _ticketsIndividualesHoy = 0;
    _personasIndividualesHoy = 0;
    _ticketsGrupalesHoy = 0;
    _personasGrupalesHoy = 0;
    _ticketsMultiplesHoy = 0;
    _personasMultiplesHoy = 0;
    
    _ticketMasGrande = 0;
    double sumaMontos = 0.0;
    int totalPersonasGrupales = 0;
    int cantidadTicketsGrupales = 0;

    // Solo contar tickets pagados o usados
    final ticketsValidos = _tickets.where(
      (t) => t.estado == EstadoTicket.pagado || t.estado == EstadoTicket.usado,
    ).toList();

    _ticketsVendidosHoy = ticketsValidos.length;

    for (final ticket in ticketsValidos) {
      // Contar personas
      _personasEsperadasHoy += ticket.cantidadPersonas;
      
      // Contar cocheras
      if (ticket.tipo == TipoEntrada.cochera || ticket.tipo == TipoEntrada.combo) {
        _cocherasReservadasHoy += ticket.cantidadVehiculos ?? 1;
      }
      
      // Sumar ingresos
      _ingresosHoy += ticket.monto;
      sumaMontos += ticket.monto;
      
      // Desglose por tipo de ticket
      switch (ticket.tipoTicket) {
        case TipoTicket.individual:
          _ticketsIndividualesHoy++;
          _personasIndividualesHoy += ticket.cantidadPersonas;
          break;
        case TipoTicket.grupal:
          _ticketsGrupalesHoy++;
          _personasGrupalesHoy += ticket.cantidadPersonas;
          totalPersonasGrupales += ticket.cantidadPersonas;
          cantidadTicketsGrupales++;
          break;
        case TipoTicket.multiple:
          _ticketsMultiplesHoy++;
          _personasMultiplesHoy += ticket.cantidadPersonas;
          break;
      }
      
      // Encontrar ticket más grande
      if (ticket.cantidadPersonas > _ticketMasGrande) {
        _ticketMasGrande = ticket.cantidadPersonas;
      }
    }

    // Calcular promedios
    if (_ticketsVendidosHoy > 0) {
      _montoPromedio = sumaMontos / _ticketsVendidosHoy;
    }
    
    if (cantidadTicketsGrupales > 0) {
      _promedioPersonasPorTicketGrupal = totalPersonasGrupales / cantidadTicketsGrupales;
    }
  }

  /// Validar un ticket (para admin/validador)
  Future<bool> validarTicket(String qrData, String validadorId) async {
    try {
      final resultado = await _ticketsService.validarTicket(qrData, validadorId);
      
      if (resultado) {
        // Recargar tickets si es necesario
        notifyListeners();
      }
      
      return resultado;
    } catch (e) {
      _error = 'Error al validar ticket: $e';
      notifyListeners();
      return false;
    }
  }

  /// Validar ticket por QR y devolver el ticket validado
  Future<Ticket> validarTicketPorQR(String qrData, String validadorId) async {
    try {
      // Primero buscar el ticket
      final ticketEncontrado = _tickets.firstWhere(
        (t) => t.qrData == qrData,
        orElse: () => throw Exception('Ticket no encontrado'),
      );

      // Validar con el servicio
      final validado = await _ticketsService.validarTicket(qrData, validadorId);
      
      if (!validado) {
        throw Exception('No se pudo validar el ticket');
      }
      
      return ticketEncontrado;
    } catch (e) {
      throw Exception('Error al validar ticket: $e');
    }
  }

  /// Crear una nueva orden y tickets
  Future<OrdenCompra?> crearOrden({
    required String userId,
    required String transactionId,
    required double montoTotal,
    required DateTime fechaVisita,
    required int cantidadEntradas,
    required int cantidadCocheras,
    required int totalPersonas,
    required String nombreComprador,
    required String dniComprador,
    required String emailComprador,
    String? telefonoComprador,
    List<Ticket>? ticketsACrear,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orden = await _ticketsService.crearOrdenCompleta(
        userId: userId,
        transactionId: transactionId,
        montoTotal: montoTotal,
        fechaVisita: fechaVisita,
        cantidadEntradas: cantidadEntradas,
        cantidadCocheras: cantidadCocheras,
        totalPersonas: totalPersonas,
        nombreComprador: nombreComprador,
        dniComprador: dniComprador,
        emailComprador: emailComprador,
        telefonoComprador: telefonoComprador,
        tickets: ticketsACrear ?? [],
      );
      
      return orden;
    } catch (e) {
      _error = 'Error al crear orden: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
