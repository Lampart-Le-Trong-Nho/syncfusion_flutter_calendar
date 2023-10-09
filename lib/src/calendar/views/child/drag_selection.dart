import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:syncfusion_flutter_calendar/src/calendar/views/child/drag_appointment.dart';
import 'package:syncfusion_flutter_core/theme.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_calendar/src/calendar/common/calendar_view_helper.dart';

@immutable
class DraggingSelectionWidget extends StatefulWidget {
  const DraggingSelectionWidget(
      this.dragDetails,
      this.isRTL,
      this.textScaleFactor,
      this.isMobilePlatform,
      this.appointmentTextStyle,
      this.dragAndDropSettings,
      this.calendarView,
      this.allDayPanelHeight,
      this.viewHeaderHeight,
      this.timeLabelWidth,
      this.resourceItemHeight,
      this.calendarTheme,
      this.calendar,
      this.width,
      this.height);

  final ValueNotifier<DragPaintDetails> dragDetails;

  final bool isRTL;

  final double textScaleFactor;

  final bool isMobilePlatform;

  final TextStyle appointmentTextStyle;

  final DragAndDropSettings dragAndDropSettings;

  final CalendarView calendarView;

  final double allDayPanelHeight;

  final double viewHeaderHeight;

  final double timeLabelWidth;

  final double resourceItemHeight;

  final SfCalendarThemeData calendarTheme;

  final SfCalendar calendar;

  final double width;

  final double height;

  @override
  _DraggingSelectionState createState() => _DraggingSelectionState();
}

class _DraggingSelectionState extends State<DraggingSelectionWidget> {
  AppointmentView? _DraggingSelectionView;

  @override
  void initState() {
    _DraggingSelectionView = widget.dragDetails.value.appointmentView;
    widget.dragDetails.value.position.addListener(_updateDraggingSelection);
    super.initState();
  }

  @override
  void dispose() {
    widget.dragDetails.value.position
        .removeListener(_updateDraggingSelection);
    super.dispose();
  }

  void _updateDraggingSelection() {
    if (_DraggingSelectionView != widget.dragDetails.value.appointmentView) {
      _DraggingSelectionView = widget.dragDetails.value.appointmentView;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? child;
    if (widget.dragDetails.value.appointmentView != null &&
        widget.calendar.appointmentBuilder != null) {
      final DateTime date = DateTime(
          _DraggingSelectionView!.appointment!.actualStartTime.year,
          _DraggingSelectionView!.appointment!.actualStartTime.month,
          _DraggingSelectionView!.appointment!.actualStartTime.day);

      child = widget.calendar.appointmentBuilder!(
          context,
          CalendarAppointmentDetails(
              date,
              List<dynamic>.unmodifiable(<dynamic>[
                CalendarViewHelper.getAppointmentDetail(
                    _DraggingSelectionView!.appointment!,
                    widget.calendar.dataSource)
              ]),
              Rect.fromLTWH(
                  widget.dragDetails.value.position.value!.dx,
                  widget.dragDetails.value.position.value!.dy,
                  widget.isRTL
                      ? -_DraggingSelectionView!.appointmentRect!.width
                      : _DraggingSelectionView!.appointmentRect!.width,
                  _DraggingSelectionView!.appointmentRect!.height)));
    }

    return _DraggingSelectionRenderObjectWidget(
      widget.dragDetails.value,
      widget.isRTL,
      widget.textScaleFactor,
      widget.isMobilePlatform,
      widget.appointmentTextStyle,
      widget.dragAndDropSettings,
      widget.calendarView,
      widget.allDayPanelHeight,
      widget.viewHeaderHeight,
      widget.timeLabelWidth,
      widget.resourceItemHeight,
      widget.calendarTheme,
      widget.width,
      widget.height,
      child: child,
    );
  }
}

@immutable
class _DraggingSelectionRenderObjectWidget
    extends SingleChildRenderObjectWidget {
  const _DraggingSelectionRenderObjectWidget(
      this.dragDetails,
      this.isRTL,
      this.textScaleFactor,
      this.isMobilePlatform,
      this.appointmentTextStyle,
      this.dragAndDropSettings,
      this.calendarView,
      this.allDayPanelHeight,
      this.viewHeaderHeight,
      this.timeLabelWidth,
      this.resourceItemHeight,
      this.calendarTheme,
      this.width,
      this.height,
      {Widget? child})
      : super(child: child);
  final DragPaintDetails dragDetails;

  final bool isRTL;

  final double textScaleFactor;

  final bool isMobilePlatform;

  final TextStyle appointmentTextStyle;

  final DragAndDropSettings dragAndDropSettings;

  final CalendarView calendarView;

  final double allDayPanelHeight;

  final double viewHeaderHeight;

  final double timeLabelWidth;

  final double resourceItemHeight;

  final SfCalendarThemeData calendarTheme;

  final double width;

  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _DraggingSelectionRenderObject(
        dragDetails,
        isRTL,
        textScaleFactor,
        isMobilePlatform,
        appointmentTextStyle,
        dragAndDropSettings,
        calendarView,
        allDayPanelHeight,
        viewHeaderHeight,
        timeLabelWidth,
        resourceItemHeight,
        calendarTheme,
        width,
        height);
  }

