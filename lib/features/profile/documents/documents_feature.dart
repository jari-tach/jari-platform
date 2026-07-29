import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';

enum DocumentReviewStatus {
  approved,
  underReview,
  rejected,
  expiringSoon,
  expired,
}

enum DocumentType { nationalId, driverLicense, vehicleRegistration, insurance }

enum DocumentEligibilityImpact {
  none,
  blocksAvailability,
  blocksVehicleApproval,
  requiresRenewal,
}

class DocumentViewData {
  const DocumentViewData({
    required this.id,
    required this.type,
    required this.maskedNumber,
    required this.expiryDate,
    required this.status,
    this.issueDate,
    this.rejectionReason,
    this.eligibilityImpact = DocumentEligibilityImpact.none,
  });

  final String id;
  final DocumentType type;
  final String maskedNumber;
  final DateTime? issueDate;
  final DateTime expiryDate;
  final DocumentReviewStatus status;
  final String? rejectionReason;
  final DocumentEligibilityImpact eligibilityImpact;
}

class FakeFileMetadata {
  const FakeFileMetadata({
    required this.name,
    required this.sizeLabel,
    required this.mimeType,
  });

  final String name;
  final String sizeLabel;
  final String mimeType;
}

abstract interface class DocumentsRepository {
  Future<List<DocumentViewData>> listDocuments();
  Future<DocumentViewData?> getById(String id);
  Future<void> uploadDocument({
    required DocumentType type,
    required FakeFileMetadata file,
  });
}

enum FakeDocumentsMode { seeded, empty, error, offline }

class FakeDocumentsRepository implements DocumentsRepository {
  FakeDocumentsRepository({
    this.mode = FakeDocumentsMode.seeded,
    this.failUpload = false,
    this.latency = Duration.zero,
    List<DocumentViewData>? seed,
  }) : _documents = List<DocumentViewData>.from(seed ?? defaultSeed);

  static final defaultSeed = <DocumentViewData>[
    DocumentViewData(
      id: 'doc-approved',
      type: DocumentType.nationalId,
      maskedNumber: '•••• •••• 4821',
      issueDate: DateTime.utc(2022, 3, 15),
      expiryDate: DateTime.utc(2028, 3, 14),
      status: DocumentReviewStatus.approved,
    ),
    DocumentViewData(
      id: 'doc-review',
      type: DocumentType.driverLicense,
      maskedNumber: '•••• •••• 9034',
      issueDate: DateTime.utc(2024, 1, 10),
      expiryDate: DateTime.utc(2029, 1, 9),
      status: DocumentReviewStatus.underReview,
      eligibilityImpact: DocumentEligibilityImpact.blocksAvailability,
    ),
    DocumentViewData(
      id: 'doc-rejected',
      type: DocumentType.vehicleRegistration,
      maskedNumber: '•••• •••• 7712',
      expiryDate: DateTime.utc(2027, 6, 30),
      status: DocumentReviewStatus.rejected,
      rejectionReason: 'Plate number mismatch',
      eligibilityImpact: DocumentEligibilityImpact.blocksVehicleApproval,
    ),
    DocumentViewData(
      id: 'doc-expiring',
      type: DocumentType.insurance,
      maskedNumber: '•••• •••• 5510',
      issueDate: DateTime.utc(2025, 2, 1),
      expiryDate: DateTime.utc(2026, 8, 15),
      status: DocumentReviewStatus.expiringSoon,
      eligibilityImpact: DocumentEligibilityImpact.requiresRenewal,
    ),
    DocumentViewData(
      id: 'doc-expired',
      type: DocumentType.driverLicense,
      maskedNumber: '•••• •••• 2208',
      expiryDate: DateTime.utc(2025, 12, 31),
      status: DocumentReviewStatus.expired,
      eligibilityImpact: DocumentEligibilityImpact.blocksAvailability,
    ),
  ];

  final FakeDocumentsMode mode;
  final bool failUpload;
  final Duration latency;
  final List<DocumentViewData> _documents;

  @override
  Future<List<DocumentViewData>> listDocuments() async {
    await Future<void>.delayed(latency);
    return switch (mode) {
      FakeDocumentsMode.seeded => List.unmodifiable(_documents),
      FakeDocumentsMode.empty => const [],
      FakeDocumentsMode.error => throw const DocumentsRepositoryException(),
      FakeDocumentsMode.offline => throw const DocumentsOfflineException(),
    };
  }

