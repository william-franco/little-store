import 'package:flutter/foundation.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/auth/exceptions/auth_exception.dart';
import 'package:little_store_app/src/features/auth/models/auth_model.dart';
import 'package:little_store_app/src/features/auth/repositories/auth_repository.dart';

typedef AuthState = AppState<AuthModel, AuthException>;

typedef _ViewModel = StateManagement<AuthState>;

abstract interface class AuthViewModel extends _ViewModel {
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> login({
    required String email,
    required String password,
  });

  Future<void> logout();
}

class AuthViewModelImpl extends _ViewModel implements AuthViewModel {
  final AuthRepository authRepository;

  AuthViewModelImpl({required this.authRepository});

  @override
  AuthState build() => InitialState();

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _emit(LoadingState());
    final result = await authRepository.register(
      name: name,
      email: email,
      password: password,
    );
    _emitResult(result);
  }

  @override
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _emit(LoadingState());
    final result = await authRepository.login(
      email: email,
      password: password,
    );
    _emitResult(result);
  }

  @override
  Future<void> logout() async {
    await authRepository.logout();
    _emit(InitialState());
  }

  void _emitResult(AuthResult result) {
    final newState = result.fold<AuthState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );
    _emit(newState);
  }

  void _emit(AuthState newState) {
    emitState(newState);
    debugPrint('AuthViewModel: $state');
  }
}
