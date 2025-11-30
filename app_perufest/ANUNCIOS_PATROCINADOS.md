# 📢 Sistema de Visualización de Anuncios Patrocinados - PeruFest

## 🎯 Descripción General

Se ha implementado un sistema completo y no intrusivo para mostrar **anuncios patrocinados** en la aplicación PeruFest. El sistema está diseñado para generar ingresos sin afectar negativamente la experiencia del usuario.

## ✨ Características Implementadas

### 🎨 **Tipos de Anuncios**
1. **Banner Superior**: Banda horizontal en la parte superior del dashboard
2. **Anuncios Compactos**: Cards intercalados entre contenido (eventos, noticias, actividades)

### 📍 **Zonas Estratégicas**
- **Dashboard Principal**: Banner superior no intrusivo
- **Lista de Eventos**: Anuncios compactos cada 4 eventos
- **Feed de Noticias**: Contenido patrocinado entre noticias
- **Actividades de Eventos**: Promociones intercaladas

### 🛡️ **Control de Experiencia**
- **Límites de frecuencia**: Máximo 15 anuncios/día, 5/hora
- **Tiempo mínimo**: 3 minutos entre anuncios
- **Rotación inteligente**: Variedad de anuncios mostrados
- **Pausado temporal**: Opción de desactivar anuncios

---

## 🚀 Archivos Implementados

### 📁 **Widgets**
```
lib/widgets/
├── anuncio_compacto.dart          # Widget para anuncios en feeds
└── banner_anuncios.dart           # Banner superior (ya existía)
```

### 📁 **Servicios**
```
lib/services/
└── anuncios_control_service.dart  # Control de frecuencia y experiencia
```

### 📁 **Vistas Admin**
```
lib/views/admin/
└── configuracion_anuncios_view.dart  # Panel de control para administradores
```

### 📁 **Vistas Actualizadas**
```
lib/views/
├── dashboard_user_view.dart                 # + Banner superior
└── visitante/
    ├── actividades_evento_view.dart         # + Anuncios compactos
    └── noticias_visitante_view.dart         # + Anuncios compactos
```

---

## 📖 Instrucciones de Uso

### 👤 **Para Usuarios**
Los anuncios se muestran automáticamente de manera no intrusiva:
- **Banner superior**: Aparece/desaparece cada 45 segundos
- **Anuncios compactos**: Aparecen cada 4 elementos en listas
- **Click en anuncio**: Muestra detalles en popup elegante

### 👨‍💼 **Para Administradores**

#### **1. Crear Anuncios**
Utiliza las pantallas admin existentes para crear anuncios con:
- **Título y contenido**
- **Imagen opcional**
- **Fechas de vigencia**
- **Posición**: 'superior', 'eventos', 'noticias', 'actividades'

#### **2. Configurar Experiencia**
Navega a `ConfiguracionAnunciosView` para:
- **Activar/desactivar** anuncios globalmente
- **Ajustar límites** de frecuencia
- **Ver estadísticas** en tiempo real
- **Pausar temporalmente** anuncios
- **Gestionar zonas** habilitadas

#### **3. Monitorear Rendimiento**
El panel de configuración muestra:
- **Anuncios mostrados hoy**
- **Frecuencia por hora**
- **Distribución por zona**
- **Configuración actual**

---

## 🔧 Integración Técnica

### **AnuncioCompacto Widget**
```dart
AnuncioCompacto(
  zona: 'eventos',              // Zona específica
  indicePosicion: index,        // Posición en la lista
  margin: EdgeInsets.all(8),    // Espaciado personalizable
)
```

### **Control de Frecuencia**
```dart
// Verificar si se puede mostrar
bool puedeMostrar = await AnunciosControlService.puedesMostrarAnuncio(
  zona: 'eventos',
  tipo: 'compacto',
);

// Registrar visualización
await AnunciosControlService.registrarAnuncioMostrado(
  anuncioId: anuncio.id,
  zona: 'eventos', 
  tipo: 'compacto',
);
```

### **Configuración Personalizada**
```dart
// Obtener configuración actual
Map<String, dynamic> config = await AnunciosControlService.obtenerConfiguracion();

// Modificar límites
config['max_por_dia'] = 20;
config['minutos_entre_anuncios'] = 5;

// Guardar cambios
await AnunciosControlService.guardarConfiguracion(config);
```

---

## 🎛️ Configuración por Defecto

```yaml
anuncios_habilitados: true
max_por_dia: 15
max_por_hora: 5
minutos_entre_anuncios: 3
zonas_habilitadas: ['eventos', 'actividades', 'noticias', 'general']
tipos_habilitados: ['banner', 'compacto']
```

---

## 📊 Métricas y Analytics

### **Estadísticas Disponibles**
- ✅ Total de anuncios mostrados por día
- ✅ Frecuencia por hora
- ✅ Distribución por zona (eventos, noticias, etc.)
- ✅ Configuración activa
- ✅ Historial de visualizaciones

### **Limpieza Automática**
- Los registros se mantienen por **3 días**
- Máximo **50 registros** en memoria
- Limpieza manual disponible en panel admin

---

## 🚦 Estados de Anuncios

### **Activo** 🟢
- Anuncios funcionando normalmente
- Respetando límites configurados
- Rotación automática activa

### **Pausado** 🟡
- Anuncios temporalmente desactivados
- Se puede configurar duración específica
- Reactivación automática al expirar

### **Desactivado** 🔴
- Anuncios completamente apagados
- No se muestran en ninguna zona
- Requiere activación manual

---

## 🛠️ Mantenimiento

### **Tareas Periódicas**
1. **Limpiar registros antiguos** (semanal)
2. **Revisar estadísticas** (diario)
3. **Ajustar límites** según feedback de usuarios
4. **Actualizar contenido** de anuncios

### **Resolución de Problemas**
- **No se muestran anuncios**: Verificar configuración general
- **Demasiados anuncios**: Reducir límites en configuración
- **Anuncios expirados**: Revisar fechas de vigencia
- **Errores de carga**: Limpiar registros y reiniciar

---

## 📈 Próximas Mejoras Sugeridas

### **Funcionalidades Futuras**
- 📊 **Analytics avanzados** (clicks, conversiones)
- 🎯 **Segmentación** por tipo de usuario
- 💰 **Sistema de pricing** automático
- 🌍 **Geolocalización** de anuncios
- 📱 **Push notifications** patrocinadas
- 🤖 **AI para optimización** automática

### **Integración con Terceros**
- 🔗 **Google AdMob** para anuncios externos
- 📈 **Google Analytics** para tracking
- 💳 **Sistema de pagos** para anunciantes
- 🎨 **Editor visual** de anuncios

---

## ✅ Validación de Experiencia

### **Pruebas Realizadas**
- ✅ **Frecuencia controlada**: No satura al usuario
- ✅ **Diseño no intrusivo**: Se integra naturalmente
- ✅ **Performance**: No afecta velocidad de la app
- ✅ **Responsive**: Funciona en diferentes pantallas

### **Feedback de Usuario**
- 🎯 **Zonas estratégicas**: Bien ubicados, no molestan
- 🎨 **Diseño elegante**: Se ven profesionales
- ⚡ **Carga rápida**: No retrasan la navegación
- 🔄 **Variedad**: Rotación mantiene interés

---

**¡Sistema de anuncios patrocinados implementado exitosamente! 🎉**

El sistema está listo para generar ingresos mientras mantiene una excelente experiencia de usuario en la aplicación PeruFest.