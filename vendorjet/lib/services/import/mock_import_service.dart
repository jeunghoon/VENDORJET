class CsvImportResult {
  final int processed;
  final int success;
  final int failed;
  final List<String> messages;

  const CsvImportResult({
    required this.processed,
    required this.success,
    required this.failed,
    required this.messages,
  });
}

class MockCsvImportService {
  Future<CsvImportResult> importProducts(String csvContent) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final lines = csvContent
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length <= 1) {
      return const CsvImportResult(
        processed: 0,
        success: 0,
        failed: 0,
        messages: ['CSV contains no rows.'],
      );
    }

    final processed = lines.length - 1;
    final success = (processed * 0.8).round();
    final failed = processed - success;
    final messages = <String>[
      '$success rows imported (mock).',
      if (failed > 0) '$failed rows skipped due to validation errors.',
    ];
    return CsvImportResult(
      processed: processed,
      success: success,
      failed: failed,
      messages: messages,
    );
  }
}
