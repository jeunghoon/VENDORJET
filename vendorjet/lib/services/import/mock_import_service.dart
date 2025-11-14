import 'package:excel/excel.dart';

class XlsxImportResult {
  final int processed;
  final int success;
  final int failed;
  final List<String> messages;

  const XlsxImportResult({
    required this.processed,
    required this.success,
    required this.failed,
    required this.messages,
  });
}

class MockXlsxImportService {
  Future<XlsxImportResult> importProducts(List<int> bytes) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        return const XlsxImportResult(
          processed: 0,
          success: 0,
          failed: 0,
          messages: ['No sheets found.'],
        );
      }
      final sheet = excel.tables.values.first;
      final rows = sheet.rows;
      final processed = (rows.length - 1).clamp(0, rows.length);
      if (processed == 0) {
        return const XlsxImportResult(
          processed: 0,
          success: 0,
          failed: 0,
          messages: ['Workbook contains no data rows.'],
        );
      }
      final success = (processed * 0.85).round();
      final failed = processed - success;
      final messages = <String>[
        '$success rows imported (mock).',
        if (failed > 0) '$failed rows skipped after validation.',
      ];
      return XlsxImportResult(
        processed: processed,
        success: success,
        failed: failed,
        messages: messages,
      );
    } catch (err) {
      return XlsxImportResult(
        processed: 0,
        success: 0,
        failed: 0,
        messages: ['Failed to read .xlsx: $err'],
      );
    }
  }
}
