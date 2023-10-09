import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:syncfusion_flutter_core/theme.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/common/calendar_view_helper.dart';

class TimeRulerView extends CustomPainter {
  TimeRulerView(
      this.horizontalLinesCount,
      this.timeIntervalHeight,
      this.timeSlotViewSettings,
      this.cellBorderColor,
      this.isRTL,
      this.locale,
      this.calendarTheme,
      this.isTimelineView,
      this.visibleDates,
      this.textScaleFactor);

  final double horizontalLinesCount;
  final double timeIntervalHeight;
  final TimeSlotViewSettings timeSlotViewSettings;
  final bool isRTL;
  final String locale;
  final SfCalendarThemeData calendarTheme;
  final Color? cellBorderColor;
  final bool isTimelineView;
  final List<DateTime> visibleDates;
  final double textScaleFactor;
  final Paint _linePainter = Paint();
  final TextPainter _textPainter = TextPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    const double offset = 0.5;
    double xPosition, yPosition;
    DateTime date = visibleDates[0];

    xPosition = isRTL && isTimelineView ? size.width : 0;
    yPosition = timeIntervalHeight;
    _linePainter.strokeWidth = offset;
    _linePainter.color = cellBorderColor ?? calendarTheme.cellBorderColor!;

    if (!isTimelineView) {
      final double lineXPosition = isRTL ? offset : size.width - offset;
      // Draw vertical time label line
      canvas.drawLine(Offset(lineXPosition, 0),
          Offset(lineXPosition, size.height), _linePainter);
    }

    _textPainter.textDirection = TextDirection.ltr;
    _textPainter.textWidthBasis = TextWidthBasis.longestLine;
    _textPainter.textScaleFactor = textScaleFactor;

    final TextStyle timeTextStyle = calendarTheme.timeTextStyle!;

    final double hour = (timeSlotViewSettings.startHour -
        timeSlotViewSettings.startHour.toInt()) *
        60;
    if (isTimelineView) {
      canvas.drawLine(Offset.zero, Offset(size.width, 0), _linePainter);
      final double timelineViewWidth =
          timeIntervalHeight * horizontalLinesCount;
      for (int i = 0; i < visibleDates.length; i++) {
        date = visibleDates[i];
        _drawTimeLabels(
            canvas, size, date, hour, xPosition, yPosition, timeTextStyle);
        if (isRTL) {
          xPosition -= timelineViewWidth;
        } else {
          xPosition += timelineViewWidth;
        }
      }
    } else {
      _drawTimeLabels(
          canvas, size, date, hour, xPosition, yPosition, timeTextStyle);
    }
  }

  /// Draws the time labels in the time label view for timeslot views in
  /// calendar.
  void _drawTimeLabels(Canvas canvas, Size size, DateTime date, double hour,
      double xPosition, double yPosition, TextStyle timeTextStyle) {
    const int padding = 5;
    final int timeInterval =
    CalendarViewHelper.getTimeInterval(timeSlotViewSettings);

    /// For timeline view we will draw 24 lines where as in day, week and work
    /// week view we will draw 23 lines excluding the 12 AM, hence to rectify
    /// this the i value handled accordingly.
    for (int i = isTimelineView ? 0 : 1;
    i <= (isTimelineView ? horizontalLinesCount - 1 : horizontalLinesCount);
    i++) {
      if (isTimelineView) {
        canvas.save();
        canvas.clipRect(
            Rect.fromLTWH(xPosition, 0, timeIntervalHeight, size.height));
        canvas.restore();
        canvas.drawLine(
            Offset(xPosition, 0), Offset(xPosition, size.height), _linePainter);
      }

      final double minute = (i * timeInterval) + hour;
      date = DateTime(date.year, date.month, date.day,
          timeSlotViewSettings.startHour.toInt(), minute.toInt());
      final String time =
      DateFormat(timeSlotViewSettings.timeFormat, locale).format(date);
      final TextSpan span = TextSpan(
        text: time,
        style: timeTextStyle,
      );

      final double cellWidth = isTimelineView ? timeIntervalHeight : size.width;

      _textPainter.text = span;
      _textPainter.layout(maxWidth: cellWidth);
      if (isTimelineView && _textPainter.height > size.height) {
        return;
      }

      double startXPosition = (cellWidth - _textPainter.width) / 2;
      if (startXPosition < 0) {
        startXPosition = 0;
      }

      if (isTimelineView) {
        startXPosition = isRTL ? xPosition - _textPainter.width : xPosition;
      }

      double startYPosition = yPosition - (_textPainter.height / 2);

      if (isTimelineView) {
        startYPosition = (size.height - _textPainter.height) / 2;
        startXPosition =
        isRTL ? startXPosition - padding : startXPosition + padding;
      }

      _textPainter.paint(canvas, Offset(startXPosition, startYPosition));

      if (!isTimelineView) {
        final Offset start =
        Offset(isRTL ? 0 : size.width - (startXPosition / 2), yPosition);
        final Offset end =
        Offset(isRTL ? startXPosition / 2 : size.width, yPosition);
        canvas.drawLine(start, end, _linePainter);
        yPosition += timeIntervalHeight;
        if (yPosition.round() == size.height.round()) {
          break;
        }
      } else {
        if (isRTL) {
          xPosition -= timeIntervalHeight;
        } else {
          xPosition += timeIntervalHeight;
        }
      }
    }
  }

  @override
  bool shouldRepaint(TimeRulerView oldDelegate) {
    final TimeRulerView oldWidget = oldDelegate;
    return oldWidget.timeSlotViewSettings != timeSlotViewSettings ||
        oldWidget.cellBorderColor != cellBorderColor ||
        oldWidget.calendarTheme != calendarTheme ||
        oldWidget.isRTL != isRTL ||
        oldWidget.locale != locale ||
        oldWidget.visibleDates != visibleDates ||
        oldWidget.isTimelineView != isTimelineView ||
        oldWidget.textScaleFactor != textScaleFactor;
  }
}