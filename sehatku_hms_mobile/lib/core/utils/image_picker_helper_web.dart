// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

class PickedImageData {
  final String name;
  final int size;
  final String dataUrl;

  const PickedImageData({
    required this.name,
    required this.size,
    required this.dataUrl,
  });
}

Future<PickedImageData?> pickImageFromDevice() async {
  final completer = Completer<PickedImageData?>();
  final uploadInput = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/jpg,image/webp'
    ..click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final file = files[0];
    final reader = html.FileReader();

    reader.onLoadEnd.listen((e) {
      final result = reader.result;
      if (result is String) {
        completer.complete(
          PickedImageData(
            name: file.name,
            size: file.size,
            dataUrl: result,
          ),
        );
      } else {
        completer.complete(null);
      }
    });

    reader.onError.listen((e) {
      completer.complete(null);
    });

    reader.readAsDataUrl(file);
  });

  return completer.future;
}
