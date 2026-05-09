class NoteMetaData {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String previewText;
  final double height;

  const NoteMetaData({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.previewText,
    required this.height,
  });
}
