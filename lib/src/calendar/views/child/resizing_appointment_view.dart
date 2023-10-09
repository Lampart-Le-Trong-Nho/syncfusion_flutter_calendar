import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:syncfusion_flutter_core/theme.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/appointment_engine/appointment_helper.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/common/calendar_view_helper.dart';

class ResizingAppointmentPainter extends CustomPainter {
  ResizingAppointmentPainter(
      this.resizingDetails,
      this.isRTL,
      this.textScaleFactor,
      this.isMobilePlatform,
      this.appointmentTextStyle,
      this.allDayHeight,
      this.viewHeaderHeight,
      this.timeLabelWidth,
      this.timeIntervalHeight,
      this.scrollController,
      this.dragAndDropSettings,
      this.view,
      this.mouseCursor,
      this.weekNumberPanelWidth,
      this.calendarTheme)
      : super(repaint: resizingDetails.value.position);

  final ValueNotifier<ResizingPaintDetails> resizingDetails;

  final bool isRTL;

  final double textScaleFactor;

  final bool isMobilePlatform;

  final TextStyle appointmentTextStyle;

  final double allDayHeight;

  final double viewHeaderHeight;

  final ScrollController? scrollController;

  final CalendarView view;

  final double weekNumberPanelWidth;

  final SystemMouseCursor mouseCursor;

  final SfCalendarThemeData calendarTheme;

  final DragAndDropSettings dragAndDropSettings;

  final double timeLabelWidth;

  final double timeIntervalHeight;

  final Paint _shadowPainter = Paint();
  final TextPainter _textPainter = TextPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (resizingDetails.value.appointmentView == null ||
        resizingDetails.value.appointmentView!.appointmentRect == null) {
      return;
    }
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final double scrollOffset =
    view == CalendarView.month || resizingDetails.value.isAllDayPanel
        ? 0
        : resizingDetails.value.scrollPosition ?? scrollController!.offset;

    final bool isForwardResize = mouseCursor == SystemMouseCursors.resizeDown ||
        mouseCursor == SystemMouseCursors.resizeRight;
    final bool isBackwardResize = mouseCursor == SystemMouseCursors.resizeUp ||
        mouseCursor == SystemMouseCursors.resizeLeft;

    const int textStartPadding = 3;
    double xPosition = resizingDetails.value.position.value!.dx;
    double yPosition = resizingDetails.value.position.value!.dy;

    _shadowPainter.color = resizingDetails.value.appointmentColor;
    final bool isTimelineView = CalendarViewHelper.isTimelineView(view);

    final bool isHorizontalResize = resizingDetails.value.isAllDayPanel ||
        isTimelineView ||
        view == CalendarView.month;
    double left = resizingDetails.value.position.value!.dx,
        top = resizingDetails.value.appointmentView!.appointmentRect!.top,
        right = resizingDetails.value.appointmentView!.appointmentRect!.right,
        bottom = resizingDetails.value.appointmentView!.appointmentRect!.bottom;

