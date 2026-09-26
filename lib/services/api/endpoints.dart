/// REST endpoints (relative to `API_BASE_URL`). Contract: docs/BACKEND_API.md
abstract final class Endpoints {
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authRefresh = '/auth/refresh';
  static const authSocial = '/auth/social';
  static const authForgotPassword = '/auth/forgot-password';
  static const authResetPassword = '/auth/reset-password';
  static const me = '/me';
  static const meAvatar = '/me/avatar';
  static const devices = '/devices';
  static const transactions = '/transactions';
  static String transaction(String id) => '/transactions/$id';
}
