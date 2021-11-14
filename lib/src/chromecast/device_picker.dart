import 'dart:async';
import 'package:dart_chromecast/casting/cast_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdns_plugin/flutter_mdns_plugin.dart';
import 'package:observable/observable.dart';
import 'package:videoplay/src/chromecast/service_discovery.dart';

class DevicePicker extends StatefulWidget {
  final ServiceDiscovery serviceDiscovery;
  final Function(CastDevice) onDevicePicked;

  DevicePicker({this.serviceDiscovery, this.onDevicePicked});

  @override
  _DevicePickerState createState() => _DevicePickerState();
}

class _DevicePickerState extends State<DevicePicker> {
  List<CastDevice> _devices = [];
  List<StreamSubscription> _streamSubscriptions = [];

  void initState() {
    super.initState();
    widget.serviceDiscovery.changes.listen((List<ChangeRecord> _) {
      _updateDevices();
    });
    _updateDevices();
  }

  _deviceDidUpdate(CastDevice device) {
    // this device did update, we need to trigger setState
    setState(() => {});
  }

  CastDevice _castDeviceFromServiceInfo(ServiceInfo serviceInfo) {
    CastDevice castDevice = CastDevice(
        name: serviceInfo.name,
        type: serviceInfo.type,
        host: serviceInfo.hostName,
        port: serviceInfo.port);
    // _streamSubscriptions
    //     .add(castDevice.changes.listen((_) => _deviceDidUpdate(castDevice)));
    return castDevice;
  }

  void _updateDevices() {
    // probably a new service was discovered, so add the new device to the list.
    _devices = [];
    List<CastDevice> devices =
        widget.serviceDiscovery.foundServices.map((ServiceInfo serviceInfo) {
      return _castDeviceFromServiceInfo(serviceInfo);
    }).toList();
    if (devices != null && devices.isNotEmpty) {
      int length = devices.length - 1;
      for (var i = length; i >= 0; i--) {
        CastDevice device = _devices.firstWhere(
            (CastDevice d) => d.name == devices[i].name,
            orElse: () => null);
        if (device == null) {
          _devices.add(devices[i]);
        }
      }
    }
  }

  Widget _buildListViewItem(BuildContext context, int index) {
    CastDevice castDevice = _devices[index];
    return ListTile(
      title: Text(castDevice.friendlyName),
      onTap: () {
        if (null != widget.onDevicePicked) {
          widget.onDevicePicked(castDevice);
          // clean up steam listeners
          _streamSubscriptions.forEach(
              (StreamSubscription subscription) => subscription.cancel());
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: SizedBox(
        height: 150.0,
        child: Material(
          type: MaterialType.transparency,
          child: ListView.builder(
            shrinkWrap: true,
            itemBuilder: _buildListViewItem,
            itemCount: _devices.length,
          ),
        ),
      ),
    );
  }
}
