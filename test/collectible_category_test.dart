import 'package:collectiq_ai/shared/domain/collectible_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonicalCategory', () {
    test(
      'Lorcana joins the same "Cards" bucket as Pokémon/MTG/Yu-Gi-Oh/One '
      'Piece, even for bare "Lorcana" text with no "card" substring (real '
      'gap: catalog rows always say "Lorcana Card(s)" so it worked by '
      'coincidence, but an AI-scanned item whose recognized category is '
      'just "Lorcana" would otherwise fall through into its own ad-hoc '
      'bucket instead of joining its sibling card games)',
      () {
        expect(canonicalCategory('Lorcana'), 'Cards');
        expect(canonicalCategory('Lorcana Card'), 'Cards');
      },
    );
  });
}
