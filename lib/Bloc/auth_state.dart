abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}
class AuthLoadingProfile extends AuthState {}
class AuthProfileLoaded extends AuthState {}
class AuthAuthenticated extends AuthState {
  final String message;
  AuthAuthenticated(this.message);
}

class AuthError extends AuthState {
  final String error;
  AuthError(this.error);
}
class AuthMessage extends AuthState {
  final String message;
  AuthMessage(this.message);
}
class AuthLogout extends AuthState {}

class PolicyAccepted extends AuthState {
  final String message;
  PolicyAccepted(this.message);
}