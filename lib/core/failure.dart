import 'package:equatable/equatable.dart';

import 'failure_strings.dart';

abstract class Failure extends Equatable {}

class OfflineFailure extends Failure {
  final String? message;
  OfflineFailure({this.message});
  @override
  List<Object?> get props => [message ?? OFFLINE_FAILURE_MESSAGE];
}

class ServerFailure extends Failure {
  final String? message;
  ServerFailure({this.message});
  @override
  List<Object?> get props => [message ?? SERVER_FAILURE_MESSAGE];
}

class DuplicateFailure extends Failure {
  final String? message;
  DuplicateFailure({this.message});
  @override
  List<Object?> get props => [message ?? DUPLICATE_FAILURE_MESSAGE];
}

class UnfilledDataFailure extends Failure {
  final String? message;
  UnfilledDataFailure({this.message});
  @override
  List<Object?> get props => [message ?? EMPTY_BODY_FAILURE_MESSAGE];
}

class NotFoundFailure extends Failure {
  final String? message;
  NotFoundFailure({this.message});
  @override
  List<Object?> get props => [message ?? NOT_FOUND_FAILURE_MESSAGE];
}

class WrongDataFailure extends Failure {
  final String? message;
  WrongDataFailure({this.message});
  @override
  List<Object?> get props => [message ?? WRONG_DATA_FAILURE_MESSAGE];
}

class UnauthorizedFailure extends Failure {
  final String? message;
  UnauthorizedFailure({this.message});
  @override
  List<Object?> get props => [message ?? NOT_AUTHORIZED_FAILURE_MESSAGE];
}

class NothingFailure extends Failure {
  @override
  List<Object?> get props => [];
}