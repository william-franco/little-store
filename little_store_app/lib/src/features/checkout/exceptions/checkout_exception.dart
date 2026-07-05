class CheckoutException implements Exception {
  final String message;

  const CheckoutException(this.message);

  @override
  String toString() => message;
}
