import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../../../../calendar.dart';
import '../../appointment_engine/appointment_helper.dart';
import '../../common/calendar_view_helper.dart';

class SelectionPainter extends CustomPainter {
  SelectionPainter(
      this.calendar,
      this.view,
      this.visibleDates,
      this.selectedDate,
      this.selectionDecoration,
      this.timeIntervalHeight,
      this.calendarTheme,
      this.repaintNotifier,
      this.isRTL,
      this.selectedResourceIndex,
      this.resourceItemHeight,
      this.showWeekNumber,
      this.isMobilePlatform,
      this.getCalendarState)
      : super(repaint: repaintNotifier);

  final SfCalendar calendar;
  final CalendarView view;
  final SfCalendarThemeData calendarTheme;
  final List<DateTime> visibleDates;
  Decoration? selectionDecoration;
  DateTime? selectedDate;
  final double timeIntervalHeight;
  final bool isRTL;
  final UpdateCalendarState getCalendarState;
  int selectedResourceIndex;
  final double? resourceItemHeight;

  late BoxPainter _boxPainter;
  AppointmentView? appointmentView;
  double _cellWidth = 0, _cellHeight = 0, _xPosition = 0, _yPosition = 0;
  final ValueNotifier<bool> repaintNotifier;
  final UpdateCalendarStateDetails _updateCalendarStateDetails =
  UpdateCalendarStateDetails();
  final bool showWeekNumber;
  final bool isMobilePlatform;

  @override
  void paint(Canvas canvas, Size size) {
    selectionDecoration ??= BoxDecoration(
      color: Colors.transparent,
      border: Border.all(color: calendarTheme.selectionBorderColor!, width: 2),
      borderRadius: const BorderRadius.all(Radius.circular(2)),
    );

    getCalendarState(_updateCalendarStateDetails);
    selectedDate = _updateCalendarStateDetails.selectedDate;
    final bool isDayView = CalendarViewHelper.isDayView(
        view,
        calendar.timeSlotViewSettings.numberOfDaysInView,
        calendar.timeSlotViewSettings.nonWorkingDays,
        calendar.monthViewSettings.numberOfWeeksInView);
    final bool isMonthView =
        view == CalendarView.month || view == CalendarView.timelineMonth;
    final int timeInterval =
    CalendarViewHelper.getTimeInterval(calendar.timeSlotViewSettings);
    if (selectedDate != null &&
        ((isMonthView &&
            !isDateWithInDateRange(
                calendar.minDate, calendar.maxDate, selectedDate)) ||
            (!isMonthView &&
                !CalendarViewHelper.isDateTimeWithInDateTimeRange(
                    calendar.minDate,
                    calendar.maxDate,
                    selectedDate!,
                    timeInterval)))) {
      return;
    }
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final double timeLabelWidth = CalendarViewHelper.getTimeLabelWidth(
        calendar.timeSlotViewSettings.timeRulerSize, view);
    double width = size.width;
    final bool isTimeline = CalendarViewHelper.isTimelineView(view);
    if (view != CalendarView.month && !isTimeline) {
      width -= timeLabelWidth;
    }

    final bool isResourceEnabled = isTimeline &&
        CalendarViewHelper.isResourceEnabled(calendar.dataSource, view);
    if ((selectedDate == null && appointmentView == null) ||
        visibleDates != _updateCalendarStateDetails.currentViewVisibleDates ||
        (isResourceEnabled && selectedResourceIndex == -1)) {
      return;
    }

    if (!isTimeline) {
      if (view == CalendarView.month) {
        _cellWidth = width / DateTime.daysPerWeek;
        _cellHeight =
            size.height / calendar.monthViewSettings.numberOfWeeksInView;
      } else {
        _cellWidth = width / visibleDates.length;
        _cellHeight = timeIntervalHeight;
      }
    } else {
      _cellWidth = timeIntervalHeight;
      _cellHeight = size.height;

      /// The selection view must render on the resource area alone, when the
      /// resource enabled.
      if (isResourceEnabled && selectedResourceIndex >= 0) {
        _cellHeight = resourceItemHeight!;
      }
    }

    if (appointmentView != null && appointmentView!.appointment != null) {
      _drawAppointmentSelection(canvas);
    }

    switch (view) {
      case CalendarView.schedule:
        return;
      case CalendarView.month:
        {
          if (selectedDate != null) {
            _drawMonthSelection(canvas, size, width);
          }
        }
        break;
      case CalendarView.day:
      case CalendarView.week:
      case CalendarView.workWeek:
        {
          if (selectedDate != null) {
            if (isDayView) {
              _drawDaySelection(canvas, size, width, timeLabelWidth);
            } else {
              _drawWeekSelection(canvas, size, timeLabelWidth, width);
            }
          }
        }
        break;
      case CalendarView.timelineDay:
      case CalendarView.timelineWeek:
      case CalendarView.timelineWorkWeek:
        {
          if (selectedDate != null) {
            _drawTimelineWeekSelection(canvas, size, width);
          }
        }
        break;
      case CalendarView.timelineMonth:
        {
          if (selectedDate != null) {
            _drawTimelineMonthSelection(canvas, size, width);
          }
        }
    }
  }

