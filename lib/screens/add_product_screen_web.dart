// Web implementation for picking images using dart:html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

void pickWebImageStub(Function(Uint8List, String) onImagePicked) {
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*';
  uploadInput.click();
  uploadInput.onChange.listen((event) {
    final file = uploadInput.files?.first;
    if (file != null) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        onImagePicked(reader.result as Uint8List, file.name);
      });
    }
  });
} 