import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/auth/routes/auth_routes.dart';
import 'package:little_store_app/src/features/auth/view_models/auth_view_model.dart';
import 'package:little_store_app/src/features/favorites/routes/favorite_routes.dart';
import 'package:little_store_app/src/features/orders/routes/order_routes.dart';
import 'package:little_store_app/src/features/profile/view_models/profile_view_model.dart';
import 'package:little_store_app/src/features/settings/routes/setting_routes.dart';

class ProfileView extends StatefulWidget {
  final ProfileViewModel profileViewModel;
  final AuthViewModel authViewModel;

  const ProfileView({
    super.key,
    required this.profileViewModel,
    required this.authViewModel,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.profileViewModel.loadProfile();
    });
  }

  Future<void> _logout() async {
    await widget.authViewModel.logout();
    if (mounted) {
      context.go(AuthRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.push(SettingRoutes.setting);
            },
          ),
        ],
      ),
      body: StateBuilderWidget<ProfileViewModel, ProfileState>(
        viewModel: widget.profileViewModel,
        builder: (context, state) {
          return switch (state) {
            InitialState() => const Center(child: Text('Carregue seu perfil.')),
            LoadingState() => const Center(child: CircularProgressIndicator()),
            SuccessState(data: final profile) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('E-mail'),
                    subtitle: Text(profile.email),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Cliente desde'),
                    subtitle: Text(profile.memberSince),
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Minhas compras'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push(OrderRoutes.orders);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite_outline),
                    title: const Text('Favoritos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push(FavoriteRoutes.favorites);
                    },
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () {
                        _logout();
                      },
                      child: const Text('Sair'),
                    ),
                  ),
                ],
              ),
            ),
            ErrorState(error: final error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro: ${error.message}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      widget.profileViewModel.loadProfile();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          };
        },
      ),
    );
  }
}
