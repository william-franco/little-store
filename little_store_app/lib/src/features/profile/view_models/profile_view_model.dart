import 'package:flutter/foundation.dart';
import 'package:little_store_app/src/common/patterns/app_state_pattern.dart';
import 'package:little_store_app/src/common/state_management/state_management.dart';
import 'package:little_store_app/src/features/profile/exceptions/profile_exception.dart';
import 'package:little_store_app/src/features/profile/models/profile_model.dart';
import 'package:little_store_app/src/features/profile/repositories/profile_repository.dart';

typedef ProfileState = AppState<ProfileModel, ProfileException>;

typedef _ViewModel = StateManagement<ProfileState>;

abstract interface class ProfileViewModel extends _ViewModel {
  Future<void> loadProfile();
}

class ProfileViewModelImpl extends _ViewModel implements ProfileViewModel {
  final ProfileRepository profileRepository;

  ProfileViewModelImpl({required this.profileRepository});

  @override
  ProfileState build() => InitialState();

  @override
  Future<void> loadProfile() async {
    _emit(LoadingState());
    final result = await profileRepository.getProfile();

    final state = result.fold<ProfileState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );

    _emit(state);
  }

  void _emit(ProfileState newState) {
    emitState(newState);
    debugPrint('ProfileViewModel: $state');
  }
}
