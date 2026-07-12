import '../models/auth_session.dart';

/// Puerto de autenticación remota (capa de aplicación).
///
/// Los casos de uso de login/registro dependen de esta interfaz, no de la
/// implementación HTTP concreta (`AuthApiClient`), para respetar DIP.
abstract interface class IAuthApiClient {
  /// Registra un usuario (`POST /auth/register`).
  Future<({String userId, String username})> register({
    required String username,
    required String password,
  });

  /// Inicia sesión (`POST /auth/login`) y devuelve la sesión con JWT.
  Future<AuthSession> login({
    required String username,
    required String password,
  });
}
