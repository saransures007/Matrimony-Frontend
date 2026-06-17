// class AppConfig {
//   const AppConfig._();

//   static const apiBaseUrl = String.fromEnvironment(
//     'API_BASE_URL',
//     defaultValue: 'http://localhost:3000/api/v1',
//   );

//   static const socketBaseUrl = String.fromEnvironment(
//     'SOCKET_BASE_URL',
//     defaultValue: 'http://localhost:3000',
//   );
// }
class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.29.160:3000/api/v1',
  );

  static const socketBaseUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: 'http://192.168.29.160:3000',
  );
}