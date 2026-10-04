/// Lightweight complaint model for the mobile app (Phase 0 — static/mock data).
class ComplaintModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String status; // 'Open', 'In Progress', 'Closed'
  final DateTime createdAt;
  final String? imageAsset; // Optional local asset path for mock image.
  final List<ComplaintStatusEntry> statusHistory;

  const ComplaintModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.createdAt,
    this.imageAsset,
    this.statusHistory = const [],
  });
}

class ComplaintStatusEntry {
  final String status;
  final DateTime timestamp;
  final String note;

  const ComplaintStatusEntry({
    required this.status,
    required this.timestamp,
    required this.note,
  });
}
