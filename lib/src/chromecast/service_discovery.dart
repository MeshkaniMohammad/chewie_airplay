import 'dart:typed_data';

import 'package:flutter_mdns_plugin/flutter_mdns_plugin.dart';
import 'package:observable/observable.dart';
import 'dart:convert' show utf8;

class ServiceDiscovery extends ChangeNotifier {
  FlutterMdnsPlugin _flutterMdnsPlugin;
  List<ServiceInfo> foundServices = [];

  ServiceDiscovery() {
    _flutterMdnsPlugin = FlutterMdnsPlugin(
        discoveryCallbacks: DiscoveryCallbacks(
            onDiscoveryStarted: () => {},
            onDiscoveryStopped: () => {},
            onDiscovered: (ServiceInfo serviceInfo) => {},
            onResolved: (ServiceInfo serviceInfo) {
              print('found device ${serviceInfo.toString()}');
              if (serviceInfo.attr != null && serviceInfo.attr.isNotEmpty) {
                Map<String, Uint8List> attr = serviceInfo.attr;
                try {
                  if (attr.containsKey("fn")) {
                    serviceInfo.name = utf8.decode(attr["fn"]);
                  }
                } catch (e) {}
              }
              foundServices.add(serviceInfo);
              notifyChange();
            }));
  }

  startDiscovery() {
    _flutterMdnsPlugin.startDiscovery('_googlecast._tcp');
  }

  stopDiscovery() {
    _flutterMdnsPlugin.stopDiscovery();
  }
}
