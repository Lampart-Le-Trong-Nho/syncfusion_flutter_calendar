import 'package:flutter/material.dart';
import '../hex_color.dart';

///
class RangedSlider extends StatelessWidget {
  ///Range Slider widget for strokeWidth
  const RangedSlider({
    required this.value,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  ///Default value of strokewidth.
  final double value;

  /// Callback for value change.
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tBrown,
              inactiveTrackColor: tBrownSecondary,
              thumbColor: tBrown,
            ),
            child: Slider.adaptive(
              max: 40,
              min: 2,
              divisions: 19,
              value: value,
              onChanged: onChanged,
            )),
        SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tBrown,
              inactiveTrackColor: tBrownSecondary,
              thumbColor: tBrown,
            ),
            child: Slider.adaptive(
              max: 40,
              min: 2,
              divisions: 19,
              value: value,
              onChanged: onChanged,
            ))
      ],
    );
  }
}
