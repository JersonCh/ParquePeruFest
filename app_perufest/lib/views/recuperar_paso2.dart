import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/recuperacion_viewmodel.dart';
import 'recuperar_paso3.dart';

class RecuperarPaso2 extends StatefulWidget {
  final String correo;

  const RecuperarPaso2({super.key, required this.correo});

  @override
  State<RecuperarPaso2> createState() => _RecuperarPaso2State();
}

class _RecuperarPaso2State extends State<RecuperarPaso2> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  void _mostrarModal(String titulo, String mensaje, {bool esExito = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono circular con fondo de color
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: esExito 
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(
                    esExito ? Icons.check_circle_outline : Icons.error_outline,
                    color: esExito 
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                // Título
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Mensaje
                Text(
                  mensaje,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Botón elegante
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 122, 0, 37),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _obtenerCodigo() {
    return _controllers.map((controller) => controller.text).join();
  }

  void _limpiarCodigo() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Fondo guinda oscuro con imagen muy transparente
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 122, 0, 37),
              image: DecorationImage(
                image: AssetImage('assets/images/fondo.jpg'),
                fit: BoxFit.cover,
                opacity: 0.08,
              ),
            ),
          ),

          // Botón de regreso
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),

          // Contenido principal
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Card blanco con formulario
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Título
                          const Text(
                            'Verificar Código',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF231C1A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Descripción
                          Text(
                            'Enviamos un código de 6 dígitos a:\n${widget.correo}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          // Campos de código mejorados
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              return Container(
                                width: 45,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFD1D5DB),
                                    width: 1,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 5) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 30),
                          // Botón verificar código
                          Consumer<RecuperacionViewModel>(
                            builder: (context, viewModel, child) {
                              return Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 122, 0, 37),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: viewModel.estado == EstadoRecuperacion.cargando
                                      ? null
                                      : () async {
                                          final codigo = _obtenerCodigo();
                                          if (codigo.length != 6) {
                                            _mostrarModal(
                                              'Código Incompleto',
                                              'Por favor, ingresa los 6 dígitos del código.',
                                            );
                                            return;
                                          }

                                          final resultado = await viewModel.validarCodigo(
                                            widget.correo,
                                            codigo,
                                          );

                                          if (resultado['valido'] && mounted) {
                                            _mostrarModal(
                                              'Código Válido',
                                              'Código verificado correctamente. Ahora puedes cambiar tu contraseña.',
                                              esExito: true,
                                            );

                                            Future.delayed(const Duration(seconds: 2), () {
                                              if (mounted) {
                                                Navigator.of(context).pop();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => RecuperarPaso3(
                                                      correo: widget.correo,
                                                    ),
                                                  ),
                                                );
                                              }
                                            });
                                          } else {
                                            String mensaje;
                                            switch (resultado['razon']) {
                                              case 'codigo_incorrecto':
                                                mensaje = 'El código ingresado no coincide. Verifica e intenta nuevamente.';
                                                break;
                                              case 'codigo_expirado':
                                                mensaje = 'El código ha expirado. Solicita uno nuevo.';
                                                break;
                                              default:
                                                mensaje = 'Error validando el código. Intenta nuevamente.';
                                            }

                                            _mostrarModal('Error', mensaje);
                                            _limpiarCodigo();
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: viewModel.estado == EstadoRecuperacion.cargando
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        )
                                      : const Text(
                                          'Verificar Código',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          // Enlace reenviar código
                          GestureDetector(
                            onTap: () async {
                              final viewModel = Provider.of<RecuperacionViewModel>(
                                context,
                                listen: false,
                              );
                              final exito = await viewModel.enviarCodigo(widget.correo);

                              if (exito) {
                                _mostrarModal(
                                  'Código Reenviado',
                                  'Se ha enviado un nuevo código a tu correo electrónico.',
                                  esExito: true,
                                );
                                _limpiarCodigo();
                              } else {
                                _mostrarModal(
                                  'Error',
                                  'No se pudo reenviar el código. Intenta más tarde.',
                                );
                              }
                            },
                            child: const Text(
                              'Reenviar código',
                              style: TextStyle(
                                color: Color.fromARGB(255, 122, 0, 37),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationColor: Color.fromARGB(255, 122, 0, 37),
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

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