  @override
  bool? hitTest(Offset position) {
    return false;
  }

  void _drawMonthSelection(Canvas canvas, Size size, double width) {
    final int visibleDatesLength = visibleDates.length;
    if (!isDateWithInDateRange(
        visibleDates[0], visibleDates[visibleDatesLength - 1], selectedDate)) {
      return;
    }

    final int currentMonth = visibleDates[visibleDatesLength ~/ 2].month;

    /// Check the selected cell date as trailing or leading date when
    /// [SfCalendar] month not shown leading and trailing dates.
    if (!CalendarViewHelper.isCurrentMonthDate(
        calendar.monthViewSettings.numberOfWeeksInView,
        calendar.monthViewSettings.showTrailingAndLeadingDates,
        currentMonth,
        selectedDate!)) {
      return;
    }

    if (CalendarViewHelper.isDateInDateCollection(
        calendar.blackoutDates, selectedDate!)) {
      return;
    }

    for (int i = 0; i < visibleDatesLength; i++) {
      if (isSameDate(visibleDates[i], selectedDate)) {
        final double weekNumberPanelWidth =
        CalendarViewHelper.getWeekNumberPanelWidth(
            showWeekNumber, width, isMobilePlatform);
        _cellWidth = (size.width - weekNumberPanelWidth) / DateTime.daysPerWeek;
        final int columnIndex = (i / DateTime.daysPerWeek).truncate();
        _yPosition = columnIndex * _cellHeight;
        final int rowIndex = i % DateTime.daysPerWeek;
        if (isRTL) {
          _xPosition = (DateTime.daysPerWeek - 1 - rowIndex) * _cellWidth;
        } else {
          _xPosition = rowIndex * _cellWidth + weekNumberPanelWidth;
        }
        _drawSlotSelection(width, size.height, canvas);
        break;
      }
    }
  }

  void _drawDaySelection(
      Canvas canvas, Size size, double width, double timeLabelWidth) {
    if (isSameDate(visibleDates[0], selectedDate)) {
      if (isRTL) {
        _xPosition = 0;
      } else {
        _xPosition = timeLabelWidth;
      }

      selectedDate = _updateSelectedDate();

      _yPosition = AppointmentHelper.timeToPosition(
          calendar, selectedDate!, timeIntervalHeight);
      _drawSlotSelection(width + timeLabelWidth, size.height, canvas);
    }
  }

  /// Method to update the selected date, when the selected date not fill the
  /// exact time slot, and render the mid of time slot, on this scenario we
  /// have updated the selected date to update the exact time slot.
  ///
  /// Eg: If the time interval is 60min, and the selected date is 12.45 PM the
  /// selection renders on the center of 12 to 1 PM slot, to avoid this we have
  /// modified the selected date to 1 PM so that the selection will render the
  /// exact time slot.
  DateTime _updateSelectedDate() {
    final int timeInterval =
    CalendarViewHelper.getTimeInterval(calendar.timeSlotViewSettings);
    final int startHour = calendar.timeSlotViewSettings.startHour.toInt();
    final double startMinute = (calendar.timeSlotViewSettings.startHour -
        calendar.timeSlotViewSettings.startHour.toInt()) *
        60;
    final int selectedMinutes = ((selectedDate!.hour - startHour) * 60) +
        (selectedDate!.minute - startMinute.toInt());
    if (selectedMinutes % timeInterval != 0) {
      final int diff = selectedMinutes % timeInterval;
      if (diff < (timeInterval / 2)) {
        return selectedDate!.subtract(Duration(minutes: diff));
      } else {
        return selectedDate!.add(Duration(minutes: timeInterval - diff));
      }
    }

    return selectedDate!;
  }

