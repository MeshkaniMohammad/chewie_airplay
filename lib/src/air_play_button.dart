import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AirPlayButton extends StatelessWidget {
  final double size;
  final Color color;

  AirPlayButton({
    Key key,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Icon(
            Icons.airplay,
            size: size,
            color: color,
          ),
          Container(
            width: size,
            height: size,
            child: UiKitView(
              viewType: "airplay",
              creationParamsCodec: const StandardMessageCodec(),
            ),
          ),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }
}
