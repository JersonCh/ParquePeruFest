import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/validador_service.dart';
import 'registro_view.dart';
import 'dashboard_user_view.dart';
import 'dashboard_admin_view.dart';
import 'dashboard_expositor_view.dart';
import 'recuperar_paso1.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      await authViewModel.login(
        _correoController.text.trim(),
        _contrasenaController.text,
      );

      if (mounted && authViewModel.state == AuthState.success) {
        final rol = authViewModel.currentUser?.rol ?? 'usuario';
        Widget destino;
        if (rol == 'administrador') {
          destino = const DashboardAdminView();
        } else if (rol == 'expositor') {
          destino = const DashboardExpositorView();
        } else if (rol == 'usuario') {
          destino = const DashboardUserView();
        } else {
          destino = const DashboardUserView();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destino),
        );
      }
    }
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
              color: Color.fromARGB(255, 122, 0, 37), // fondo guinda más oscuro y fuerte
              image: DecorationImage(
                image: AssetImage('assets/images/fondo.jpg'),
                fit: BoxFit.cover,
                opacity: 0.08, // aún más transparente para que predomine el guinda
              ),
            ),
          ),


          // Contenido principal
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                      // Logo de la aplicación - tamaño original
                      Image.asset(
                                'assets/images/logo.png',
                                width: 350,
                                height: 300,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.festival,
                                    size: 160,
                                    color: Colors.white,
                                  );
                        },
                      ),
                      const SizedBox(height: 5),
                      // Card blanco con formulario
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        decoration: BoxDecoration(
                          color: Colors.white, // fondo blanco para modo día
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
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Título "Iniciar Sesión" para modo día
                            const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF231C1A), // texto oscuro
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Texto de registro como la referencia
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '¿No tienes cuenta? ',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280), // gris para modo día
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RegistroView(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Regístrate',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 122, 0, 37), // guinda
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color.fromARGB(255, 122, 0, 37),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            // Campo de correo para modo día
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB), // fondo claro
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD1D5DB), // borde gris claro
                                  width: 1,
                                ),
                              ),
                              child: TextFormField(
                                controller: _correoController,
                                decoration: const InputDecoration(
                                  hintText: 'Correo electrónico',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF), // gris claro
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF6B7280), // gris medio
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: ValidadorService.validarCorreo,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Campo de contraseña para modo día
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB), // fondo claro
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD1D5DB), // borde gris claro
                                  width: 1,
                                ),
                              ),
                              child: TextFormField(
                                controller: _contrasenaController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Contraseña',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9CA3AF), // gris claro
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF6B7280), // gris medio
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFF6B7280), // gris medio
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87,
                                ),
                                validator: ValidadorService.validarContrasena,
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Botón de login
                            Consumer<AuthViewModel>(
                              builder: (context, authViewModel, child) {
                                return Column(
                                  children: [
                                    // Mostrar error
                                    if (authViewModel.state == AuthState.error)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade300),
                                        ),
                                        child: Text(
                                          authViewModel.errorMessage,
                                          style: TextStyle(color: Colors.red.shade700),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    // Botón LOGIN como la referencia
                                    Container(
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 122, 0, 37), // guinda
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
                                        onPressed: authViewModel.isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: authViewModel.isLoading
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              )
                                            : const Text(
                                                'Iniciar Sesión',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            // Enlace "¿Olvidaste tu contraseña?" como la referencia
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RecuperarPaso1(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280), // gris para modo día
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}