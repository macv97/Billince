class SharedFile {
  final String id;
  final String name;
  final double sizeMb;
  final String type; // 'pdf', 'jpg', 'png'
  final DateTime dateAdded;
  final String uploadedBy;
  final String? localPath;

  SharedFile({
    required this.id,
    required this.name,
    required this.sizeMb,
    required this.type,
    required this.dateAdded,
    required this.uploadedBy,
    this.localPath,
  });
}