    bool canUpdateSubjectPosition = true;
    late Rect rect;
    if (resizingDetails.value.monthRowCount != 0 &&
        view == CalendarView.month) {
      final int lastRow = resizingDetails.value.monthRowCount;
      for (int i = lastRow; i >= 0; i--) {
        if (i == 0) {
          if (isBackwardResize) {
            left = isRTL ? 0 : weekNumberPanelWidth;
            right =
                resizingDetails.value.appointmentView!.appointmentRect!.right;
            if (isRTL) {
              top -= resizingDetails.value.monthCellHeight!;
              xPosition = right;
              yPosition = top;
            } else {
              top += resizingDetails.value.monthCellHeight!;
            }
          } else {
            left = resizingDetails.value.appointmentView!.appointmentRect!.left;
            right = isRTL ? size.width - weekNumberPanelWidth : size.width;
            if (isRTL) {
              top += resizingDetails.value.monthCellHeight!;
            } else {
              top -= resizingDetails.value.monthCellHeight!;
            }

            if (!isRTL) {
              xPosition = left;
              yPosition = top;
            }
          }
        } else if (i == lastRow) {
          if (isBackwardResize) {
            left = resizingDetails.value.position.value!.dx;
            right = isRTL ? size.width - weekNumberPanelWidth : size.width;
            xPosition = left;
            yPosition = resizingDetails.value.position.value!.dy;
          } else {
            right = resizingDetails.value.position.value!.dx;
            left = isRTL ? 0 : weekNumberPanelWidth;
            if (!isRTL) {
              xPosition = right;
              yPosition = top;
            }
          }
          top = resizingDetails.value.position.value!.dy;
        } else {
          left = isRTL ? 0 : weekNumberPanelWidth;
          if (isForwardResize) {
            if (isRTL) {
              top += resizingDetails.value.monthCellHeight!;
            } else {
              top -= resizingDetails.value.monthCellHeight!;
            }
          } else {
            if (isRTL) {
              top -= resizingDetails.value.monthCellHeight!;
            } else {
              top += resizingDetails.value.monthCellHeight!;
            }
          }
          right = isRTL ? size.width : size.width - weekNumberPanelWidth;
        }

        bottom = top +
            resizingDetails.value.appointmentView!.appointmentRect!.height;
        rect = Rect.fromLTRB(left, top, right, bottom);
        canvas.drawRect(rect, _shadowPainter);
        paintBorder(canvas, rect,
            left: BorderSide(
                color: calendarTheme.selectionBorderColor!, width: 2),
            right: BorderSide(
                color: calendarTheme.selectionBorderColor!, width: 2),
            bottom: BorderSide(
                color: calendarTheme.selectionBorderColor!, width: 2),
            top: BorderSide(
                color: calendarTheme.selectionBorderColor!, width: 2));
      }
    } else {
      if (isForwardResize) {
        if (isHorizontalResize) {
          if (resizingDetails.value.isAllDayPanel ||
              view == CalendarView.month) {
            left = resizingDetails.value.appointmentView!.appointmentRect!.left;
          } else if (isTimelineView) {
            left =
                resizingDetails.value.appointmentView!.appointmentRect!.left -
                    scrollOffset;
            if (isRTL) {
              left =
                  scrollOffset + scrollController!.position.viewportDimension;
              left = left -
                  ((scrollController!.position.viewportDimension +
                      scrollController!.position.maxScrollExtent) -
                      resizingDetails
                          .value.appointmentView!.appointmentRect!.left);
            }
          }
          right = resizingDetails.value.position.value!.dx;
          top = resizingDetails.value.position.value!.dy;
          bottom = top +
              resizingDetails.value.appointmentView!.appointmentRect!.height;
        } else {
          top = resizingDetails.value.appointmentView!.appointmentRect!.top -
              scrollOffset +
              allDayHeight +
              viewHeaderHeight;
          bottom = resizingDetails.value.position.value!.dy;
          if (top < viewHeaderHeight + allDayHeight) {
            top = viewHeaderHeight + allDayHeight;
            canUpdateSubjectPosition = false;
          }
          bottom = bottom > size.height ? size.height : bottom;
        }

        xPosition = isRTL ? right : left;
      } else {
        if (isHorizontalResize) {
          if (resizingDetails.value.isAllDayPanel ||
              view == CalendarView.month) {
            right =
                resizingDetails.value.appointmentView!.appointmentRect!.right;
          } else if (isTimelineView) {
            right =
                resizingDetails.value.appointmentView!.appointmentRect!.right -
                    scrollOffset;
            if (isRTL) {
              right =
                  scrollOffset + scrollController!.position.viewportDimension;
              right = right -
                  ((scrollController!.position.viewportDimension +
                      scrollController!.position.maxScrollExtent) -
                      resizingDetails
                          .value.appointmentView!.appointmentRect!.right);
            }
          }

          left = resizingDetails.value.position.value!.dx;
          top = resizingDetails.value.position.value!.dy;
          bottom = top +
              resizingDetails.value.appointmentView!.appointmentRect!.height;
        } else {
          top = resizingDetails.value.position.value!.dy;
          bottom =
              resizingDetails.value.appointmentView!.appointmentRect!.bottom -
                  scrollOffset +
                  allDayHeight +
                  viewHeaderHeight;
          if (top < viewHeaderHeight + allDayHeight) {
            top = viewHeaderHeight + allDayHeight;
          }
          bottom = bottom > size.height ? size.height : bottom;
        }

        xPosition = isRTL ? right : left;
        if (!isHorizontalResize) {
          if (top < viewHeaderHeight + allDayHeight) {
            top = viewHeaderHeight + allDayHeight;
            canUpdateSubjectPosition = false;
          }
          bottom = bottom > size.height ? size.height : bottom;
        }
      }
      rect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(rect, _shadowPainter);
      yPosition = top;
    }
    if (dragAndDropSettings.showTimeIndicator &&
        resizingDetails.value.resizingTime != null) {
      _drawTimeIndicator(canvas, isTimelineView, size, isBackwardResize);
    }

    if (!canUpdateSubjectPosition) {
      return;
    }

    final TextSpan span = TextSpan(
      text: resizingDetails.value.appointmentView!.appointment!.subject,
      style: appointmentTextStyle,
    );

    final bool isRecurrenceAppointment =
        resizingDetails.value.appointmentView!.appointment!.recurrenceRule !=
            null &&
            resizingDetails
                .value.appointmentView!.appointment!.recurrenceRule!.isNotEmpty;

