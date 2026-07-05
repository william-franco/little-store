import 'package:little_store_app/src/common/constants/api_constant.dart';
import 'package:little_store_app/src/common/patterns/result_pattern.dart';
import 'package:little_store_app/src/common/services/connection_service.dart';
import 'package:little_store_app/src/common/services/http_service.dart';
import 'package:little_store_app/src/features/profile/exceptions/profile_exception.dart';
import 'package:little_store_app/src/features/profile/models/profile_model.dart';

typedef ProfileResult = Result<ProfileModel, ProfileException>;

abstract interface class ProfileRepository {
  Future<ProfileResult> getProfile();
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ConnectionService connectionService;
  final HttpService httpService;

  ProfileRepositoryImpl({
    required this.connectionService,
    required this.httpService,
  });

  @override
  Future<ProfileResult> getProfile() async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: ProfileException('Dispositivo sem conexão.'));
      }

      final result = await httpService.getData(path: ApiConstant.authMe);

      if (result.statusCode == 200 && result.data != null) {
        final profile = ProfileModel.fromJson(
          result.data as Map<String, dynamic>,
        );
        return SuccessResult(value: profile);
      }

      return ErrorResult(
        error: ProfileException('Falha ao carregar perfil: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: ProfileException('Erro inesperado: $error'));
    }
  }
}
