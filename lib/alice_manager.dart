import 'package:alice_manager/alice.dart';
import 'package:alice_manager/alice_get_connect.dart';
import 'package:alice_manager/dio_interceptor.dart';
import 'package:alice_manager/model/alice_configuration.dart';
import 'package:alice_manager/overlay_alice.dart';
import 'package:flutter/material.dart';

class AliceManager {
  static final instance = AliceManager();
  final OverlayAlice _overlayAlice = OverlayAlice();
  OverlayAlice get overlayAlice => _overlayAlice;
  DioInterceptor get dioInterceptor => alice.dioInterceptor;
  GetConnectInterceptor get getConnectInterceptor =>
      alice.getConnectInterceptor;

  final Alice alice = Alice(
    configuration: AliceConfiguration(
      showInspectorOnShake: false,
    ),
  );

  void init(GlobalKey<NavigatorState> navigationKey) {
    alice.setNavigatorKey(navigationKey);
  }

  void showInspector() => alice.showInspector();

  void addEntryPoint(BuildContext context) =>
      _overlayAlice.insertOverlay(context);
}
