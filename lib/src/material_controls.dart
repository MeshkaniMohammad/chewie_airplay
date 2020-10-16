import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:videoplay/src/chromecast/chromecast_controller.dart';
import 'package:videoplay/src/utils.dart';

import 'chewie_player.dart';
import 'chewie_progress_colors.dart';
import 'chromecast/chromecast_material_controls.dart';
import 'material_progress_bar.dart';

class MaterialControls extends StatefulWidget {
  const MaterialControls({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls>
    with WidgetsBindingObserver {
  ChromecastController _chromecastController;
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _chromecastModeActive = false;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  String _log = "";

  final barHeight = 48.0;
  final marginSize = 5.0;

  VideoPlayerController controller;
  ChewieController chewieController;

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_chromecastModeActive) {
        _chromecastController.reconnectOrDiscover(
            videoPath: controller.dataSource,
            listener: () {
              if (chewieController != null) setState(() {});
            });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  void _dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
    if (_chromecastController != null) await _chromecastController.disconnect();
  }

  bool castServicesFound() {
    return _chromecastController != null
        ? _chromecastController.serviceFound
        : false;
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder(
              context,
              chewieController.videoPlayerController.value.errorDescription,
            )
          : Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
                size: 42,
              ),
            );
    }
    if (_chromecastController == null &&
        chewieController != null &&
        controller.dataSource.isNotEmpty) {
      _chromecastController = ChromecastController((value) {
        print(value);
        this._log = this._log + "\n" + value;
      });
      _chromecastController.discover(
          videoPath: controller.dataSource,
          listener: () {
            if (chewieController != null) setState(() {});
          });
    }
    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: _chromecastModeActive
            ? _buildChromeCastControls()
            : AbsorbPointer(
                absorbing: _hideStuff,
                child: Column(
                  children: <Widget>[
                    _latestValue != null &&
                                !_latestValue.isPlaying &&
                                _latestValue.duration == null ||
                            _latestValue.isBuffering
                        ? const Expanded(
                            child: const Center(
                              child: const CircularProgressIndicator(),
                            ),
                          )
                        : _buildHitArea(),
                    _buildBottomBar(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildChromeCastControls() {
    print(controller.value.duration);
      ChromecastMaterialControls material = ChromecastMaterialControls(
        duration: controller.value.duration != null ? controller.value.duration.inSeconds : 0,
        onChromeCastPressed: (time) async {
        if (chewieController.isFullScreen) {
          Navigator.of(context).pop();
        }
        await _chromecastController.disconnect();
          setState(() {
            _chromecastModeActive = false;
            chewieController.seekTo(Duration(seconds: time.toInt()));
            chewieController.play();
          });
        },
        setupMediaStatusListener: (listener) {
          _chromecastController.setupMediaStatusListener(listener);
        },
        chromecastController: _chromecastController,
        isFullScreen: chewieController.isFullScreen,
      );
    return material;
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    final iconColor = Theme.of(context).textTheme.button.color;

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        height: barHeight,
        color: Theme.of(context).dialogBackgroundColor,
        child: Row(
          children: <Widget>[
            _buildPlayPause(controller),
            chewieController.isLive
                ? Expanded(child: const Text('LIVE'))
                : _buildPosition(iconColor),
            chewieController.isLive ? const SizedBox() : _buildProgressBar(),
            chewieController.allowMuting
                ? _buildMuteButton(controller)
                : Container(),
            chewieController.allowFullScreen
                ? _buildExpandButton()
                : Container(),
            _buildChromeCastButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildChromeCastButton() {
    if (!castServicesFound()) {
      return SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        if (_chromecastController != null)
          _chromecastController.selectDevice(context, () {
            setState(() {
              chewieController.pause();
              _chromecastModeActive = true;
            });
          }, controller.value.position.inSeconds.toDouble());
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(Icons.cast),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          margin: EdgeInsets.only(right: 12.0),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_latestValue != null && _latestValue.isPlaying) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
              });
            } else
              _cancelAndRestartTimer();
          } else {
            _playPause();

            setState(() {
              _hideStuff = true;
            });
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
              opacity:
                  _latestValue != null && !_latestValue.isPlaying && !_dragging
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
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
              ),
              child: Icon(
                (_latestValue != null && _latestValue.volume > 0)
                    ? Icons.volume_up
                    : Icons.volume_off,
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: EdgeInsets.only(left: 8.0, right: 4.0),
        padding: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return Padding(
      padding: EdgeInsets.only(right: 24.0),
      child: Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: TextStyle(
          fontSize: 14.0,
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<Null> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      chewieController.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    bool isFinished;
    if( _latestValue.duration != null)
    {
      isFinished = _latestValue.position >= _latestValue.duration;
    }
    else
    {
      isFinished = false;
    }

    setState(() {
      if (controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration(seconds: 0));
          }
          controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: MaterialVideoProgressBar(
        controller,
        onDragStart: () {
          setState(() {
            _dragging = true;
          });

          _hideTimer?.cancel();
        },
        onDragEnd: () {
          setState(() {
            _dragging = false;
          });

          _startHideTimer();
        },
        colors: chewieController.materialProgressColors ??
            ChewieProgressColors(
                playedColor: Theme.of(context).accentColor,
                handleColor: Theme.of(context).accentColor,
                bufferedColor: Theme.of(context).backgroundColor,
                backgroundColor: Theme.of(context).disabledColor),
      ),
    );
  }
}