  @override
  void updateRenderObject(
      BuildContext context, _DraggingSelectionRenderObject renderObject) {
    renderObject
      ..dragDetails = dragDetails
      ..isRTL = isRTL
      ..textScaleFactor = textScaleFactor
      ..isMobilePlatform = isMobilePlatform
      ..appointmentTextStyle = appointmentTextStyle
      ..dragAndDropSettings = dragAndDropSettings
      ..calendarView = calendarView
      ..allDayPanelHeight = allDayPanelHeight
      ..viewHeaderHeight = viewHeaderHeight
      ..timeLabelWidth = timeLabelWidth
      ..resourceItemHeight = resourceItemHeight
      ..calendarTheme = calendarTheme
      ..width = width
      ..height = height;
  }
}

class _DraggingSelectionRenderObject extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _DraggingSelectionRenderObject(
      this._dragDetails,
      this._isRTL,
      this._textScaleFactor,
      this._isMobilePlatform,
      this._appointmentTextStyle,
      this._dragAndDropSettings,
      this._calendarView,
      this._allDayPanelHeight,
      this._viewHeaderHeight,
      this._timeLabelWidth,
      this._resourceItemHeight,
      this._calendarTheme,
      this._width,
      this._height);

  double _width;

  double get width => _width;

  set width(double value) {
    if (_width == value) {
      return;
    }

    _width = value;
    if (child != null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  double _height;

  double get height => _height;

  set height(double value) {
    if (_height == value) {
      return;
    }

    _height = value;
    if (child != null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  DragPaintDetails _dragDetails;

  DragPaintDetails get dragDetails => _dragDetails;

  set dragDetails(DragPaintDetails value) {
    if (_dragDetails == value) {
      return;
    }

    _dragDetails.position.removeListener(markNeedsPaint);
    _dragDetails = value;
    _dragDetails.position.addListener(markNeedsPaint);
    if (child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  bool _isRTL;

  bool get isRTL => _isRTL;

  set isRTL(bool value) {
    if (_isRTL == value) {
      return;
    }

    _isRTL = value;
    if (child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  double _textScaleFactor;

  double get textScaleFactor => _textScaleFactor;

  set textScaleFactor(double value) {
    if (_textScaleFactor == value) {
      return;
    }

    _textScaleFactor = value;
    markNeedsPaint();
  }

  bool _isMobilePlatform;

  bool get isMobilePlatform => _isMobilePlatform;

  set isMobilePlatform(bool value) {
    if (_isMobilePlatform == value) {
      return;
    }

    _isMobilePlatform = value;
    if (child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  TextStyle _appointmentTextStyle;

  TextStyle get appointmentTextStyle => _appointmentTextStyle;

  set appointmentTextStyle(TextStyle value) {
    if (_appointmentTextStyle == value) {
      return;
    }

    _appointmentTextStyle = value;
    if (child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  DragAndDropSettings _dragAndDropSettings;

  DragAndDropSettings get dragAndDropSettings => _dragAndDropSettings;

  set dragAndDropSettings(DragAndDropSettings value) {
    if (_dragAndDropSettings == value) {
      return;
    }

    _dragAndDropSettings = value;
    if (child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  CalendarView _calendarView;

  CalendarView get calendarView => _calendarView;

  set calendarView(CalendarView value) {
    if (_calendarView == value) {
      return;
    }

    _calendarView = value;
    if (child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  double _allDayPanelHeight;

  double get allDayPanelHeight => _allDayPanelHeight;

  set allDayPanelHeight(double value) {
    if (_allDayPanelHeight == value) {
      return;
    }

    _allDayPanelHeight = value;
    if (child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  double _viewHeaderHeight;

  double get viewHeaderHeight => _viewHeaderHeight;

  set viewHeaderHeight(double value) {
    if (_viewHeaderHeight == value) {
      return;
    }

    _viewHeaderHeight = value;
    if (child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  double _timeLabelWidth;

  double get timeLabelWidth => _timeLabelWidth;

  set timeLabelWidth(double value) {
    if (_timeLabelWidth == value) {
      return;
    }

    _timeLabelWidth = value;
    if (child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  double _resourceItemHeight;

  double get resourceItemHeight => _resourceItemHeight;

  set resourceItemHeight(double value) {
    if (_resourceItemHeight == value) {
      return;
    }

    _resourceItemHeight = value;
    if (child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  SfCalendarThemeData _calendarTheme;

  SfCalendarThemeData get calendarTheme => _calendarTheme;

  set calendarTheme(SfCalendarThemeData value) {
    if (_calendarTheme == value) {
      return;
    }

    _calendarTheme = value;
    if (child == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _dragDetails.position.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _dragDetails.position.removeListener(markNeedsPaint);
    super.detach();
  }

  final Paint _shadowPainter = Paint();

  final TextPainter _textPainter = TextPainter();

  @override
  void performLayout() {
    final Size widgetSize = constraints.biggest;
    size = Size(widgetSize.width.isInfinite ? width : widgetSize.width,
        widgetSize.height.isInfinite ? height : widgetSize.height);

    child?.layout(constraints.copyWith(
        minWidth: dragDetails.appointmentView!.appointmentRect!.width,
        minHeight: dragDetails.appointmentView!.appointmentRect!.height,
        maxWidth: dragDetails.appointmentView!.appointmentRect!.width,
        maxHeight: dragDetails.appointmentView!.appointmentRect!.height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final bool isTimelineView = CalendarViewHelper.isTimelineView(calendarView);
    if (child == null) {
      _drawDefaultUI(context.canvas, isTimelineView);
    } else {
      context.paintChild(
          child!,
          Offset(
              isRTL
                  ? dragDetails.position.value!.dx -
                  dragDetails.appointmentView!.appointmentRect!.width
                  : dragDetails.position.value!.dx,
              dragDetails.position.value!.dy));
      if (dragAndDropSettings.showTimeIndicator &&
          dragDetails.draggingTime != null) {
        _drawTimeIndicator(context.canvas, isTimelineView, size);
      }
    }
  }

  void _drawDefaultUI(Canvas canvas, bool isTimelineView) {
    if (dragDetails.appointmentView == null ||
        dragDetails.appointmentView!.appointmentRect == null) {
      return;
    }

    const int textStartPadding = 3;
    double xPosition;
    double yPosition;
    xPosition = dragDetails.position.value!.dx;
    yPosition = dragDetails.position.value!.dy;
    _shadowPainter.color =
        dragDetails.appointmentView!.appointment!.color.withOpacity(0.5);

    final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            dragDetails.position.value!.dx,
            dragDetails.position.value!.dy,
            isRTL
                ? -dragDetails.appointmentView!.appointmentRect!.width
                : dragDetails.appointmentView!.appointmentRect!.width,
            dragDetails.appointmentView!.appointmentRect!.height),
        dragDetails.appointmentView!.appointmentRect!.tlRadius);
    final Path path = Path();
    path.addRRect(rect);
    canvas.drawPath(path, _shadowPainter);
    canvas.drawShadow(path, _shadowPainter.color, 0.1, true);
    final TextSpan span = TextSpan(
      text: dragDetails.appointmentView!.appointment!.subject,
      style: appointmentTextStyle,
    );

    _textPainter.text = span;
    _textPainter.maxLines = 1;
    _textPainter.textDirection = TextDirection.ltr;
    _textPainter.textAlign = isRTL ? TextAlign.right : TextAlign.left;
    _textPainter.textWidthBasis = TextWidthBasis.longestLine;
    _textPainter.textScaleFactor = textScaleFactor;
    double maxTextWidth =
        dragDetails.appointmentView!.appointmentRect!.width - textStartPadding;
    maxTextWidth = maxTextWidth > 0 ? maxTextWidth : 0;
    _textPainter.layout(maxWidth: maxTextWidth);

    if (isRTL) {
      xPosition -= textStartPadding + _textPainter.width;
    }

    final double totalHeight =
        dragDetails.appointmentView!.appointmentRect!.height - textStartPadding;
    _updatePainterMaxLines(totalHeight);

    maxTextWidth =
        dragDetails.appointmentView!.appointmentRect!.width - textStartPadding;
    maxTextWidth = maxTextWidth > 0 ? maxTextWidth : 0;
    _textPainter.layout(maxWidth: maxTextWidth);

    _textPainter.paint(
        canvas,
        isTimelineView
            ? Offset(xPosition + (isRTL ? 0 : textStartPadding),
            yPosition + textStartPadding)
            : Offset(xPosition + (isRTL ? 0 : textStartPadding),
            yPosition + textStartPadding));
    if (dragAndDropSettings.showTimeIndicator &&
        dragDetails.draggingTime != null) {
      _drawTimeIndicator(canvas, isTimelineView, size);
    }
  }

  void _drawTimeIndicator(Canvas canvas, bool isTimelineView, Size size) {
    if (calendarView == CalendarView.month ||
        calendarView == CalendarView.timelineMonth) {
      return;
    }

    final TextSpan span = TextSpan(
      text: DateFormat(dragAndDropSettings.indicatorTimeFormat)
          .format(dragDetails.draggingTime!),
      style: calendarTheme.timeIndicatorTextStyle,
    );
    _textPainter.text = span;
    _textPainter.maxLines = 1;
    _textPainter.textDirection = TextDirection.ltr;
    _textPainter.textAlign = isRTL ? TextAlign.right : TextAlign.left;
    _textPainter.textWidthBasis = TextWidthBasis.longestLine;
    _textPainter.textScaleFactor = textScaleFactor;
    final double timeLabelSize =
    isTimelineView ? dragDetails.timeIntervalHeight! : timeLabelWidth;
    _textPainter.layout(maxWidth: timeLabelSize);
    double xPosition;
    double yPosition;
    if (isTimelineView) {
      yPosition = viewHeaderHeight + (timeLabelWidth - _textPainter.height);
      xPosition = dragDetails.position.value!.dx;
      if (isRTL) {
        xPosition -= _textPainter.width;
      }
    } else {
      yPosition = dragDetails.position.value!.dy;
      xPosition = (timeLabelSize - _textPainter.width) / 2;
      if (isRTL) {
        xPosition = (size.width - timeLabelSize) + xPosition;
      }
    }
    _textPainter.paint(canvas, Offset(xPosition, yPosition));
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