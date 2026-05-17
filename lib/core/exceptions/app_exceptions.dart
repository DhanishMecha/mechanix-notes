class AppAlreadyRunningException implements Exception {
  final String message;
  AppAlreadyRunningException([
    this.message = 'This app instance is already running.',
  ]);

  @override
  String toString() => message;
}
