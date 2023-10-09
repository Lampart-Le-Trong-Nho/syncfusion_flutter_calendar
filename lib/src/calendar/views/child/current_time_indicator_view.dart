import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_core/core.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/common/calendar_view_helper.dart';

class CurrentTimeIndicator extends CustomPainter {
  CurrentTimeIndicator(
      this.timeIntervalSize,
      this.timeRulerSize,
      this.timeSlotViewSettings,
      this.isTimelineView,
      this.visibleDates,
      this.todayHighlightColor,
      this.isRTL,
      ValueNotifier<int> repaintNotifier)
      : super(repaint: repaintNotifier);
  final double timeIntervalSize;
  final TimeSlotViewSettings timeSlotViewSettings;
  final bool isTimelineView;
  final List<DateTime> visibleDates;
  final double timeRulerSize;
  final Color? todayHighlightColor;
  final bool isRTL;

  @override
  void paint(Canvas canvas, Size size) {
    final DateTime now = DateTime.now();
    final int hours = now.hour;
    final int minutes = now.minute;
    final int totalMinutes = (hours * 60) + minutes;
    final int viewStartMinutes = (timeSlotViewSettings.startHour * 60).toInt();
    final int viewEndMinutes = (timeSlotViewSettings.endHour * 60).toInt();
    if (totalMinutes < viewStartMinutes || totalMinutes > viewEndMinutes) {
      return;
    }

    int index = -1;
    for (int i = 0; i < visibleDates.length; i++) {
      final DateTime date = visibleDates[i];
      if (isSameDate(date, now)) {
        index = i;
        break;
      }
    }

    if (index == -1) {
      return;
    }

    final double minuteHeight = timeIntervalSize /
        CalendarViewHelper.getTimeInterval(timeSlotViewSettings);
    final double currentTimePosition = CalendarViewHelper.getTimeToPosition(
        Duration(hours: hours, minutes: minutes),
        timeSlotViewSettings,
        minuteHeight);
    final Paint painter = Paint()
      ..color = todayHighlightColor!
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    if (isTimelineView) {
      final double viewSize = size.width / visibleDates.length;
      double startXPosition = (index * viewSize) + currentTimePosition;
      if (isRTL) {
        startXPosition = size.width - startXPosition;
      }
      canvas.drawCircle(Offset(startXPosition, 5), 5, painter);
      canvas.drawLine(Offset(startXPosition, 0),
          Offset(startXPosition, size.height), painter);
    } else {
      final double viewSize =
          (size.width - timeRulerSize) / visibleDates.length;
      final double startYPosition = currentTimePosition;
      double viewStartPosition = (index * viewSize) + timeRulerSize;
      double viewEndPosition = viewStartPosition + viewSize;
      double startXPosition = viewStartPosition < 5 ? 5 : viewStartPosition;
      if (isRTL) {
        viewStartPosition = size.width - viewStartPosition;
        viewEndPosition = size.width - viewEndPosition;
        startXPosition = size.width - startXPosition;
      }
      canvas.drawCircle(Offset(startXPosition, startYPosition), 5, painter);
      canvas.drawLine(Offset(viewStartPosition, startYPosition),
          Offset(viewEndPosition, startYPosition), painter);
    }
  }

  @override
  bool? hitTest(Offset position) {
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}