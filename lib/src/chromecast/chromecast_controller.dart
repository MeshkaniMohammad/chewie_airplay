import 'dart:async';

import 'package:dart_chromecast/casting/cast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:videoplay/src/chromecast/chromecast_controls.dart';
import 'package:videoplay/src/chromecast/service_discovery.dart';
import 'device_picker.dart';

class ChromecastController {
  CastMedia _castMedia;
  VoidCallback _listener;
  ServiceDiscovery _serviceDiscovery;
  CastSender _castSender;
  bool _servicesFound = false;
  VoidCallback _onChromecastConnected;
  MediaStatusListener _mediaStatusListener;
  final Function(String value) log;

  ChromecastController(this.log);

  void setupMediaStatusListener(MediaStatusListener listener) {
    _mediaStatusListener = listener;
  }

  Future reconnectOrDiscover({
    String videoPath,
    VoidCallback listener,
  }) async {
    log("reconnectOrDiscover");
    _listener = listener;
    _castMedia = CastMedia(
      contentId: videoPath,
    );
    bool reconnectSuccess = await _reconnect();
    if (!reconnectSuccess) {
      log("not reconnected");
      _discover();
    } else {
      log("reconnected");
      if (_mediaStatusListener != null) {
        log("_mediaStatusListener not null");
        if (_castSender != null && _castSender.castSession != null) {
          log("castSender castSession NOT null");
          _mediaStatusListener
              .onReconnected(_castSender.castSession.castMediaStatus);
        } else {
          log("castSender castSession null");
          _mediaStatusListener.onReconnected(null);
        }
      }
    }
  }

  void discover({
    String videoPath,
    VoidCallback listener,
  }) async {
    log("START discover");
    _listener = listener;
    _castMedia = CastMedia(
      contentId: videoPath,
    );
    await disconnect();
    _discover();
  }

  bool get serviceFound => _servicesFound;

  CastSender get castSender => _castSender;

  void reloadVideo() {
    _castSender.load(_castMedia);
  }

  Future disconnect() async {
    log("disconnect");
    if (_castSender != null) {
      log("disconnect _castSender not null");
      await _castSender.disconnect();
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('cast_session_host');
      prefs.remove('cast_session_port');
      prefs.remove('cast_session_device_name');
      prefs.remove('cast_session_device_type');
      prefs.remove('cast_session_sender_id');
      prefs.remove('cast_session_destination_id');

      _castSender = null;
      _servicesFound = false;
      _discover();
    }
  }

  void selectDevice(
      BuildContext context, VoidCallback onChromecastConnected, double time) {
    _onChromecastConnected = onChromecastConnected;
    log("selectDevice");
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          content: DevicePicker(
            serviceDiscovery: _serviceDiscovery,
            onDevicePicked: (device) {
              log("onDevicePicked");
              _connectToDevice(device, time);
            },
          ),
        );
      },
    );
  }

  _discover() async {
    log("_discover");
    _serviceDiscovery = ServiceDiscovery();
    _serviceDiscovery.changes.listen((_) {
      log("_discover");
      if (!_servicesFound && _serviceDiscovery.foundServices.length > 0) {
        //The service is just found
        log("The service is just found");
        _listener();
      } else if (_servicesFound &&
          _serviceDiscovery.foundServices.length == 0) {
        log("The service is just lost");
        //The service is just lost
//        _listener();
      }
      _servicesFound = _serviceDiscovery.foundServices.length > 0;
      log("_services length = " +
          _serviceDiscovery.foundServices.length.toString());
    });
    _serviceDiscovery.startDiscovery();
  }

  Future<bool> _reconnect() async {
    log("_reconnect");
    final prefs = await SharedPreferences.getInstance();
    String host = prefs.getString('cast_session_host');
    String name = prefs.getString('cast_session_device_name');
    String type = prefs.getString('cast_session_device_type');
    String sourceId = prefs.getString('cast_session_sender_id');
    String destinationId = prefs.getString('cast_session_destination_id');
    if (null == host ||
        null == name ||
        null == type ||
        null == sourceId ||
        null == destinationId) {
      log("Prefs are empty");
      return false;
    }
    log("Prefs are NOT empty");
    CastDevice device = CastDevice(
        name: name,
        host: host,
        port: prefs.getInt('cast_session_port') ?? 8009,
        type: type);
    _castSender = CastSender(device);
    StreamSubscription subscription = _castSender.castSessionController.stream
        .listen((CastSession castSession) {
      print('CastSession update ${castSession.isConnected.toString()}');
      if (castSession.isConnected) {
        _castSessionIsConnected(castSession);
      }
    });
    log("trying to reconnect");
    bool didReconnect = await _castSender.reconnect(
      sourceId: sourceId,
      destinationId: destinationId,
    );
    if (!didReconnect) {
      log("Could not reconnect");
      subscription.cancel();
      _castSender = null;
    }
    log("Reconnect success");
    return didReconnect;
  }

  void _castSessionIsConnected(CastSession castSession) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cast_session_host', _castSender.device.host);
    prefs.setInt('cast_session_port', _castSender.device.port);
    prefs.setString('cast_session_device_name', _castSender.device.name);
    prefs.setString('cast_session_device_type', _castSender.device.type);
    prefs.setString('cast_session_sender_id', castSession.sourceId);
    prefs.setString('cast_session_destination_id', castSession.destinationId);
    _listener();
  }

  void _connectToDevice(CastDevice device, double time) async {
    // stop discovery, only has to be on when we're not casting already
    log("_connectToDevice");
    _serviceDiscovery.stopDiscovery();

    _castSender = CastSender(device);
    StreamSubscription subscription = _castSender.castSessionController.stream
        .listen((CastSession castSession) {
      log("castSession " + castSession.toString());
      if (castSession.isConnected) {
        log("castSession isConnected");
        _castSessionIsConnected(castSession);
        _castMedia.position = time;
        _castSender.load(_castMedia);
      }
    });
    log("_castSender connect");
    bool connected = await _castSender.connect();
    if (!connected) {
      log("Not connected");
      // show error message...
      subscription.cancel();
      _castSender = null;
      return;
    }

    // SAVE STATE SO WE CAN TRY TO RECONNECT!
    _castSender.launch();
    _onChromecastConnected();
  }
}