  @override
  Future<DocumentViewData?> getById(String id) async {
    await Future<void>.delayed(latency);
    if (mode == FakeDocumentsMode.error) {
      throw const DocumentsRepositoryException();
    }
    if (mode == FakeDocumentsMode.offline) {
      throw const DocumentsOfflineException();
    }
    for (final document in _documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  @override
  Future<void> uploadDocument({
    required DocumentType type,
    required FakeFileMetadata file,
  }) async {
    await Future<void>.delayed(latency);
    if (mode == FakeDocumentsMode.offline) {
      throw const DocumentsOfflineException();
    }
    if (failUpload || mode == FakeDocumentsMode.error) {
      throw const DocumentsRepositoryException();
    }
    _documents.add(
      DocumentViewData(
        id: 'doc-upload-${_documents.length + 1}',
        type: type,
        maskedNumber: '•••• •••• 0001',
        expiryDate: DateTime.utc(2027, 1, 1),
        status: DocumentReviewStatus.underReview,
        eligibilityImpact: DocumentEligibilityImpact.blocksAvailability,
      ),
    );
  }
}

class DocumentsRepositoryException implements Exception {
  const DocumentsRepositoryException();
}

class DocumentsOfflineException implements Exception {
  const DocumentsOfflineException();
}

enum DocumentsViewStatus { loading, loaded, empty, error, offline }

class DocumentsListState {
  const DocumentsListState({
    this.status = DocumentsViewStatus.loading,
    this.documents = const [],
  });

  final DocumentsViewStatus status;
  final List<DocumentViewData> documents;
}

enum DocumentUploadStatus {
  initial,
  fileSelected,
  validationError,
  uploading,
  uploadFailure,
  uploadSuccess,
}

class DocumentUploadState {
  const DocumentUploadState({
    this.status = DocumentUploadStatus.initial,
    this.selectedType = DocumentType.nationalId,
    this.file,
  });

  final DocumentUploadStatus status;
  final DocumentType selectedType;
  final FakeFileMetadata? file;

  DocumentUploadState copyWith({
    DocumentUploadStatus? status,
    DocumentType? selectedType,
    FakeFileMetadata? file,
    bool clearFile = false,
  }) {
    return DocumentUploadState(
      status: status ?? this.status,
      selectedType: selectedType ?? this.selectedType,
      file: clearFile ? null : (file ?? this.file),
    );
  }
}

final documentsRepositoryProvider = Provider<DocumentsRepository?>((ref) {
  try {
    if (AppConfig.isProduction) return null;
  } catch (_) {
    // Widget tests may run before AppConfig initialization.
  }
  return FakeDocumentsRepository();
});

class DocumentsListController extends Notifier<DocumentsListState> {
  @override
  DocumentsListState build() {
    Future.microtask(load);
    return const DocumentsListState();
  }

  DocumentsRepository? get _repository => ref.read(documentsRepositoryProvider);

  Future<void> load() async {
    state = DocumentsListState(
      status: DocumentsViewStatus.loading,
      documents: state.documents,
    );
    final repository = _repository;
    if (repository == null) {
      state = const DocumentsListState(status: DocumentsViewStatus.error);
      return;
    }
    try {
      final documents = await repository.listDocuments();
      if (!ref.mounted) return;
      state = DocumentsListState(
        status: documents.isEmpty
            ? DocumentsViewStatus.empty
            : DocumentsViewStatus.loaded,
        documents: documents,
      );
    } on DocumentsOfflineException {
      if (ref.mounted) {
        state = DocumentsListState(
          status: DocumentsViewStatus.offline,
          documents: state.documents,
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = DocumentsListState(
          status: DocumentsViewStatus.error,
          documents: state.documents,
        );
      }
    }
  }
}

final documentsListControllerProvider =
    NotifierProvider<DocumentsListController, DocumentsListState>(
      DocumentsListController.new,
    );

final documentDetailProvider = FutureProvider.family<DocumentViewData?, String>(
  (ref, id) async {
    final repository = ref.watch(documentsRepositoryProvider);
    if (repository == null) return null;
    return repository.getById(id);
  },
);

class DocumentUploadController extends Notifier<DocumentUploadState> {
  @override
  DocumentUploadState build() => const DocumentUploadState();

  DocumentsRepository? get _repository => ref.read(documentsRepositoryProvider);

  void selectType(DocumentType type) {
    state = state.copyWith(
      selectedType: type,
      status: DocumentUploadStatus.initial,
    );
  }

  void selectFakeFile() {
    state = state.copyWith(
      status: DocumentUploadStatus.fileSelected,
      file: FakeFileMetadata(
        name: 'trial-document.pdf',
        sizeLabel: '1.2 MB',
        mimeType: 'application/pdf',
      ),
    );
  }

  Future<void> upload() async {
    final file = state.file;
    if (file == null) {
      state = state.copyWith(status: DocumentUploadStatus.validationError);
      return;
    }
    final repository = _repository;
    if (repository == null) {
      state = state.copyWith(status: DocumentUploadStatus.uploadFailure);
      return;
    }
    state = state.copyWith(status: DocumentUploadStatus.uploading);
    try {
      await repository.uploadDocument(type: state.selectedType, file: file);
      if (ref.mounted) {
        state = state.copyWith(
          status: DocumentUploadStatus.uploadSuccess,
          clearFile: true,
        );
      }
    } on DocumentsOfflineException {
      if (ref.mounted) {
        state = state.copyWith(status: DocumentUploadStatus.uploadFailure);
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(status: DocumentUploadStatus.uploadFailure);
      }
    }
  }

  void reset() {
    state = const DocumentUploadState();
  }
}

final documentUploadControllerProvider =
    NotifierProvider<DocumentUploadController, DocumentUploadState>(
      DocumentUploadController.new,
    );
