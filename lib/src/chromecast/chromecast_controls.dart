import 'package:dart_chromecast/casting/cast_media_status.dart';

abstract class MediaStatusListener{
  void onReconnected(CastMediaStatus mediaStatus);
}