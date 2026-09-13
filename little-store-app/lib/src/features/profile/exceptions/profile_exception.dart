class ProfileException implements Exception {
  final String message;

  const ProfileException(this.message);

  @override
  String toString() => message;
}
