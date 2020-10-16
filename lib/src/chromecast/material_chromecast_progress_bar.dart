import 'package:dart_chromecast/casting/cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:videoplay/src/chewie_progress_colors.dart';
import 'package:videoplay/src/chromecast/chromecast_controller.dart';

class MaterialChromecastProgressBar extends StatefulWidget {
  MaterialChromecastProgressBar({
    ChewieProgressColors colors,
    this.duration,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.chromecastController,
  }) : colors = colors ?? ChewieProgressColors();

  final int duration;
  final ChewieProgressColors colors;
  final Function() onDragStart;
  final Function() onDragEnd;
  final Function() onDragUpdate;
  final ChromecastController chromecastController;

  @override
  _VideoProgressBarState createState() {
    return _VideoProgressBarState(chromecastController);
  }
}

class _VideoProgressBarState extends State<MaterialChromecastProgressBar> {
  final ChromecastController chromecastController;

  _VideoProgressBarState(this.chromecastController) {
    listener = () {
      setState(() {});
    };
  }
  VoidCallback listener;
  bool _controllerWasPlaying = false;

  @override
  void initState() {
    super.initState();
    chromecastController.castSender.castMediaStatusController.stream
        .listen(_mediaStatusChanged);
    setState(() {
    });
  }

  void _mediaStatusChanged(CastMediaStatus mediaStatus) {
    setState(() {
    });
  }

  CastMediaStatus mediaStatus() {
    if (chromecastController.castSender != null &&
        chromecastController.castSender.castSession != null)
      return chromecastController.castSender.castSession.castMediaStatus;
    else
      return null;
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final box = context.findRenderObject() as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = Duration(seconds: widget.duration) * relative;

      chromecastController.castSender.seek(position.inSeconds.toDouble());
    }

    return GestureDetector(
      child: Center(
        child: Container(
          height: MediaQuery.of(context).size.height / 2,
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent,
          child: CustomPaint(
            painter: _ProgressBarPainter(
              widget.duration,
              mediaStatus() != null ? mediaStatus().position : 0.0,
              widget.colors,
            ),
          ),
        ),
      ),
      onHorizontalDragStart: (DragStartDetails details) {
        if (mediaStatus() == null) {
          return;
        }
        _controllerWasPlaying = mediaStatus() != null && mediaStatus().isPlaying;
        if (_controllerWasPlaying) {

          chromecastController.castSender.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (mediaStatus() == null) {
          return;
        }
        seekToRelativePosition(details.globalPosition);

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_controllerWasPlaying) {

          chromecastController.castSender.play();
        }

        if (widget.onDragEnd != null) {
          widget.onDragEnd();
        }
      },
      onTapDown: (TapDownDetails details) {
        if (mediaStatus() == null) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.duration, this.value, this.colors);

  final int duration;
  double value;
  ChewieProgressColors colors;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final height = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(size.width, size.height / 2 + height),
        ),
        Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    double playedPartPercent = 0;
    if (duration != 0.0) {
      playedPartPercent = (value * 1000.0) / (duration.toDouble() * 1000.0);
    }
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(playedPart, size.height / 2 + height),
        ),
        Radius.circular(4.0),
      ),
      colors.playedPaint,
    );
    canvas.drawCircle(
      Offset(playedPart, size.height / 2 + height / 2),
      height * 3,
      colors.handlePaint,
    );
  }
}
