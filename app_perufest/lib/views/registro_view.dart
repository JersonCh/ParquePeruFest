import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/validador_service.dart';
import 'login_view.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _usernameController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      await authViewModel.registrar(
        nombre: _nombreController.text.trim(),
        username: _usernameController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        rol: 'usuario',
        contrasena: _contrasenaController.text,
      );

      if (mounted && authViewModel.state == AuthState.success) {
        // Mostrar mensaje de éxito y redirigir al login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            // Título "Regístrate"
                            const Text(
                              'Regístrate',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF231C1A), // texto oscuro
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Texto de login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '¿Ya tienes cuenta? ',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280), // gris para modo día
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Iniciar Sesión',
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

                            // Campo nombre
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
                                controller: _nombreController,
                                decoration: const InputDecoration(
                                  hintText: 'Nombre completo',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF), // gris claro
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
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
                                validator: ValidadorService.validarNombre,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Campo username
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
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  hintText: 'Nombre de usuario',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF), // gris claro
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.account_circle_outlined,
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
                                validator: ValidadorService.validarUsername,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Campo correo
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
                            const SizedBox(height: 12),
                            // Campo teléfono
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
                                controller: _telefonoController,
                                decoration: const InputDecoration(
                                  hintText: 'Teléfono',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF), // gris claro
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
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
                                keyboardType: TextInputType.phone,
                                validator: ValidadorService.validarTelefono,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Campo contraseña
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
                            const SizedBox(height: 12),
                            // Campo confirmar contraseña
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
                                controller: _confirmarContrasenaController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  hintText: 'Confirmar contraseña',
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
                                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFF6B7280), // gris medio
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                                validator: (value) => ValidadorService.validarConfirmarContrasena(
                                  value,
                                  _contrasenaController.text,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Botón de registro
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
                                    // Botón REGISTRO
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
                                        onPressed: authViewModel.isLoading ? null : _registrar,
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
                                                'Registrarse',
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