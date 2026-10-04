import '../models/complaint_model.dart';

/// Static mock complaint data for Phase 0.
/// No Firebase / backend integration.
class MockComplaintData {
  MockComplaintData._();

  static final List<ComplaintModel> complaints = [
    ComplaintModel(
      id: 'CMP-001',
      title: 'Fan not working',
      description:
          'The ceiling fan in F06 classroom has stopped working completely. Students are facing difficulty during class due to extreme heat.',
      location: 'F06 Classroom',
      status: 'Open',
      createdAt: DateTime(2026, 10, 4, 10, 30),
      statusHistory: [
        ComplaintStatusEntry(
          status: 'Open',
          timestamp: DateTime(2026, 10, 4, 10, 30),
          note: 'Complaint submitted',
        ),
      ],
    ),
    ComplaintModel(
      id: 'CMP-002',
      title: 'Water leakage',
      description:
          'There is continuous water leakage from the overhead pipe near the staircase in Block A. The floor is wet and poses a safety risk.',
      location: 'Block A',
      status: 'In Progress',
      createdAt: DateTime(2026, 9, 28, 9, 15),
      statusHistory: [
        ComplaintStatusEntry(
          status: 'Open',
          timestamp: DateTime(2026, 9, 28, 9, 15),
          note: 'Complaint submitted',
        ),
        ComplaintStatusEntry(
          status: 'In Progress',
          timestamp: DateTime(2026, 9, 30, 11, 20),
          note: 'Work started by maintenance team',
        ),
      ],
    ),
    ComplaintModel(
      id: 'CMP-003',
      title: 'Light not working',
      description:
          'Two tube lights in the library reading area on the 1st floor are not functioning. Poor lighting is affecting student study sessions.',
      location: 'Library',
      status: 'Closed',
      createdAt: DateTime(2026, 9, 20, 14, 45),
      statusHistory: [
        ComplaintStatusEntry(
          status: 'Open',
          timestamp: DateTime(2026, 9, 20, 14, 45),
          note: 'Complaint submitted',
        ),
        ComplaintStatusEntry(
          status: 'In Progress',
          timestamp: DateTime(2026, 9, 22, 10, 00),
          note: 'Electrician assigned and work in progress',
        ),
        ComplaintStatusEntry(
          status: 'Closed',
          timestamp: DateTime(2026, 9, 23, 16, 30),
          note: 'Lights replaced and issue resolved',
        ),
      ],
    ),
    ComplaintModel(
      id: 'CMP-004',
      title: 'AC not working',
      description:
          'The air conditioning unit in the Computer Lab is not cooling properly. The temperature inside is very high, causing discomfort.',
      location: 'Computer Lab',
      status: 'Open',
      createdAt: DateTime(2026, 10, 2, 8, 00),
      statusHistory: [
        ComplaintStatusEntry(
          status: 'Open',
          timestamp: DateTime(2026, 10, 2, 8, 00),
          note: 'Complaint submitted',
        ),
      ],
    ),
  ];
}
