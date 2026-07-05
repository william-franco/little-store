# Reference Code

## This is an example of how I use certain patterns in my projects.

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reference Code',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const UserView(),
    );
  }
}

sealed class AppState<S, E extends Exception> {
  const AppState();
}

final class InitialState<S, E extends Exception> extends AppState<S, E> {
  const InitialState();
}

final class LoadingState<S, E extends Exception> extends AppState<S, E> {
  const LoadingState();
}

final class SuccessState<S, E extends Exception> extends AppState<S, E> {
  final S data;

  const SuccessState({required this.data});
}

final class ErrorState<S, E extends Exception> extends AppState<S, E> {
  final E error;

  const ErrorState({required this.error});
}

sealed class Result<S, E extends Exception> {
  const Result();

  T fold<T>({
    required T Function(S value) onSuccess,
    required T Function(E error) onError,
  }) {
    switch (this) {
      case Success(value: final v):
        return onSuccess(v);
      case Error(error: final e):
        return onError(e);
    }
  }
}

final class Success<S, E extends Exception> extends Result<S, E> {
  final S value;

  const Success({required this.value});
}

final class Error<S, E extends Exception> extends Result<S, E> {
  final E error;

  const Error({required this.error});
}

class UserException implements Exception {
  final String message;

  const UserException(this.message);

  @override
  String toString() => 'UserException: $message';
}

class UserModel {
  final String? name;

  UserModel({this.name});
}

typedef UserResult = Result<UserModel, UserException>;

abstract interface class UserRepository {
  Future<UserResult> findOneUser();
}

class UserRepositoryImpl implements UserRepository {
  @override
  Future<UserResult> findOneUser() async {
    try {
      await Future.delayed(Duration(seconds: 4));
      return Success(value: UserModel(name: 'John Doe'));
    } catch (error) {
      return Error(error: UserException('An error occurred.'));
    }
  }
}

typedef UserState = AppState<UserModel, UserException>;

typedef _ViewModel = StateManagement<UserState>;

abstract interface class UserViewModel extends _ViewModel {
  Future<void> getUserData();
}

class UserViewModelImpl extends _ViewModel implements UserViewModel {
  final UserRepository userRepository;

  UserViewModelImpl({required this.userRepository});

  @override
  UserState build() => const InitialState();

  @override
  Future<void> getUserData() async {
    _emit(const LoadingState());

    final result = await userRepository.findOneUser();

    final userState = result.fold<UserState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );

    _emit(userState);
  }

  void _emit(UserState newState) {
    emitState(newState);
    debugPrint('User state: $state');
  }
}

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  late final UserRepository userRepository;
  late final UserViewModel userViewModel;

  @override
  void initState() {
    super.initState();
    userRepository = UserRepositoryImpl();
    userViewModel = UserViewModelImpl(userRepository: userRepository);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getUserData();
    });
  }

  @override
  void dispose() {
    userViewModel.dispose();
    super.dispose();
  }

  Future<void> _getUserData() async {
    await userViewModel.getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              _getUserData();
            },
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: () async {
            await _getUserData();
          },
          child: StateBuilderWidget<UserViewModel, UserState>(
            viewModel: userViewModel,
            builder: (context, userState) {
              return switch (userState) {
                InitialState() => const SizedBox.shrink(),
                LoadingState() => const CircularProgressIndicator(),
                SuccessState(data: final user) => Text('User: ${user.name}'),
                ErrorState(error: final e) => Text('Error: ${e.message}'),
              };
            },
          ),
        ),
      ),
    );
  }
}

abstract class StateManagement<T> extends ChangeNotifier {
  late T _state;

  StateManagement() {
    _state = build();
  }

  @protected
  T build();

  T get state => _state;

  @protected
  void emitState(T newState) {
    if (identical(_state, newState)) return;
    _state = newState;
    notifyListeners();
  }

  @override
  String toString() => 'StateManagement<$T>(state: $_state)';
}

@protected
typedef StateBuilder<S> = Widget Function(BuildContext context, S state);

class StateBuilderWidget<V extends StateManagement<S>, S>
    extends StatelessWidget {
  final V viewModel;
  final StateBuilder<S> builder;
  final Widget? child;

  const StateBuilderWidget({
    super.key,
    required this.viewModel,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      child: child,
      builder: (context, child) {
        return builder(context, viewModel.state);
      },
    );
  }
}

@protected
typedef StateListener<S> = void Function(BuildContext context, S state);

class StateListenerWidget<V extends StateManagement<S>, S>
    extends StatefulWidget {
  final V viewModel;
  final StateListener<S> listener;
  final Widget child;

  const StateListenerWidget({
    super.key,
    required this.viewModel,
    required this.listener,
    required this.child,
  });

  @override
  State<StateListenerWidget<V, S>> createState() =>
      _StateListenerWidgetState<V, S>();
}

class _StateListenerWidgetState<V extends StateManagement<S>, S>
    extends State<StateListenerWidget<V, S>> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(StateListenerWidget<V, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onStateChanged);
      widget.viewModel.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() => widget.listener(context, widget.viewModel.state);

  @override
  Widget build(BuildContext context) => widget.child;
}

class StateConsumerWidget<V extends StateManagement<S>, S>
    extends StatefulWidget {
  final V viewModel;
  final StateListener<S> listener;
  final StateBuilder<S> builder;
  final Widget? child;

  const StateConsumerWidget({
    super.key,
    required this.viewModel,
    required this.listener,
    required this.builder,
    this.child,
  });

  @override
  State<StateConsumerWidget<V, S>> createState() =>
      _StateConsumerWidgetState<V, S>();
}

class _StateConsumerWidgetState<V extends StateManagement<S>, S>
    extends State<StateConsumerWidget<V, S>> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(StateConsumerWidget<V, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onStateChanged);
      widget.viewModel.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() => widget.listener(context, widget.viewModel.state);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      child: widget.child,
      builder: (context, child) {
        return widget.builder(context, widget.viewModel.state);
      },
    );
  }
}
```
