import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_profile.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_profile_provenance.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_profile_update.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';

void main() {
  group('DriverProfile sovereign lockdown', () {
    final now = DateTime.utc(2026, 7, 25);

    DriverProfile build() {
      return DriverProfile(
        driverId: 'd1',
        businessId: 'b1',
        branchId: 'br1',
        fullName: 'Driver One',
        phoneNumber: '0512345678',
        email: 'old@example.com',
        profileImageUrl: 'https://example.com/old.png',
        accountStatus: AccountStatus.pending,
        employmentStatus: EmploymentStatus.active,
        vehicleType: 'motorcycle',
        vehiclePlate: 'ABC-1',
        createdAt: now,
        updatedAt: now,
        provenance: DriverProfileProvenance.trialSynthetic,
      );
    }

    test('DriverProfileUpdate exposes only approved editable fields', () {
      const update = DriverProfileUpdate(
        fullName: 'Safe',
        email: 'a@b.c',
        profileImageUrl: 'https://example.com/n.png',
      );
      expect(update.fullName, 'Safe');
      expect(update.email, 'a@b.c');
      expect(update.profileImageUrl, 'https://example.com/n.png');
      // Structural proof: type has no sovereign members (compile-time).
      expect(
        DriverProfile.clientEditableFieldNames,
        equals({'fullName', 'email', 'profileImageUrl'}),
      );
      expect(
        DriverProfile.sovereignFieldNames.intersection(
          DriverProfile.clientEditableFieldNames,
        ),
        isEmpty,
      );
    });

    test('applyClientUpdate preserves all sovereign and vehicle fields', () {
      final profile = build();
      final updated = profile.applyClientUpdate(
        const DriverProfileUpdate(
          fullName: 'Safe Name',
          email: 'new@example.com',
          profileImageUrl: 'https://example.com/new.png',
        ),
        updatedAt: now.add(const Duration(minutes: 1)),
      );

      expect(updated.fullName, 'Safe Name');
      expect(updated.email, 'new@example.com');
      expect(updated.profileImageUrl, 'https://example.com/new.png');

      expect(updated.driverId, profile.driverId);
      expect(updated.businessId, profile.businessId);
      expect(updated.branchId, profile.branchId);
      expect(updated.phoneNumber, profile.phoneNumber);
      expect(updated.accountStatus, profile.accountStatus);
      expect(updated.employmentStatus, profile.employmentStatus);
      expect(updated.createdAt, profile.createdAt);
      expect(updated.vehicleType, profile.vehicleType);
      expect(updated.vehiclePlate, profile.vehiclePlate);
      expect(updated.provenance, profile.provenance);
    });

    test(
      'copyWith cannot spoof tenant, identity, phone, status, or createdAt',
      () {
        final profile = build();
        final updated = profile.copyWith(fullName: 'Only Name');
        expect(updated.driverId, 'd1');
        expect(updated.businessId, 'b1');
        expect(updated.branchId, 'br1');
        expect(updated.phoneNumber, '0512345678');
        expect(updated.accountStatus, AccountStatus.pending);
        expect(updated.employmentStatus, EmploymentStatus.active);
        expect(updated.createdAt, now);
        expect(updated.vehicleType, 'motorcycle');
        expect(updated.vehiclePlate, 'ABC-1');
      },
    );

    test('nullable businessId/branchId do not authorize client assignment', () {
      final unscoped = DriverProfile(
        driverId: 'd2',
        fullName: 'U',
        phoneNumber: '0500000000',
        accountStatus: AccountStatus.pending,
        employmentStatus: EmploymentStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final after = unscoped.applyClientUpdate(
        const DriverProfileUpdate(fullName: 'Still Unscoped'),
      );
      expect(after.businessId, isNull);
      expect(after.branchId, isNull);
      expect(after.hasBusinessScope, isFalse);
    });
  });
}
