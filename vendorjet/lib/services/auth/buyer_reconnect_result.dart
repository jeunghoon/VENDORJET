class BuyerReconnectResult {
  final bool success;
  final String? message;
  final bool pendingExists;
  final bool alreadyConnected;

  const BuyerReconnectResult({
    required this.success,
    this.message,
    this.pendingExists = false,
    this.alreadyConnected = false,
  });

  const BuyerReconnectResult.success({String? message})
      : this(success: true, message: message);

  const BuyerReconnectResult.failure({
    String? message,
    bool pendingExists = false,
    bool alreadyConnected = false,
  }) : this(
          success: false,
          message: message,
          pendingExists: pendingExists,
          alreadyConnected: alreadyConnected,
        );

  bool get handled =>
      success || pendingExists || alreadyConnected;
}
