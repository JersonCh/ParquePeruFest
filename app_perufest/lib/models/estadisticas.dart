class EstadisticasGenerales {
  final int totalUsuarios;
  final int usuariosNuevosSemana;
  final int eventosActivos;
  final int totalEventos;
  final int totalActividades;
  final int totalNoticias;
  final int noticiasDelMes;
  final int anunciosActivos;
  final DateTime fechaActualizacion;

  EstadisticasGenerales({
    required this.totalUsuarios,
    required this.usuariosNuevosSemana,
    required this.eventosActivos,
    required this.totalEventos,
    required this.totalActividades,
    required this.totalNoticias,
    required this.noticiasDelMes,
    required this.anunciosActivos,
    required this.fechaActualizacion,
  });
}

class EstadisticasAgenda {
  final int totalUsuariosConAgenda;
  final int totalActividadesEnAgenda;
  final int promedioActividadesPorUsuario;
  final List<ActividadPopular> actividadesPopulares;

  EstadisticasAgenda({
    required this.totalUsuariosConAgenda,
    required this.totalActividadesEnAgenda,
    required this.promedioActividadesPorUsuario,
    required this.actividadesPopulares,
  });
}

class ActividadPopular {
  final String id;
  final String nombre;
  final String zona;
  final int cantidadUsuarios;

  ActividadPopular({
    required this.id,
    required this.nombre,
    required this.zona,
    required this.cantidadUsuarios,
  });
}

class EstadisticasPorFecha {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int noticiasPublicadas;
  final int eventosCreados;
  final int actividadesCreadas;

  EstadisticasPorFecha({
    required this.fechaInicio,
    required this.fechaFin,
    required this.noticiasPublicadas,
    required this.eventosCreados,
    required this.actividadesCreadas,
  });
}

class UsuariosPorMes {
  final String mes;
  final int cantidad;

  UsuariosPorMes({
    required this.mes,
    required this.cantidad,
  });
}