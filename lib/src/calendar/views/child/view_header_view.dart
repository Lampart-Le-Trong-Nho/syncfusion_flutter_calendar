import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:syncfusion_flutter_core/core.dart';
import 'package:syncfusion_flutter_core/localizations.dart';
import 'package:syncfusion_flutter_core/theme.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/common/calendar_view_helper.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/common/date_time_engine.dart';

class ViewHeaderViewPainter extends CustomPainter {
  ViewHeaderViewPainter(
      this.visibleDates,
      this.view,
      this.viewHeaderStyle,
      this.timeSlotViewSettings,
      this.timeLabelWidth,
      this.viewHeaderHeight,
      this.monthViewSettings,
      this.isRTL,
      this.locale,
      this.calendarTheme,
      this.todayHighlightColor,
      this.todayTextStyle,
      this.cellBorderColor,
      this.minDate,
      this.maxDate,
      this.viewHeaderNotifier,
      this.textScaleFactor,
      this.showWeekNumber,
      this.isMobilePlatform,
      this.weekNumberStyle,
      this.localizations)
      : super(repaint: viewHeaderNotifier);

  final CalendarView view;
  final ViewHeaderStyle viewHeaderStyle;
  final TimeSlotViewSettings timeSlotViewSettings;
  final MonthViewSettings monthViewSettings;
  final List<DateTime> visibleDates;
  final double timeLabelWidth;
  final double viewHeaderHeight;
  final SfCalendarThemeData calendarTheme;
  final bool isRTL;
  final String locale;
  final Color? todayHighlightColor;
  final TextStyle? todayTextStyle;
  final Color? cellBorderColor;
  final DateTime minDate;
  final DateTime maxDate;
  final ValueNotifier<Offset?> viewHeaderNotifier;
  final double textScaleFactor;
  final Paint _circlePainter = Paint();
  final TextPainter _dayTextPainter = TextPainter(),
      _dateTextPainter = TextPainter();
  final bool showWeekNumber;
  final bool isMobilePlatform;
  final WeekNumberStyle weekNumberStyle;
  final SfLocalizations localizations;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final double weekNumberPanelWidth =
    CalendarViewHelper.getWeekNumberPanelWidth(
        showWeekNumber, size.width, isMobilePlatform);
    double width = view == CalendarView.month
        ? size.width - weekNumberPanelWidth
        : size.width;
    width = _getViewHeaderWidth(width);

    /// Initializes the default text style for the texts in view header of
    /// calendar.
    final TextStyle viewHeaderDayStyle = calendarTheme.viewHeaderDayTextStyle!;
    final TextStyle viewHeaderDateStyle =
    calendarTheme.viewHeaderDateTextStyle!;

