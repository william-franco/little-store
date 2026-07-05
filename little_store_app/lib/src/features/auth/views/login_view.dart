import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/auth/exceptions/auth_exception.dart';
import 'package:little_store_app/src/features/auth/models/auth_model.dart';
import 'package:little_store_app/src/features/auth/routes/auth_routes.dart';
import 'package:little_store_app/src/features/auth/view_models/auth_view_model.dart';
import 'package:little_store_app/src/features/products/routes/product_routes.dart';

class LoginView extends StatefulWidget {
  final AuthViewModel authViewModel;

  const LoginView({super.key, required this.authViewModel});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.authViewModel.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: StateConsumerWidget<AuthViewModel, AuthState>(
        viewModel: widget.authViewModel,
        listener: (context, state) {
          if (state is SuccessState) {
            context.go(ProductRoutes.products);
          }
        },
        builder: (context, state) {
          final isLoading = state is LoadingState;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront, size: 64),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o e-mail';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a senha';
                      }
                      return null;
                    },
                  ),
                  if (state is ErrorState<AuthModel, AuthException>) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error.message,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              _login();
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            context.push(AuthRoutes.register);
                          },
                    child: const Text('Criar conta'),
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
