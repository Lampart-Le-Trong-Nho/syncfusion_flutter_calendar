import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/common/calendar_view_helper.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/settings/time_slot_view_settings.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/sfcalendar.dart';

class DraggingSelectionWidget extends StatefulWidget {
  DraggingSelectionWidget({
    required this.timeLabelWidth,
    required this.cellHeight,
    required this.width,
    required this.height,
    Offset? position,
    this.dragSelectionHandle,
    this.scrollController,
    required this.timeSlotViewSettings,
    required this.calendar,
  }) {
    this.position = position ?? Offset(0, 0);
  }

  final SfCalendar calendar;
  final double timeLabelWidth;
  final double cellHeight;
  final double width;
  final double height;
  late Offset position;
  final Function? dragSelectionHandle;
  final ScrollController? scrollController;
  final TimeSlotViewSettings timeSlotViewSettings;

  @override
  _DraggingSelectionState createState() => _DraggingSelectionState();
}

class _DraggingSelectionState extends State<DraggingSelectionWidget> {
  final double paddingBottom = 15;
  final double dragDotsSize = 10;
  Offset? _position;
  bool showTimeStart = false;
  bool showTimeEnd = false;
  DateTime? start;
  DateTime? end;
  final DateFormat formatterTime = DateFormat.Hm();
  double _selectionHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _position = widget.position;
    _selectionHeight = widget.cellHeight;
    start =
        _getDateFromPositionSelection(widget.cellHeight, widget.position.dy);
    end = _getDateFromPositionSelection(
        widget.cellHeight, widget.position.dy + _selectionHeight);
  }

  @override
  void dispose() {
    super.dispose();
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
        onPanStart: (DragStartDetails details) {
          showTimeStart = true;
        },
        onPanUpdate: (DragUpdateDetails details) {
          double dy = _position!.dy + details.delta.dy;

          if (dy < 0) {
            dy = 0;
          } else if (dy + _selectionHeight > widget.height) {
            dy = widget.height - _selectionHeight;
          }

          start = _getDateFromPositionSelection(widget.cellHeight, dy);
          end = _getDateFromPositionSelection(
              widget.cellHeight, dy + _selectionHeight);

          setState(() {
            _position = Offset(_position!.dx, dy);
          });
        },
        onPanEnd: (DragEndDetails details) {
          showTimeStart = false;
          CalendarViewHelper.raiseCalendarDaySelectionChangedCallback(
              widget.calendar, start, end);
        },
        child: Stack(
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: widget.timeLabelWidth,
                  height: _selectionHeight,
                  child: Stack(
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
              right: 15,
              bottom: 0,
              child: GestureDetector(
                onPanStart: (DragStartDetails details) {
                  showTimeEnd = true;
                },
                onPanUpdate: (DragUpdateDetails details) {
                  double updateHeight = _selectionHeight + details.delta.dy;

                  if (updateHeight <= 20) {
                    updateHeight = 20;
                  } else if (updateHeight > widget.height) {
                    updateHeight = widget.height;
                  }

                  end = _getDateFromPositionSelection(
                      widget.cellHeight, _position!.dy + updateHeight);

                  setState(() {
                    _selectionHeight = updateHeight;
                  });
                },
                onPanEnd: (DragEndDetails details) {
                  showTimeEnd = false;
                  CalendarViewHelper.raiseCalendarDaySelectionChangedCallback(
                      widget.calendar, start, end);
                },
                child: Container(
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

  DateTime? _getDateFromPositionSelection(double cellHeight, double y) {
    final double time = y / cellHeight;
    final int hour = time.truncate();
    final int minute = ((time - hour) * 60).round();

    return DateTime(0, 1, 1, hour, minute);
  }
}
