import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';

abstract interface class MarketProvider {
  Future<MarketSummary> summarizeMarket(RecognitionResult recognition);
}
