import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/app_models.dart';

class PredictionResponseResult {
  final bool isBackendOnline;
  final String statusMessage;
  final PredictionModel? prediction;
  final Map<String, dynamic>? backendStatusInfo;

  PredictionResponseResult({
    required this.isBackendOnline,
    required this.statusMessage,
    this.prediction,
    this.backendStatusInfo,
  });
}

class PredictionApiService {
  static const Uuid _uuid = Uuid();

  /// Cek status server FastAPI ML (Apakah model sudah dilatih & metrik evaluasi tersedia)
  static Future<Map<String, dynamic>?> checkServerStatus(String baseUrl) async {
    final cleanUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final candidateUrls = <String>{
      cleanUrl,
      'http://127.0.0.1:8000',
      'http://10.0.2.2:8000', // Android Emulator loopback ke host PC
    };

    for (final url in candidateUrls) {
      try {
        final response = await http
            .get(Uri.parse('$url/health'))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          data['resolved_base_url'] = url;
          return data;
        }
      } catch (_) {
        // Coba URL kandidat berikutnya
      }
    }
    return null;
  }

  /// Meminta prediksi dari backend Python FastAPI (Linear Regression & Random Forest Regression)
  /// Aturan H: Jangan membuat prediksi palsu atau angka acak jika backend/model belum tersedia.
  static Future<PredictionResponseResult> requestYieldPrediction({
    required String baseUrl,
    required String userId,
    required String plotId,
    required String cycleId,
    required double areaHa,
    required String cornVariety,
    required double seedKg,
    required double fertilizerKg,
    double? historicalAvgYieldTonsPerHa,
    String preferredModel =
        'random_forest', // 'random_forest' atau 'linear_regression'
  }) async {
    final serverInfo = await checkServerStatus(baseUrl);
    if (serverInfo == null) {
      return PredictionResponseResult(
        isBackendOnline: false,
        statusMessage: 'Server Prediksi FastAPI belum terhubung atau model belum dijalankan. Sesuai aturan aplikasi, sistem tidak menampilkan angka prediksi palsu/acak. Jalankan backend Python FastAPI (`python backend/main.py`) untuk mengaktifkan model Linear Regression & Random Forest Regression.',
      );
    }

    final resolvedUrl = serverInfo['resolved_base_url'] as String? ?? baseUrl;
    final isModelTrained = serverInfo['model_trained'] == true;
    if (!isModelTrained) {
      return PredictionResponseResult(
        isBackendOnline: true,
        backendStatusInfo: serverInfo,
        statusMessage: 'Dataset belum tersedia atau model belum dilatih pada server. Tidak ada angka prediksi yang ditampilkan sebelum model selesai dilatih dan diuji.',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$resolvedUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'area_ha': areaHa,
              'corn_variety': cornVariety,
              'seed_kg': seedKg,
              'fertilizer_kg': fertilizerKg,
              'historical_avg_tons_per_ha': historicalAvgYieldTonsPerHa,
              'model_type': preferredModel,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final now = DateTime.now();
        final pred = PredictionModel(
          id: 'pred_${_uuid.v4()}',
          userId: userId,
          plotId: plotId,
          cycleId: cycleId,
          areaHa: areaHa,
          cornVariety: cornVariety,
          seedKg: seedKg,
          fertilizerKg: fertilizerKg,
          historicalAvgYieldTonsPerHa: historicalAvgYieldTonsPerHa,
          predictedYieldKg: (body['predicted_yield_kg'] as num).toDouble(),
          predictedYieldTons: (body['predicted_yield_tons'] as num).toDouble(),
          predictedYieldKgPerHa: (body['predicted_yield_kg_per_ha'] as num)
              .toDouble(),
          modelUsed: body['model_used'] ?? 'Random Forest Regression',
          mae: (body['metrics']?['mae'] as num?)?.toDouble() ?? 0.0,
          rmse: (body['metrics']?['rmse'] as num?)?.toDouble() ?? 0.0,
          r2Score: (body['metrics']?['r2'] as num?)?.toDouble() ?? 0.0,
          comparisonMetrics: body['comparison'] != null
              ? Map<String, dynamic>.from(body['comparison'])
              : null,
          createdAt: now,
          updatedAt: now,
        );
        return PredictionResponseResult(
          isBackendOnline: true,
          statusMessage:
              'Prediksi berhasil dihitung oleh model Machine Learning.',
          prediction: pred,
          backendStatusInfo: serverInfo,
        );
      } else {
        return PredictionResponseResult(
          isBackendOnline: true,
          statusMessage:
              'Gagal memproses prediksi dari server (HTTP ${response.statusCode}): ${response.body}',
          backendStatusInfo: serverInfo,
        );
      }
    } catch (e) {
      return PredictionResponseResult(
        isBackendOnline: false,
        statusMessage: 'Gagal menghubungi endpoint prediksi FastAPI: $e',
      );
    }
  }
}
