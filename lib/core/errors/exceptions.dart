/// Exceptions thrown inside the data layer. Repositories catch them and turn
/// them into [Failure]s, so they never reach the presentation layer.
class CacheException implements Exception {
  const CacheException([this.message]);
  final String? message;

  @override
  String toString() => 'CacheException: ${message ?? ''}';
}

class ServerException implements Exception {
  const ServerException({this.statusCode, this.message});
  final int? statusCode;
  final String? message;

  @override
  String toString() => 'ServerException($statusCode): ${message ?? ''}';
}
