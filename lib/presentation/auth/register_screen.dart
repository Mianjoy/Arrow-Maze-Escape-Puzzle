import 'package:flutter/material.dart';

import 'register_controller.dart';

/// Pantalla de registro de usuario nuevo en el backend.
class RegisterScreen extends StatefulWidget {
  /// Crea la pantalla con su [controller].
  const RegisterScreen({super.key, required this.controller});

  /// Controlador que ejecuta el registro.
  final RegisterController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida el formulario y delega el registro al controlador.
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.controller.submit(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/levels');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arrow Maze — Register')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey('register-username'),
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) =>
                        (value == null || value.trim().length < 3) ? 'Min 3 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('register-password'),
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password (min 8)'),
                    obscureText: true,
                    validator: (value) =>
                        (value == null || value.length < 8) ? 'Min 8 characters' : null,
                  ),
                  if (widget.controller.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.controller.error.toString(),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('register-submit'),
                    onPressed: widget.controller.isLoading ? null : _onSubmit,
                    child: widget.controller.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create account'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
