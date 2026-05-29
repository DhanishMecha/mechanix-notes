class HiveLockedException implements Exception {
  final String message;

  HiveLockedException([
    this.message = 'Notes app is already open in another instance.',
  ]);

  @override
  String toString() => message;
}
