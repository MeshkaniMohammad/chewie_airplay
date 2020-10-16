import 'package:dart_chromecast/casting/cast.dart';
import 'package:flutter/material.dart';
import 'package:videoplay/chewie.dart';
import 'package:videoplay/src/chromecast/chromecast_controller.dart';
import 'package:videoplay/src/chromecast/chromecast_controls.dart';
import 'package:videoplay/src/chromecast/material_chromecast_progress_bar.dart';
import 'package:videoplay/src/utils.dart';

class ChromecastMaterialControls extends StatefulWidget {
  final int duration;
  final Function(double time) onChromeCastPressed;
  final Function(MediaStatusListener listener) setupMediaStatusListener;
  final ChromecastController chromecastController;
  final bool isFullScreen;

  const ChromecastMaterialControls({
    Key key,
    @required this.duration,
    @required this.onChromeCastPressed,
    @required this.setupMediaStatusListener,
    @required this.chromecastController,
    @required this.isFullScreen,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    _ChromecastMaterialControlsState state =
        _ChromecastMaterialControlsState(chromecastController);
    setupMediaStatusListener(state);
    return state;
  }
}

class _ChromecastMaterialControlsState extends State<ChromecastMaterialControls>
    implements MediaStatusListener {
  bool _dragging = false;
  final barHeight = 48.0;
  final marginSize = 5.0;
  final ChromecastController chromecastController;

  _ChromecastMaterialControlsState(this.chromecastController);

  @override
  void initState() {
    super.initState();
    chromecastController.castSender.castMediaStatusController.stream
        .listen(_mediaStatusChanged);

    setState(() {});
  }

  @override
  void onReconnected(CastMediaStatus mediaStatus) {
    chromecastController.castSender.castMediaStatusController.stream
        .listen(_mediaStatusChanged);
    setState(() {});
  }

  CastMediaStatus mediaStatus() {
    if (chromecastController.castSender != null &&
        chromecastController.castSender.castSession != null)
      return chromecastController.castSender.castSession.castMediaStatus;
    else
      return null;
  }

  void _mediaStatusChanged(CastMediaStatus mediaStatus) {
    if (mediaStatus == null) return;
    if (!_dragging) {
      setState(() {});
    }
  }

  void _playPause() {
    if (mediaStatus() == null) return;

    bool isFinished = mediaStatus().isFinished;

    setState(() {
      if (mediaStatus().isPlaying) {
        chromecastController.castSender.pause();
      } else {
        if (mediaStatus().isLoading) {
          chromecastController.castSender.play();
        } else {
          if (isFinished) {
            chromecastController.reloadVideo();
          }
          chromecastController.castSender.play();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (mediaStatus() != null && mediaStatus().hasError) {
      return Center(
        child: Icon(
          Icons.error,
          color: Colors.white,
          size: 42,
        ),
      );
    }

    return Stack(fit: StackFit.expand, children: [
      Column(
        children: <Widget>[
          _buildHitArea(),
          _buildBottomBar(context),
        ],
      )
    ]);
  }

  Widget _buildBottomBar(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.button.color;
    return Container(
      height: barHeight,
      color: Theme.of(context).dialogBackgroundColor,
      child: Row(
        children: <Widget>[
          _buildPlayPause(),
          _buildPosition(iconColor),
          _buildProgressBar(),
          _buildChromeCastButton(),
        ],
      ),
    );
  }

  Widget _buildChromeCastButton() {
    return GestureDetector(
      onTap: () {
        widget.onChromeCastPressed(
            mediaStatus() != null ? mediaStatus().position : 0.0);
      },
      child: Container(
        height: barHeight,
        padding: EdgeInsets.only(
          left: 8.0,
          right: 8.0,
        ),
        child: Center(
          child: Icon(Icons.cast_connected),
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              if (mediaStatus() != null && mediaStatus().isPlaying) {
              } else {
                _playPause();
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: mediaStatus() != null &&
                          !mediaStatus().isPlaying &&
                          !_dragging
                      ? 1.0
                      : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: GestureDetector(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).dialogBackgroundColor,
                        borderRadius: BorderRadius.circular(48.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(Icons.play_arrow, size: 32.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          widget.isFullScreen ? _buildCloseButton() : SizedBox()
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 6.0,
      right: 6.0,
      child: SizedBox(
        width: 32.0,
        height: 32.0,
        child: Material(
          type: MaterialType.button,
          color: Colors.white,
          child: InkWell(
            onTap: () {
              widget.onChromeCastPressed(
                  mediaStatus() != null ? mediaStatus().position : 0.0);
            },
            child: Padding(
                padding: const EdgeInsets.all(5.0), child: Icon(Icons.close)),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause() {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: Icon(
          mediaStatus() != null && mediaStatus().isPlaying
              ? Icons.pause
              : Icons.play_arrow,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = mediaStatus() != null
        ? Duration(seconds: mediaStatus().position.toInt())
        : Duration.zero;
    final duration = Duration(seconds: widget.duration);

    return Padding(
      padding: EdgeInsets.only(right: 20.0),
      child: Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: TextStyle(
          fontSize: 14.0,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: MaterialChromecastProgressBar(
        chromecastController: chromecastController,
        duration: widget.duration,
        onDragStart: () {
          setState(() {
            _dragging = true;
          });
        },
        onDragEnd: () {
          setState(() {
            _dragging = false;
          });
        },
        colors: ChewieProgressColors(
            playedColor: Theme.of(context).accentColor,
            handleColor: Theme.of(context).accentColor,
            bufferedColor: Theme.of(context).backgroundColor,
            backgroundColor: Theme.of(context).disabledColor),
      ),
    );
  }
}
