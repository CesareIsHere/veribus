import 'dart:async';

import 'package:emiliano_cesare_flutter_template/core/config.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/app_failure.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payments_repository.g.dart';

/// RevenueCat wrapper: the only place that talks to the purchases SDK.
class PaymentsRepository {
  Future<void>? _configured;

  /// Configured only on iOS/Android with the platform API key set.
  bool get isAvailable =>
      !kIsWeb &&
      switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS => AppConfig.revenueCatAppleKey.isNotEmpty,
        TargetPlatform.android => AppConfig.revenueCatGoogleKey.isNotEmpty,
        _ => false,
      };

  Future<void> _configure() => _configured ??= Purchases.configure(
    PurchasesConfiguration(
      defaultTargetPlatform == TargetPlatform.android ? AppConfig.revenueCatGoogleKey : AppConfig.revenueCatAppleKey,
    ),
  );

  /// Links purchases to [userId] (null = anonymous).
  Future<void> identify(String? userId) async {
    await _configure();
    if (userId != null) {
      await Purchases.logIn(userId);
    } else if (!await Purchases.isAnonymous) {
      await Purchases.logOut();
    }
  }

  Stream<CustomerInfo> customerInfo() async* {
    await _configure();
    final controller = StreamController<CustomerInfo>();
    void listener(CustomerInfo info) => controller.add(info);
    Purchases.addCustomerInfoUpdateListener(listener);
    controller.onCancel = () => Purchases.removeCustomerInfoUpdateListener(listener);
    yield await Purchases.getCustomerInfo();
    yield* controller.stream;
  }

  Future<Offering?> currentOffering() async {
    await _configure();
    return (await Purchases.getOfferings()).current;
  }

  Future<void> purchase(Package package) async {
    try {
      await Purchases.purchase(PurchaseParams.package(package));
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        throw const AuthFailure(AuthErrorCode.cancelled);
      }
      rethrow;
    }
  }

  Future<void> restore() => Purchases.restorePurchases();
}

@Riverpod(keepAlive: true)
PaymentsRepository paymentsRepository(Ref ref) => PaymentsRepository();