    final DateTime today = DateTime.now();
    if (view != CalendarView.month) {
      _addViewHeaderForTimeSlotViews(
          canvas, size, viewHeaderDayStyle, viewHeaderDateStyle, width, today);
    } else {
      _addViewHeaderForMonthView(
          canvas, size, viewHeaderDayStyle, width, today, weekNumberPanelWidth);
    }
  }

  void _addViewHeaderForMonthView(
      Canvas canvas,
      Size size,
      TextStyle viewHeaderDayStyle,
      double width,
      DateTime today,
      double weekNumberPanelWidth) {
    TextStyle dayTextStyle = viewHeaderDayStyle;
    double xPosition = isRTL
        ? size.width - width - weekNumberPanelWidth
        : weekNumberPanelWidth;
    double yPosition = 0;
    final int visibleDatesLength = visibleDates.length;
    bool hasToday = monthViewSettings.numberOfWeeksInView > 0 &&
        monthViewSettings.numberOfWeeksInView < 6 ||
        visibleDates[visibleDatesLength ~/ 2].month == today.month;
    if (hasToday) {
      hasToday = isDateWithInDateRange(
          visibleDates[0], visibleDates[visibleDatesLength - 1], today);
    }

    for (int i = 0; i < DateTime.daysPerWeek; i++) {
      final DateTime currentDate = visibleDates[i];
      String dayText = DateFormat(monthViewSettings.dayFormat, locale)
          .format(currentDate)
          .toUpperCase();

      dayText = _updateViewHeaderFormat(monthViewSettings.dayFormat, dayText);

      if (hasToday && currentDate.weekday == today.weekday) {
        final Color? todayTextColor =
        CalendarViewHelper.getTodayHighlightTextColor(
            todayHighlightColor, todayTextStyle, calendarTheme);

        dayTextStyle = todayTextStyle != null
            ? calendarTheme.todayTextStyle!.copyWith(
            fontSize: viewHeaderDayStyle.fontSize, color: todayTextColor)
            : viewHeaderDayStyle.copyWith(color: todayTextColor);
      } else {
        dayTextStyle = viewHeaderDayStyle;
      }

      _updateDayTextPainter(dayTextStyle, width, dayText);

      if (yPosition == 0) {
        yPosition = (viewHeaderHeight - _dayTextPainter.height) / 2;
      }

      if (viewHeaderNotifier.value != null) {
        _addMouseHoverForMonth(canvas, size, xPosition, yPosition, width);
      }

      _dayTextPainter.paint(
          canvas,
          Offset(
              xPosition + (width / 2 - _dayTextPainter.width / 2), yPosition));

      if (isRTL) {
        xPosition -= width;
      } else {
        xPosition += width;
      }
    }
    if (weekNumberPanelWidth != 0 && showWeekNumber) {
      const double defaultFontSize = 14;
      final TextStyle weekNumberTextStyle = calendarTheme.weekNumberTextStyle!;
      final double xPosition = isRTL ? (size.width - weekNumberPanelWidth) : 0;

      _updateDayTextPainter(weekNumberTextStyle, weekNumberPanelWidth,
          localizations.weeknumberLabel);

      /// Condition added to remove the ellipsis, when the width is too small
      /// the ellipsis alone displayed, hence to resolve this removed ecclipsis
      /// when the width is too small, in this scenario the remaining letters
      /// were clipped.
      if (_dayTextPainter.didExceedMaxLines &&
          (_dayTextPainter.width <=
              (weekNumberTextStyle.fontSize ?? defaultFontSize) * 1.5)) {
        _dayTextPainter.ellipsis = null;
        _dayTextPainter.layout(maxWidth: weekNumberPanelWidth);
      }

      _dayTextPainter.paint(
          canvas,
          Offset(
              xPosition +
                  (weekNumberPanelWidth / 2 - _dayTextPainter.width / 2),
              yPosition));
    }
  }

  void _addViewHeaderForTimeSlotViews(
      Canvas canvas,
      Size size,
      TextStyle viewHeaderDayStyle,
      TextStyle viewHeaderDateStyle,
      double width,
      DateTime today) {
    double xPosition, yPosition;
    final bool isDayView = CalendarViewHelper.isDayView(
        view,
        timeSlotViewSettings.numberOfDaysInView,
        timeSlotViewSettings.nonWorkingDays,
        monthViewSettings.numberOfWeeksInView);
    final double labelWidth =
    isDayView && timeLabelWidth < 50 ? 50 : timeLabelWidth;
    TextStyle dayTextStyle = viewHeaderDayStyle;
    TextStyle dateTextStyle = viewHeaderDateStyle;
    const double topPadding = 5;
    if (isDayView) {
      width = labelWidth;
    }

    final Paint linePainter = Paint();
    xPosition = isDayView ? 0 : timeLabelWidth;
    yPosition = 2;
    final int visibleDatesLength = visibleDates.length;
    final double cellWidth = width / visibleDatesLength;
    if (isRTL && !isDayView) {
      xPosition = size.width - timeLabelWidth - cellWidth;
    }
    for (int i = 0; i < visibleDatesLength; i++) {
      final DateTime currentDate = visibleDates[i];

      String dayText = DateFormat(timeSlotViewSettings.dayFormat, locale)
          .format(currentDate)
          .toUpperCase();

      dayText =
          _updateViewHeaderFormat(timeSlotViewSettings.dayFormat, dayText);

      final String dateText =
      DateFormat(timeSlotViewSettings.dateFormat).format(currentDate);
      final bool isToday = isSameDate(currentDate, today);
      if (isToday) {
        final Color? todayTextStyleColor = calendarTheme.todayTextStyle!.color;
        final Color? todayTextColor =
        CalendarViewHelper.getTodayHighlightTextColor(
            todayHighlightColor, todayTextStyle, calendarTheme);
        dayTextStyle = todayTextStyle != null
            ? calendarTheme.todayTextStyle!.copyWith(
            fontSize: viewHeaderDayStyle.fontSize, color: todayTextColor)
            : viewHeaderDayStyle.copyWith(color: todayTextColor);
        dateTextStyle = todayTextStyle != null
            ? calendarTheme.todayTextStyle!
            .copyWith(fontSize: viewHeaderDateStyle.fontSize)
            : viewHeaderDateStyle.copyWith(color: todayTextStyleColor);
      } else {
        dayTextStyle = viewHeaderDayStyle;
        dateTextStyle = viewHeaderDateStyle;
      }

      if (!isDateWithInDateRange(minDate, maxDate, currentDate)) {
        dayTextStyle = dayTextStyle.copyWith(
            color: dayTextStyle.color != null
                ? dayTextStyle.color!.withOpacity(0.38)
                : calendarTheme.brightness == Brightness.light
                ? Colors.black26
                : Colors.white38);
        dateTextStyle = dateTextStyle.copyWith(
            color: dateTextStyle.color != null
                ? dateTextStyle.color!.withOpacity(0.38)
                : calendarTheme.brightness == Brightness.light
                ? Colors.black26
                : Colors.white38);
      }

      _updateDayTextPainter(dayTextStyle, width, dayText);

      final TextSpan dateTextSpan = TextSpan(
        text: dateText,
        style: dateTextStyle,
      );

      _dateTextPainter.text = dateTextSpan;
      _dateTextPainter.textDirection = TextDirection.ltr;
      _dateTextPainter.textAlign = TextAlign.left;
      _dateTextPainter.textWidthBasis = TextWidthBasis.longestLine;
      _dateTextPainter.textScaleFactor = textScaleFactor;

      _dateTextPainter.layout(maxWidth: width);

      /// To calculate the day start position by width and day painter
      final double dayXPosition = (cellWidth - _dayTextPainter.width) / 2;

      /// To calculate the date start position by width and date painter
      final double dateXPosition = (cellWidth - _dateTextPainter.width) / 2;

      const int inBetweenPadding = 2;
      yPosition = size.height / 2 -
          (_dayTextPainter.height +
              topPadding +
              _dateTextPainter.height +
              inBetweenPadding) /
              2;

      _dayTextPainter.paint(
          canvas, Offset(xPosition + dayXPosition, yPosition));

      if (isToday) {
        _drawTodayCircle(
            canvas,
            xPosition + dateXPosition,
            yPosition + topPadding + _dayTextPainter.height + inBetweenPadding,
            _dateTextPainter);
      }

      if (viewHeaderNotifier.value != null) {
        _addMouseHoverForTimeSlotView(canvas, size, xPosition, yPosition,
            dateXPosition, topPadding, isToday, inBetweenPadding);
      }

      _dateTextPainter.paint(
          canvas,
          Offset(
              xPosition + dateXPosition,
              yPosition +
                  topPadding +
                  _dayTextPainter.height +
                  inBetweenPadding));
      if (!isDayView &&
          showWeekNumber &&
          ((currentDate.weekday == DateTime.monday) ||
              (view == CalendarView.workWeek &&
                  timeSlotViewSettings.nonWorkingDays
                      .contains(DateTime.monday) &&
                  i == visibleDatesLength ~/ 2))) {
        final String weekNumber =
        DateTimeHelper.getWeekNumberOfYear(currentDate).toString();
        final TextStyle weekNumberTextStyle =
        calendarTheme.weekNumberTextStyle!;
        final TextSpan dayTextSpan = TextSpan(
          text: weekNumber,
          style: weekNumberTextStyle,
        );
        _dateTextPainter.text = dayTextSpan;
        _dateTextPainter.textDirection = TextDirection.ltr;
        _dateTextPainter.textAlign = TextAlign.left;
        _dateTextPainter.textWidthBasis = TextWidthBasis.longestLine;
        _dateTextPainter.textScaleFactor = textScaleFactor;
        _dateTextPainter.layout(maxWidth: timeLabelWidth);
        final double weekNumberPosition = isRTL
            ? (size.width - timeLabelWidth) +
            ((timeLabelWidth - _dateTextPainter.width) / 2)
            : (timeLabelWidth - _dateTextPainter.width) / 2;
        final double weekNumberYPosition = size.height / 2 -
            (_dayTextPainter.height +
                topPadding +
                _dateTextPainter.height +
                inBetweenPadding) /
                2 +
            topPadding +
            _dayTextPainter.height +
            inBetweenPadding;
        const double padding = 10;
        final Rect rect = Rect.fromLTRB(
            weekNumberPosition - padding,
            weekNumberYPosition - (padding / 2),
            weekNumberPosition + _dateTextPainter.width + padding,
            weekNumberYPosition + _dateTextPainter.height + (padding / 2));
        linePainter.style = PaintingStyle.fill;
        linePainter.color = weekNumberStyle.backgroundColor ??
            calendarTheme.weekNumberBackgroundColor!;
        final RRect roundedRect =
        RRect.fromRectAndRadius(rect, const Radius.circular(padding / 2));
        canvas.drawRRect(roundedRect, linePainter);
        _dateTextPainter.paint(
            canvas, Offset(weekNumberPosition, weekNumberYPosition));
        final double xPosition = isRTL ? (size.width - timeLabelWidth) : 0;
        _updateDayTextPainter(
            weekNumberTextStyle, timeLabelWidth, localizations.weeknumberLabel);
        _dayTextPainter.paint(
            canvas,
            Offset(xPosition + (timeLabelWidth / 2 - _dayTextPainter.width / 2),
                yPosition));
      }

      if (isRTL) {
        xPosition -= cellWidth;
      } else {
        xPosition += cellWidth;
      }
    }
  }

  void _addMouseHoverForMonth(Canvas canvas, Size size, double xPosition,
      double yPosition, double width) {
    if (xPosition + (width / 2 - _dayTextPainter.width / 2) <=
        viewHeaderNotifier.value!.dx &&
        xPosition +
            (width / 2 - _dayTextPainter.width / 2) +
            _dayTextPainter.width >=
            viewHeaderNotifier.value!.dx &&
        yPosition - 5 <= viewHeaderNotifier.value!.dy &&
        (yPosition + size.height) - 5 >= viewHeaderNotifier.value!.dy) {
      _drawTodayCircle(
          canvas,
          xPosition + (width / 2 - _dayTextPainter.width / 2),
          yPosition,
          _dayTextPainter,
          hoveringColor: (calendarTheme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black87)
              .withOpacity(0.04));
    }
  }

  void _addMouseHoverForTimeSlotView(
      Canvas canvas,
      Size size,
      double xPosition,
      double yPosition,
      double dateXPosition,
      double topPadding,
      bool isToday,
      int padding) {
    if (xPosition + dateXPosition <= viewHeaderNotifier.value!.dx &&
        xPosition + dateXPosition + _dateTextPainter.width >=
            viewHeaderNotifier.value!.dx) {
      final Color hoveringColor = isToday
          ? Colors.black.withOpacity(0.12)
          : (calendarTheme.brightness == Brightness.dark
          ? Colors.white
          : Colors.black87)
          .withOpacity(0.04);
      _drawTodayCircle(
          canvas,
          xPosition + dateXPosition,
          yPosition + topPadding + _dayTextPainter.height + padding,
          _dateTextPainter,
          hoveringColor: hoveringColor);
    }
  }

  String _updateViewHeaderFormat(String dayFormat, String dayText) {
    switch (view) {
      case CalendarView.day:
      case CalendarView.week:
      case CalendarView.workWeek:
        {
          if (!CalendarViewHelper.isDayView(
              view,
              timeSlotViewSettings.numberOfDaysInView,
              timeSlotViewSettings.nonWorkingDays,
              monthViewSettings.numberOfWeeksInView) &&
              (dayFormat == 'EE' && (locale.contains('en')))) {
            return dayText[0];
          }
          break;
        }
      case CalendarView.schedule:
      case CalendarView.timelineDay:
      case CalendarView.timelineWeek:
      case CalendarView.timelineWorkWeek:
      case CalendarView.timelineMonth:
        break;
      case CalendarView.month:
        {
          //// EE format value shows the week days as S, M, T, W, T, F, S.
          if (dayFormat == 'EE' && (locale.contains('en'))) {
            return dayText[0];
          }
        }
    }

    return dayText;
  }

  void _updateDayTextPainter(
      TextStyle dayTextStyle, double width, String dayText) {
    final TextSpan dayTextSpan = TextSpan(
      text: dayText,
      style: dayTextStyle,
    );

    _dayTextPainter.text = dayTextSpan;
    _dayTextPainter.textDirection = TextDirection.ltr;
    _dayTextPainter.textAlign = TextAlign.left;
    _dayTextPainter.textWidthBasis = TextWidthBasis.longestLine;
    _dayTextPainter.textScaleFactor = textScaleFactor;
    _dayTextPainter.ellipsis = '...';
    _dayTextPainter.maxLines = 1;

    _dayTextPainter.layout(maxWidth: width);
  }

  double _getViewHeaderWidth(double width) {
    switch (view) {
      case CalendarView.timelineDay:
      case CalendarView.timelineWeek:
      case CalendarView.timelineWorkWeek:
      case CalendarView.timelineMonth:
      case CalendarView.schedule:
        return 0;
      case CalendarView.month:
        return width / DateTime.daysPerWeek;
      case CalendarView.day:
      case CalendarView.week:
      case CalendarView.workWeek:
        {
          if (CalendarViewHelper.isDayView(
              view,
              timeSlotViewSettings.numberOfDaysInView,
              timeSlotViewSettings.nonWorkingDays,
              monthViewSettings.numberOfWeeksInView)) {
            return timeLabelWidth;
          }
          return width - timeLabelWidth;
        }
    }
  }

  @override
  bool shouldRepaint(ViewHeaderViewPainter oldDelegate) {
    final ViewHeaderViewPainter oldWidget = oldDelegate;
    return oldWidget.visibleDates != visibleDates ||
        oldWidget.viewHeaderStyle != viewHeaderStyle ||
        oldWidget.viewHeaderHeight != viewHeaderHeight ||
        oldWidget.todayHighlightColor != todayHighlightColor ||
        oldWidget.timeSlotViewSettings != timeSlotViewSettings ||
        oldWidget.monthViewSettings != monthViewSettings ||
        oldWidget.cellBorderColor != cellBorderColor ||
        oldWidget.calendarTheme != calendarTheme ||
        oldWidget.isRTL != isRTL ||
        oldWidget.locale != locale ||
        oldWidget.todayTextStyle != todayTextStyle ||
        oldWidget.textScaleFactor != textScaleFactor ||
        oldWidget.weekNumberStyle != weekNumberStyle ||
        oldWidget.showWeekNumber != showWeekNumber;
  }

  //// draw today highlight circle in view header.
  void _drawTodayCircle(
      Canvas canvas, double x, double y, TextPainter dateTextPainter,
      {Color? hoveringColor}) {
    _circlePainter.color = (hoveringColor ?? todayHighlightColor)!;
    const double circlePadding = 5;
    final double painterWidth = dateTextPainter.width / 2;
    final double painterHeight = dateTextPainter.height / 2;
    final double radius =
    painterHeight > painterWidth ? painterHeight : painterWidth;
    canvas.drawCircle(Offset(x + painterWidth, y + painterHeight),
        radius + circlePadding, _circlePainter);
  }

  /// overrides this property to build the semantics information which uses to
  /// return the required information for accessibility, need to return the list
  /// of custom painter semantics which contains the rect area and the semantics
  /// properties for accessibility
  @override
  SemanticsBuilderCallback get semanticsBuilder {
    return (Size size) {
      return _getSemanticsBuilder(size);
    };
  }

  @override
  bool shouldRebuildSemantics(ViewHeaderViewPainter oldDelegate) {
    final ViewHeaderViewPainter oldWidget = oldDelegate;
    return oldWidget.visibleDates != visibleDates;
  }

  String _getAccessibilityText(DateTime date) {
    if (!isDateWithInDateRange(minDate, maxDate, date)) {
      // ignore: lines_longer_than_80_chars
      return '${DateFormat('EEEEE').format(date)}${DateFormat('dd MMMM yyyy').format(date)}, Disabled date';
    }

    return DateFormat('EEEEE').format(date) +
        DateFormat('dd MMMM yyyy').format(date);
  }

  List<CustomPainterSemantics> _getSemanticsForMonthViewHeader(Size size) {
    final List<CustomPainterSemantics> semanticsBuilder =
    <CustomPainterSemantics>[];
    final double cellWidth = size.width / DateTime.daysPerWeek;
    double left = isRTL ? size.width - cellWidth : 0;
    const double top = 0;
    for (int i = 0; i < DateTime.daysPerWeek; i++) {
      semanticsBuilder.add(CustomPainterSemantics(
        rect: Rect.fromLTWH(left, top, cellWidth, size.height),
        properties: SemanticsProperties(
          label: DateFormat('EEEEE').format(visibleDates[i]).toUpperCase(),
          textDirection: TextDirection.ltr,
        ),
      ));
      if (isRTL) {
        left -= cellWidth;
      } else {
        left += cellWidth;
      }
    }

    return semanticsBuilder;
  }

  List<CustomPainterSemantics> _getSemanticsForDayHeader(Size size) {
    final List<CustomPainterSemantics> semanticsBuilder =
    <CustomPainterSemantics>[];
    const double top = 0;
    double left;
    final bool isDayView = CalendarViewHelper.isDayView(
        view,
        timeSlotViewSettings.numberOfDaysInView,
        timeSlotViewSettings.nonWorkingDays,
        monthViewSettings.numberOfWeeksInView);
    final double cellWidth = isDayView
        ? size.width
        : (size.width - timeLabelWidth) / visibleDates.length;
    if (isRTL) {
      left = isDayView
          ? size.width - timeLabelWidth
          : (size.width - timeLabelWidth) - cellWidth;
    } else {
      left = isDayView ? 0 : timeLabelWidth;
    }
    for (int i = 0; i < visibleDates.length; i++) {
      final DateTime visibleDate = visibleDates[i];
      if (showWeekNumber &&
          ((visibleDate.weekday == DateTime.monday && !isDayView) ||
              (view == CalendarView.workWeek &&
                  timeSlotViewSettings.nonWorkingDays
                      .contains(DateTime.monday) &&
                  i == visibleDates.length ~/ 2))) {
        final int weekNumber = DateTimeHelper.getWeekNumberOfYear(visibleDate);
        semanticsBuilder.add(CustomPainterSemantics(
            rect: Rect.fromLTWH(isRTL ? (size.width - timeLabelWidth) : 0, 0,
                isRTL ? size.width : timeLabelWidth, viewHeaderHeight),
            properties: SemanticsProperties(
              label: 'week$weekNumber',
              textDirection: TextDirection.ltr,
            )));
      }
      semanticsBuilder.add(CustomPainterSemantics(
        rect: Rect.fromLTWH(left, top, cellWidth, size.height),
        properties: SemanticsProperties(
          label: _getAccessibilityText(visibleDates[i]),
          textDirection: TextDirection.ltr,
        ),
      ));
      if (isRTL) {
        left -= cellWidth;
      } else {
        left += cellWidth;
      }
    }

    return semanticsBuilder;
  }

  List<CustomPainterSemantics> _getSemanticsBuilder(Size size) {
    switch (view) {
      case CalendarView.schedule:
      case CalendarView.timelineDay:
      case CalendarView.timelineWeek:
      case CalendarView.timelineWorkWeek:
      case CalendarView.timelineMonth:
        return <CustomPainterSemantics>[];
      case CalendarView.month:
        return _getSemanticsForMonthViewHeader(size);
      case CalendarView.day:
      case CalendarView.week:
      case CalendarView.workWeek:
        return _getSemanticsForDayHeader(size);
    }
  }
}