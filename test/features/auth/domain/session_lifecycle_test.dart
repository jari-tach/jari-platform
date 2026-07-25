import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/auth/domain/entities/auth_error.dart';
import 'package:saeq_driver/features/auth/domain/entities/driver_session.dart';
import 'package:saeq_driver/features/auth/domain/entities/session_lifecycle.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller_state.dart';

void main() {
  test('sessionLifecycle maps controller statuses', () {
    expect(
      const AuthControllerState.unauthenticated().sessionLifecycle,
      SessionLifecycle.unauthenticated,
    );
    expect(
      const AuthControllerState.authenticating().sessionLifecycle,
      SessionLifecycle.authenticating,
    );
    expect(
      AuthControllerState.authenticated(
        const DriverSession(
          driverId: 'd',
          phoneNumber: '0512345678',
          sessionToken: 't',
        ),
      ).sessionLifecycle,
      SessionLifecycle.authenticated,
    );
    expect(
      const AuthControllerState.expired().sessionLifecycle,
      SessionLifecycle.expired,
    );
    expect(
      const AuthControllerState.failure(UnexpectedAuthError()).sessionLifecycle,
      SessionLifecycle.failed,
    );
    expect(
      const AuthControllerState.restoring().sessionLifecycle,
      SessionLifecycle.unknown,
    );
  });
}
