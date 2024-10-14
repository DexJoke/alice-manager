import 'package:alice_manager/dio_interceptor.dart';
import 'package:alice_manager/alice_get_connect.dart';
import 'package:alice_manager/core/alice_adapter.dart';
import 'package:alice_manager/core/alice_core.dart';
import 'package:alice_manager/model/alice_configuration.dart';
import 'package:alice_manager/model/alice_http_call.dart';
import 'package:alice_manager/model/alice_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

export 'package:alice_manager/model/alice_log.dart';
export 'package:alice_manager/core/alice_memory_storage.dart';
export 'package:alice_manager/utils/alice_parser.dart';
export 'package:alice_manager/alice_manager.dart';
export 'alice_widget_overlay.dart';

class Alice {
  late final AliceCore _aliceCore;
  final DioInterceptor _dioInterceptor = DioInterceptor();
  DioInterceptor get dioInterceptor => _dioInterceptor;
  final GetConnectInterceptor _getConnectInterceptor = GetConnectInterceptor();
  GetConnectInterceptor get getConnectInterceptor => _getConnectInterceptor;

  /// Creates alice instance.
  Alice({AliceConfiguration? configuration}) {
    _aliceCore = AliceCore(
      configuration: configuration ?? AliceConfiguration(),
    );
    _dioInterceptor.injectCore(_aliceCore);
    _getConnectInterceptor.injectCore(_aliceCore);
  }

  /// Set custom navigation key. This will help if there's route library.
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _aliceCore.setNavigatorKey(navigatorKey);
  }

  /// Get currently used navigation key
  GlobalKey<NavigatorState>? getNavigatorKey() =>
      _aliceCore.configuration.navigatorKey;

  /// Opens Http calls inspector. This will navigate user to the new fullscreen
  /// page where all listened http calls can be viewed.
  void showInspector() => _aliceCore.navigateToCallListScreen();

  /// Handle generic http call. Can be used to any http client.
  void addHttpCall(AliceHttpCall aliceHttpCall) {
    assert(aliceHttpCall.request != null, "Http call request can't be null");
    assert(aliceHttpCall.response != null, "Http call response can't be null");

    _aliceCore.addCall(aliceHttpCall);
  }

  /// Adds new log to Alice logger.
  void addLog(AliceLog log) => _aliceCore.addLog(log);

  /// Adds list of logs to Alice logger
  void addLogs(List<AliceLog> logs) => _aliceCore.addLogs(logs);

  /// Returns flag which determines whether inspector is opened
  bool get isInspectorOpened => _aliceCore.isInspectorOpened;

  /// Adds new adapter to Alice.
  void addAdapter(AliceAdapter adapter) => adapter.injectCore(_aliceCore);
}