    _updateTextPainter(span);

    if (view != CalendarView.month) {
      _addSubjectTextForTimeslotViews(canvas, textStartPadding, xPosition,
          yPosition, isRecurrenceAppointment, rect);
    } else {
      _addSubjectTextForMonthView(
          canvas,
          resizingDetails.value.appointmentView!.appointmentRect!,
          appointmentTextStyle,
          span,
          isRecurrenceAppointment,
          xPosition,
          rect,
          yPosition);
    }

    paintBorder(canvas, rect,
        left: BorderSide(color: calendarTheme.selectionBorderColor!, width: 2),
        right: BorderSide(color: calendarTheme.selectionBorderColor!, width: 2),
        bottom:
        BorderSide(color: calendarTheme.selectionBorderColor!, width: 2),
        top: BorderSide(color: calendarTheme.selectionBorderColor!, width: 2));
  }

  /// Draw the time indicator when resizing the appointment on all calendar
  /// views except month and timelineMonth views.
  void _drawTimeIndicator(
      Canvas canvas, bool isTimelineView, Size size, bool isBackwardResize) {
    if (view == CalendarView.month || view == CalendarView.timelineMonth) {
      return;
    }

    if (!isTimelineView &&
        resizingDetails.value.position.value!.dy <
            viewHeaderHeight + allDayHeight) {
      return;
    }

    final TextSpan span = TextSpan(
      text: DateFormat(dragAndDropSettings.indicatorTimeFormat)
          .format(resizingDetails.value.resizingTime!),
      style: calendarTheme.timeIndicatorTextStyle,
    );
    _updateTextPainter(span);
    _textPainter.layout(
        maxWidth: isTimelineView ? timeIntervalHeight : timeLabelWidth);
    double xPosition;
    double yPosition;
    if (isTimelineView) {
      yPosition = viewHeaderHeight + (timeLabelWidth - _textPainter.height);
      xPosition = resizingDetails.value.position.value!.dx;
      if (isRTL) {
        xPosition -= _textPainter.width;
        if (isBackwardResize) {
          xPosition += _textPainter.width;
        }
      }
      if (!isBackwardResize && !isRTL) {
        xPosition -= _textPainter.width;
      }
    } else {
      yPosition = resizingDetails.value.position.value!.dy;
      xPosition = (timeLabelWidth - _textPainter.width) / 2;
      if (isRTL) {
        xPosition = (size.width - timeLabelWidth) + xPosition;
      }
    }
    _textPainter.paint(canvas, Offset(xPosition, yPosition));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  void _addSubjectTextForTimeslotViews(
      Canvas canvas,
      int textStartPadding,
      double xPosition,
      double yPosition,
      bool isRecurrenceAppointment,
      Rect rect) {
    final double totalHeight =
        resizingDetails.value.appointmentView!.appointmentRect!.height -
            textStartPadding;
    _updatePainterMaxLines(totalHeight);

    double maxTextWidth =
        resizingDetails.value.appointmentView!.appointmentRect!.width -
            textStartPadding;
    maxTextWidth = maxTextWidth > 0 ? maxTextWidth : 0;
    _textPainter.layout(maxWidth: maxTextWidth);
    if (isRTL) {
      xPosition -= textStartPadding + _textPainter.width;
    }
    _textPainter.paint(
        canvas,
        Offset(xPosition + (isRTL ? 0 : textStartPadding),
            yPosition + textStartPadding));
    if (isRecurrenceAppointment ||
        resizingDetails.value.appointmentView!.appointment!.recurrenceId !=
            null) {
      double textSize = appointmentTextStyle.fontSize!;
      if (rect.width < textSize || rect.height < textSize) {
        textSize = rect.width > rect.height ? rect.height : rect.width;
      }
      _addRecurrenceIcon(
          rect, canvas, textStartPadding, isRecurrenceAppointment, textSize);
    }
  }

  void _addSubjectTextForMonthView(
      Canvas canvas,
      RRect appointmentRect,
      TextStyle style,
      TextSpan span,
      bool isRecurrenceAppointment,
      double xPosition,
      Rect rect,
      double yPosition) {
    double textSize = -1;
    if (textSize == -1) {
      //// left and right side padding value 2 subtracted in appointment width
      double maxTextWidth = appointmentRect.width - 2;
      maxTextWidth = maxTextWidth > 0 ? maxTextWidth : 0;
      for (double j = style.fontSize! - 1; j > 0; j--) {
        _textPainter.layout(maxWidth: maxTextWidth);
        if (_textPainter.height >= appointmentRect.height) {
          style = style.copyWith(fontSize: j);
          span = TextSpan(
              text: resizingDetails.value.appointmentView!.appointment!.subject,
              style: style);
          _updateTextPainter(span);
        } else {
          textSize = j + 1;
          break;
        }
      }
    } else {
      span = TextSpan(
          text: resizingDetails.value.appointmentView!.appointment!.subject,
          style: style.copyWith(fontSize: textSize));
      _updateTextPainter(span);
    }
    final double textWidth =
        appointmentRect.width - (isRecurrenceAppointment ? textSize : 1);
    _textPainter.layout(maxWidth: textWidth > 0 ? textWidth : 0);
    if (isRTL) {
      xPosition -= (isRTL ? 0 : 2) + _textPainter.width;
    }
    yPosition =
        yPosition + ((appointmentRect.height - _textPainter.height) / 2);
    _textPainter.paint(canvas, Offset(xPosition + (isRTL ? 0 : 2), yPosition));

    if (isRecurrenceAppointment ||
        resizingDetails.value.appointmentView!.appointment!.recurrenceId !=
            null) {
      _addRecurrenceIcon(rect, canvas, null, isRecurrenceAppointment, textSize);
    }
  }

  void _updateTextPainter(TextSpan span) {
    _textPainter.text = span;
    _textPainter.maxLines = 1;
    _textPainter.textDirection = TextDirection.ltr;
    _textPainter.textAlign = isRTL ? TextAlign.right : TextAlign.left;
    _textPainter.textWidthBasis = TextWidthBasis.longestLine;
    _textPainter.textScaleFactor = textScaleFactor;
  }

  void _addRecurrenceIcon(Rect rect, Canvas canvas, int? textPadding,
      bool isRecurrenceAppointment, double textSize) {
    const double xPadding = 2;
    const double bottomPadding = 2;

    final TextSpan icon = AppointmentHelper.getRecurrenceIcon(
        appointmentTextStyle.color!, textSize, isRecurrenceAppointment);
    _textPainter.text = icon;

    if (view == CalendarView.month) {
      _textPainter.layout(maxWidth: rect.width + 1 > 0 ? rect.width + 1 : 0);
      final double yPosition =
          rect.top + ((rect.height - _textPainter.height) / 2);
      const double rightPadding = 0;
      final double recurrenceStartPosition = isRTL
          ? rect.left + rightPadding
          : rect.right - _textPainter.width - rightPadding;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(recurrenceStartPosition, yPosition,
                  recurrenceStartPosition + _textPainter.width, rect.bottom),
              resizingDetails.value.appointmentView!.appointmentRect!.tlRadius),
          _shadowPainter);
      _textPainter.paint(canvas, Offset(recurrenceStartPosition, yPosition));
    } else {
      double maxTextWidth =
          resizingDetails.value.appointmentView!.appointmentRect!.width -
              textPadding! -
              2;
      maxTextWidth = maxTextWidth > 0 ? maxTextWidth : 0;
      _textPainter.layout(maxWidth: maxTextWidth);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(
                  isRTL
                      ? rect.left + textSize + xPadding
                      : rect.right - textSize - xPadding,
                  rect.bottom - bottomPadding - textSize,
                  isRTL ? rect.left : rect.right,
                  rect.bottom),
              resizingDetails.value.appointmentView!.appointmentRect!.tlRadius),
          _shadowPainter);
      _textPainter.paint(
          canvas,
          Offset(
              isRTL ? rect.left + xPadding : rect.right - textSize - xPadding,
              rect.bottom - bottomPadding - textSize));
    }
  }

  void _updatePainterMaxLines(double height) {
    /// [preferredLineHeight] is used to get the line height based on text
    /// style and text. floor the calculated value to set the minimum line
    /// count to painter max lines property.
    final int maxLines = (height / _textPainter.preferredLineHeight).floor();
    if (maxLines <= 0) {
      return;
    }

    _textPainter.maxLines = maxLines;
  }
}

class ResizingPaintDetails {
  ResizingPaintDetails(
      // ignore: unused_element
          {this.appointmentView,
        required this.position,
        // ignore: unused_element
        this.isAllDayPanel = false,
        // ignore: unused_element
        this.scrollPosition,
        // ignore: unused_element
        this.monthRowCount = 0,
        // ignore: unused_element
        this.monthCellHeight,
        // ignore: unused_element
        this.appointmentColor = Colors.transparent,
        // ignore: unused_element
        this.resizingTime});

  AppointmentView? appointmentView;
  final ValueNotifier<Offset?> position;
  bool isAllDayPanel;
  double? scrollPosition;
  int monthRowCount;
  double? monthCellHeight;
  Color appointmentColor;
  DateTime? resizingTime;
}