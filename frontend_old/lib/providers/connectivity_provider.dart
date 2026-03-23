import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityProvider with ChangeNotifier {
  ConnectivityStatus _status = ConnectivityStatus.online;
  final Connectivity _connectivity = Connectivity();

  ConnectivityStatus get status => _status;
  bool get isOffline => _status == ConnectivityStatus.offline;

  ConnectivityProvider() {
    _init();
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateStatus(results);
    });
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      _status = ConnectivityStatus.offline;
    } else {
      _status = ConnectivityStatus.online;
    }
    notifyListeners();
  }
}
