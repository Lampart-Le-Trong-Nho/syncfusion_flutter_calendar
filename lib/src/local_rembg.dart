import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_rembg/src/local_rembg_result_model.dart';

class LocalRembg {
  static const MethodChannel _channel = MethodChannel(
    'methodChannel.localRembg',
  );

  /// Removes the background from the specified image file or image Uint8List.
  /// Returns a [LocalRembgResultModel] representing the result of the operation.
  /// [imagePath] Throws an error if the provided image path ['.png', '.jpg', '.jpeg', '.heic'] is invalid or unsupported.
  /// [imageUint8List] Your image Uint8List.
  static Future<LocalRembgResultModel> removeBackground({
    Uint8List? imageUint8List,
  }) async {
    if (imageUint8List == null) {
      return LocalRembgResultModel(
        status: 0,
        imageBytes: [],
        errorMessage: "Provide either 'imagePath' or 'imageUint8List'.",
      );
    }

    Map<dynamic, dynamic> methodChannelResult = await _channel.invokeMethod(
      'removeBackground',
      {
        'imageUint8List': imageUint8List,
      },
    );
    if (kDebugMode) {
      print(methodChannelResult);
    }
    return LocalRembgResultModel.fromMap(
      methodChannelResult,
    );
  }

  static Future<LocalRembgResultModel> blurBackground(Uint8List imageUint8List) async {
    Map<dynamic, dynamic> methodChannelResult = await _channel.invokeMethod(
      'blurredBackground',
      {
        'imageUint8List': imageUint8List,
      },
    );

    return LocalRembgResultModel.fromMap(
      methodChannelResult,
    );
  }
}
