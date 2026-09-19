/// Where an appointment request has got to.
///
/// The app cannot book on a patient's behalf: there is no integration with any
/// centre's booking system. A request therefore starts as [recorded] — saved in
/// the patient's own record as an intention to attend — and the patient moves it
/// forward once they have actually spoken to the centre.
enum AppointmentStatus { recorded, confirmedWithCentre, attended, cancelled }

extension AppointmentStatusX on AppointmentStatus {
  String get label => switch (this) {
    AppointmentStatus.recorded => 'Saved — centre not yet contacted',
    AppointmentStatus.confirmedWithCentre => 'Confirmed with the centre',
    AppointmentStatus.attended => 'Attended',
    AppointmentStatus.cancelled => 'Cancelled',
  };

  /// True while the patient still has to do something for this to be a real
  /// appointment.
  bool get needsPatientAction => this == AppointmentStatus.recorded;

  String get storageValue => name;

  static AppointmentStatus fromStorage(String? value) =>
      AppointmentStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => AppointmentStatus.recorded,
      );
}

/// A patient's intention to attend a screening or treatment centre
/// (Section F, "Appointment requests").
class AppointmentRequest {
  const AppointmentRequest({
    required this.id,
    required this.patientId,
    required this.centerId,
    required this.centerName,
    required this.centerPhone,
    required this.centerCity,
    required this.requestedDate,
    required this.slot,
    required this.createdAt,
    this.status = AppointmentStatus.recorded,
    this.note,
  });

  final String id;
  final String patientId;

  final String centerId;
  final String centerName;

  /// Kept on the request so the patient can still ring the centre even if the
  /// bundled directory changes later.
  final String centerPhone;
  final String centerCity;

  final DateTime requestedDate;
  final String slot;
  final DateTime createdAt;
  final AppointmentStatus status;
  final String? note;

  bool get isOpen =>
      status == AppointmentStatus.recorded ||
      status == AppointmentStatus.confirmedWithCentre;

  AppointmentRequest copyWith({AppointmentStatus? status, String? note}) =>
      AppointmentRequest(
        id: id,
        patientId: patientId,
        centerId: centerId,
        centerName: centerName,
        centerPhone: centerPhone,
        centerCity: centerCity,
        requestedDate: requestedDate,
        slot: slot,
        createdAt: createdAt,
        status: status ?? this.status,
        note: note ?? this.note,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'patient_id': patientId,
    'center_id': centerId,
    'center_name': centerName,
    'center_phone': centerPhone,
    'center_city': centerCity,
    'requested_date': requestedDate.toIso8601String(),
    'slot': slot,
    'created_at': createdAt.toIso8601String(),
    'status': status.storageValue,
    'note': note,
  };

  factory AppointmentRequest.fromJson(Map<String, Object?> json) =>
      AppointmentRequest(
        id: json['id'] as String? ?? '',
        patientId: json['patient_id'] as String? ?? '',
        centerId: json['center_id'] as String? ?? '',
        centerName: json['center_name'] as String? ?? '',
        centerPhone: json['center_phone'] as String? ?? '',
        centerCity: json['center_city'] as String? ?? '',
        requestedDate:
            DateTime.tryParse(json['requested_date'] as String? ?? '') ??
            DateTime.now(),
        slot: json['slot'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        status: AppointmentStatusX.fromStorage(json['status'] as String?),
        note: json['note'] as String?,
      );
}
