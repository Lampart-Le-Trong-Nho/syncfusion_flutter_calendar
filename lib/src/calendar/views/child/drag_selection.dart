import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/appointment_engine/appointment_helper.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/common/calendar_view_helper.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/settings/time_slot_view_settings.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/sfcalendar.dart';

class DraggingSelectionWidget extends StatefulWidget {
  DraggingSelectionWidget({
    required this.timeLabelWidth,
    required this.cellHeight,
    required this.width,
    required this.height,
    this.dragSelectionHandle,
    this.scrollController,
    required this.timeSlotViewSettings,
    required this.calendar,
    required this.initDateTime,
  });

  final SfCalendar calendar;
  final double timeLabelWidth;
  final double cellHeight;
  final double width;
  final double height;
  final Function? dragSelectionHandle;
  final ScrollController? scrollController;
  final TimeSlotViewSettings timeSlotViewSettings;
  final DateTime initDateTime;

  @override
  _DraggingSelectionState createState() => _DraggingSelectionState();
}

class _DraggingSelectionState extends State<DraggingSelectionWidget> {
  final double paddingBottom = 25;
  final double dragDotsSize = 10;
  Offset? _position;
  bool showTimeStart = false;
  bool showTimeEnd = false;
  DateTime? today;
  DateTime? start;
  DateTime? end;
  final DateFormat formatterTime = DateFormat.Hm();
  double _selectionHeight = 0.0;
  double _minHeight = 0;
  bool _changeSize = false;
  double _heightScaleTemp = 0.0;

  @override
  void initState() {
    super.initState();
    _minHeight = widget.cellHeight / 4;
    today = DateTime(widget.initDateTime.year, widget.initDateTime.month,
        widget.initDateTime.day);
    _selectionHeight = widget.cellHeight;
    _initPosition();
  }

  @override
  void didUpdateWidget(covariant DraggingSelectionWidget oldWidget) {
    _minHeight = widget.cellHeight / 4;

    if (widget.initDateTime != oldWidget.initDateTime) {
      _initPosition();
    }

    if (widget.cellHeight != oldWidget.cellHeight) {
      _position = Offset(
          0,
          _getPositionSelectionFromDateTime(
              widget.cellHeight, start ?? widget.initDateTime));
      _selectionHeight *= widget.cellHeight / oldWidget.cellHeight;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initPosition() {
    double yPosition = AppointmentHelper.timeToPosition(
        widget.calendar, widget.initDateTime, widget.cellHeight);

    if (yPosition + _selectionHeight > widget.height) {
      yPosition = widget.height - _selectionHeight;
    }

    final Offset position = Offset(0, yPosition);
    _position = position;
    start = widget.initDateTime;
    end = today?.add(_getDurationFromPositionSelection(
        widget.cellHeight, position.dy + _selectionHeight));
    Future.delayed(
      const Duration(milliseconds: 500),
      () => CalendarViewHelper.raiseCalendarDaySelectionChangedCallback(
          widget.calendar, start, end),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position?.dx,
      top: _position?.dy,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          widget.dragSelectionHandle?.call(false);
        },
        onTapUp: (TapUpDetails details) {
          widget.dragSelectionHandle?.call(true);
        },
        onPanStart: _changeSize
            ? null
            : (DragStartDetails details) {
                showTimeStart = true;
              },
        onPanUpdate: _changeSize
            ? null
            : (DragUpdateDetails details) {
                _heightScaleTemp += details.delta.dy;

                if (_heightScaleTemp.abs() < _minHeight) {
                  return;
                }

                double dy = _position!.dy;

                if (_heightScaleTemp > 0) {
                  dy += _minHeight;
                } else {
                  dy -= _minHeight;
                }

                _heightScaleTemp = 0;

                if (dy < 0) {
                  dy = 0;
                } else if (dy + _selectionHeight > widget.height) {
                  dy = widget.height - _selectionHeight;
                }

                start = today?.add(
                    _getDurationFromPositionSelection(widget.cellHeight, dy));
                end = today?.add(_getDurationFromPositionSelection(
                    widget.cellHeight, dy + _selectionHeight));

                setState(() {
                  _position = Offset(_position!.dx, dy);
                });
              },
        onPanEnd: _changeSize
            ? null
            : (DragEndDetails details) {
                _heightScaleTemp = 0;
                showTimeStart = false;
                CalendarViewHelper.raiseCalendarDaySelectionChangedCallback(
                    widget.calendar, start, end);
                widget.dragSelectionHandle?.call(true);
              },
        child: Stack(
          children: <Widget>[
            Row(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: paddingBottom),
                  child: SizedBox(
                    width: widget.timeLabelWidth,
                    height: _selectionHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: <Widget>[
                        Positioned(
                          top: 0,
                          child: Text(
                            showTimeStart ? formatterTime.format(start!) : '',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(color: Colors.grey),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Text(
                              showTimeEnd ? formatterTime.format(end!) : '',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    color: Colors.grey,
                                  )),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: paddingBottom),
                  child: Container(
                    width: widget.width - widget.timeLabelWidth - 4,
                    height: _selectionHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown, width: 1.5),
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTapDown: (TapDownDetails details) {
                  setState(() {
                    _changeSize = true;
                  });
                },
                onTapUp: (TapUpDetails details) {
                  setState(() {
                    _changeSize = false;
                  });
                },
                onPanStart: (DragStartDetails details) {
                  showTimeEnd = true;
                },
                onPanUpdate: (DragUpdateDetails details) {
                  _heightScaleTemp += details.delta.dy;

                  if (_heightScaleTemp.abs() < _minHeight) {
                    return;
                  }

                  double updateHeight = _selectionHeight;

                  if (_heightScaleTemp > 0) {
                    updateHeight += _minHeight;
                  } else {
                    updateHeight -= _minHeight;
                  }

                  _heightScaleTemp = 0;

                  if (updateHeight <= _minHeight) {
                    updateHeight = _minHeight;
                  } else if (updateHeight > widget.height) {
                    updateHeight = widget.height;
                  }

                  end = today?.add(_getDurationFromPositionSelection(
                      widget.cellHeight, _position!.dy + updateHeight));

                  setState(() {
                    _selectionHeight = updateHeight;
                  });
                },
                onPanEnd: (DragEndDetails details) {
                  _heightScaleTemp = 0;
                  showTimeEnd = false;
                  CalendarViewHelper.raiseCalendarDaySelectionChangedCallback(
                      widget.calendar, start, end);
                  setState(() {
                    _changeSize = false;
                  });
                },
                child: SizedBox(
                  width: paddingBottom * 2,
                  height: paddingBottom * 2,
                  child: Center(
                    child: Container(
                      width: dragDotsSize,
                      decoration: const BoxDecoration(
                        color: Colors.brown,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration _getDurationFromPositionSelection(double cellHeight, double y) {
    return Duration(milliseconds: (y / cellHeight * 3600000).round());
  }

  double _getPositionSelectionFromDateTime(
      double cellHeight, DateTime duration) {
    return duration
            .difference(DateTime(duration.year, duration.month, duration.day))
            .inMilliseconds *
        cellHeight /
        3600000;
  }
}
