class FavoriteException implements Exception {
  final String message;

  const FavoriteException(this.message);

  @override
  String toString() => message;
}