  void _drawWeekSelection(
      Canvas canvas, Size size, double timeLabelWidth, double width) {
    final int visibleDatesLength = visibleDates.length;
    if (isDateWithInDateRange(
        visibleDates[0], visibleDates[visibleDatesLength - 1], selectedDate)) {
      for (int i = 0; i < visibleDatesLength; i++) {
        if (isSameDate(selectedDate, visibleDates[i])) {
          final int rowIndex = i;
          if (isRTL) {
            _xPosition = _cellWidth * (visibleDatesLength - 1 - rowIndex);
          } else {
            _xPosition = timeLabelWidth + _cellWidth * rowIndex;
          }

          selectedDate = _updateSelectedDate();
          _yPosition = AppointmentHelper.timeToPosition(
              calendar, selectedDate!, timeIntervalHeight);
          _drawSlotSelection(width + timeLabelWidth, size.height, canvas);
          break;
        }
      }
    }
  }

  /// Returns the yPosition for selection view based on resource associated with
  /// the selected cell in  timeline views when resource enabled.
  double _getTimelineYPosition() {
    if (selectedResourceIndex == -1) {
      return 0;
    }

    return selectedResourceIndex * resourceItemHeight!;
  }

  void _drawTimelineMonthSelection(Canvas canvas, Size size, double width) {
    if (!isDateWithInDateRange(
        visibleDates[0], visibleDates[visibleDates.length - 1], selectedDate)) {
      return;
    }

    if (CalendarViewHelper.isDateInDateCollection(
        calendar.blackoutDates, selectedDate!)) {
      return;
    }

    for (int i = 0; i < visibleDates.length; i++) {
      if (isSameDate(visibleDates[i], selectedDate)) {
        _yPosition = _getTimelineYPosition();
        _xPosition =
        isRTL ? size.width - ((i + 1) * _cellWidth) : i * _cellWidth;
        final double height = selectedResourceIndex == -1
            ? size.height
            : _yPosition + resourceItemHeight!;
        _drawSlotSelection(width, height, canvas);
        break;
      }
    }
  }

  void _drawTimelineWeekSelection(Canvas canvas, Size size, double width) {
    if (isDateWithInDateRange(
        visibleDates[0], visibleDates[visibleDates.length - 1], selectedDate)) {
      selectedDate = _updateSelectedDate();
      for (int i = 0; i < visibleDates.length; i++) {
        if (isSameDate(selectedDate, visibleDates[i])) {
          final double singleViewWidth = width / visibleDates.length;
          _xPosition = (i * singleViewWidth) +
              AppointmentHelper.timeToPosition(
                  calendar, selectedDate!, timeIntervalHeight);
          if (isRTL) {
            _xPosition = size.width - _xPosition - _cellWidth;
          }
          _yPosition = _getTimelineYPosition();
          final double height = selectedResourceIndex == -1
              ? size.height
              : _yPosition + resourceItemHeight!;
          _drawSlotSelection(width, height, canvas);
          break;
        }
      }
    }
  }

  void _drawAppointmentSelection(Canvas canvas) {
    Rect rect = appointmentView!.appointmentRect!.outerRect;
    rect = Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom);
    _boxPainter = selectionDecoration!
        .createBoxPainter(_updateSelectionDecorationPainter);
    _boxPainter.paint(canvas, Offset(rect.left, rect.top),
        ImageConfiguration(size: rect.size));
  }

  /// Used to pass the argument of create box painter and it is called when
  /// decoration have asynchronous data like image.
  void _updateSelectionDecorationPainter() {
    repaintNotifier.value = !repaintNotifier.value;
  }

  void _drawSlotSelection(double width, double height, Canvas canvas) {
    //// padding used to avoid first, last row and column selection clipping.
    const double padding = 0.5;
    final Rect rect = Rect.fromLTRB(
        _xPosition == 0 ? _xPosition + padding : _xPosition,
        _yPosition == 0 ? _yPosition + padding : _yPosition,
        _xPosition + _cellWidth == width
            ? _xPosition + _cellWidth - padding
            : _xPosition + _cellWidth,
        _yPosition + _cellHeight == height
            ? _yPosition + _cellHeight - padding
            : _yPosition + _cellHeight);

    _boxPainter = selectionDecoration!
        .createBoxPainter(_updateSelectionDecorationPainter);
    _boxPainter.paint(canvas, Offset(rect.left, rect.top),
        ImageConfiguration(size: rect.size, textDirection: TextDirection.ltr));
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) {
    final SelectionPainter oldWidget = oldDelegate;
    return oldWidget.selectionDecoration != selectionDecoration ||
        oldWidget.selectedDate != selectedDate ||
        oldWidget.view != view ||
        oldWidget.visibleDates != visibleDates ||
        oldWidget.selectedResourceIndex != selectedResourceIndex ||
        oldWidget.isRTL != isRTL;
  }
}
