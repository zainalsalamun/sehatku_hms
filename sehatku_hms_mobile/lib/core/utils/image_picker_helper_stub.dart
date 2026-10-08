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
  return null;
}
