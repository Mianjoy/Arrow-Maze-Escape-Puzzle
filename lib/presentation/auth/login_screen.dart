import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../widgets/app_nav_actions.dart';
import 'auth_error_message.dart';
import 'login_controller.dart';

/// Pantalla de inicio de sesión: formulario username/password contra el backend.
class LoginScreen extends StatefulWidget {
  /// Crea la pantalla con su [controller].
  const LoginScreen({super.key, required this.controller});

  /// Controlador que ejecuta el login.
  final LoginController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida el formulario y delega el login al controlador.
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
      appBar: AppBar(
        title: const Text('Arrow Maze — Login'),
        actions: const [AppNavActions()],
      ),
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
                    key: const ValueKey('login-username'),
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) =>
                        (value == null || value.trim().length < 3) ? 'Min 3 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('login-password'),
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                  if (widget.controller.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      authErrorMessage(AppStringsScope.of(context), widget.controller.error),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('login-submit'),
                    onPressed: widget.controller.isLoading ? null : _onSubmit,
                    child: widget.controller.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/register'),
                    child: const Text('Create account'),
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
