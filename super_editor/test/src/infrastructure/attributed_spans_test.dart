import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:logging/logging.dart';
import 'package:super_editor/src/default_editor/attributions.dart';
import 'package:super_editor/src/infrastructure/_logging.dart';
import 'package:super_editor/src/infrastructure/attributed_spans.dart';

import '../../test_tools.dart';
import '_attributed_text_test_tools.dart';

void main() {
  groupWithLogging('Spans', Level.OFF, {attributionsLog}, () {
    group('attribution queries', () {
      test('it expands a span from a given offset', () {
        final spans = AttributedSpans()..addAttribution(newAttribution: boldAttribution, start: 3, end: 16);
        final expandedSpan = spans.expandAttributionToSpan(attribution: boldAttribution, offset: 6);

        expect(
          expandedSpan,
          equals(
            const AttributionSpan(
              attribution: boldAttribution,
              start: 3,
              end: 16,
            ),
          ),
        );
      });

      test('it returns spans that fit within a range', () {
        final spans = AttributedSpans()
          ..addAttribution(newAttribution: boldAttribution, start: 0, end: 2)
          ..addAttribution(newAttribution: boldAttribution, start: 5, end: 10);
        final attributionSpans = spans.getAttributionSpansInRange(
          attributionFilter: (attribution) => attribution == boldAttribution,
          start: 3,
          end: 15,
        );

        expect(attributionSpans.length, 1);
        expect(
          attributionSpans.first,
          equals(
            const AttributionSpan(
              attribution: boldAttribution,
              start: 5,
              end: 10,
            ),
          ),
        );
      });

      test('it returns spans that partially overlap range', () {
        final spans = AttributedSpans()
          ..addAttribution(newAttribution: boldAttribution, start: 3, end: 7)
          ..addAttribution(newAttribution: boldAttribution, start: 10, end: 15);
        final attributionSpans = spans.getAttributionSpansInRange(
          attributionFilter: (attribution) => attribution == boldAttribution,
          start: 5,
          end: 12,
        );

        expect(attributionSpans.length, 2);
        expect(
          attributionSpans.first,
          equals(
            const AttributionSpan(
              attribution: boldAttribution,
              start: 3,
              end: 7,
            ),
          ),
        );
        expect(
          attributionSpans.last,
          equals(
            const AttributionSpan(
              attribution: boldAttribution,
              start: 10,
              end: 15,
            ),
          ),
        );
      });

      test('it returns spans that completely cover the range', () {
        final spans = AttributedSpans()..addAttribution(newAttribution: boldAttribution, start: 0, end: 10);
        final attributionSpans = spans.getAttributionSpansInRange(
          attributionFilter: (attribution) => attribution == boldAttribution,
          start: 3,
          end: 8,
        );

        expect(attributionSpans.length, 1);
        expect(
          attributionSpans.first,
          equals(
            const AttributionSpan(
              attribution: boldAttribution,
              start: 0,
              end: 10,
            ),
          ),
        );
      });

      test('it resizes spans that partially overlap range', () {
        final spans = AttributedSpans()
          ..addAttribution(newAttribution: boldAttribution, start: 3, end: 7)
          ..addAttribution(newAttribution: boldAttribution, start: 10, end: 15);
        final attributionSpans = spans.getAttributionSpansInRange(
          attributionFilter: (attribution) => attribution == boldAttribution,
          start: 5,
          end: 12,
          resizeSpansToFitInRange: true,
        );

        expect(attributionSpans.length, 2);
        expect(
          attributionSpans.first,
          equals(
            const AttributionSpan(
              attribution: boldAttribution,
              start: 5,
              end: 7,
            ),
          ),
        );
        expect(
          attributionSpans.last,
          equals(
            const AttributionSpan(
              attribution: boldAttribution,
              start: 10,
              end: 12,
            ),
          ),
        );
      });

      test('it resizes spans that completely cover the range', () {
        final spans = AttributedSpans()..addAttribution(newAttribution: boldAttribution, start: 0, end: 10);
        final attributionSpans = spans.getAttributionSpansInRange(
          attributionFilter: (attribution) => attribution == boldAttribution,
          start: 3,
          end: 8,
          resizeSpansToFitInRange: true,
        );

        expect(attributionSpans.length, 1);
        expect(
          attributionSpans.first,
          equals(
            const AttributionSpan(
              attribution: boldAttribution,
              start: 3,
              end: 8,
            ),
          ),
        );
      });
    });

    group('single attribution', () {
      test('applies attribution to full span', () {
        final spans = AttributedSpans()..addAttribution(newAttribution: boldAttribution, start: 0, end: 16);

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 0, end: 16), true);
      });

      test('applies attribution to beginning of span', () {
        final spans = AttributedSpans()..addAttribution(newAttribution: boldAttribution, start: 0, end: 7);

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 0, end: 7), true);
      });

      test('applies attribution to inner span', () {
        final spans = AttributedSpans()..addAttribution(newAttribution: boldAttribution, start: 2, end: 7);

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 2, end: 7), true);
      });

      test('applies attribution to end of span', () {
        final spans = AttributedSpans()..addAttribution(newAttribution: boldAttribution, start: 7, end: 16);

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 7, end: 16), true);
      });

      test('applies exotic span', () {
        final linkAttribution = _LinkAttribution(
          url: 'https://youtube.com/c/superdeclarative',
        );
        final spans = AttributedSpans()..addAttribution(newAttribution: linkAttribution, start: 2, end: 7);

        expect(spans.hasAttributionsWithin(attributions: {linkAttribution}, start: 2, end: 7), true);
      });

      test('removes attribution from full span', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 16, markerType: SpanMarkerType.end)
          ],
        )..removeAttribution(attributionToRemove: boldAttribution, start: 0, end: 16);

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 0, end: 16), false);
      });

      test('removes attribution from single unit', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 8, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 8, markerType: SpanMarkerType.end)
          ],
        );

        ExpectedSpans([
          '________b_______',
        ]).expectSpans(spans);

        spans.removeAttribution(attributionToRemove: boldAttribution, start: 8, end: 8);

        ExpectedSpans([
          '________________',
        ]).expectSpans(spans);
      });

      test('removes attribution from single unit at end of span', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 8, markerType: SpanMarkerType.end)
          ],
        );

        ExpectedSpans([
          'bbbbbbbb_______',
        ]).expectSpans(spans);

        spans.removeAttribution(attributionToRemove: boldAttribution, start: 8, end: 8);

        ExpectedSpans([
          'bbbbbbb_________',
        ]).expectSpans(spans);
      });

      test('removes attribution from all units except the last', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 8, markerType: SpanMarkerType.end)
          ],
        );

        ExpectedSpans([
          'bbbbbbbb_______',
        ]).expectSpans(spans);

        spans.removeAttribution(attributionToRemove: boldAttribution, start: 0, end: 7);

        ExpectedSpans([
          '________b________',
        ]).expectSpans(spans);
      });

      test('removes attribution from single unit at start of span', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 8, markerType: SpanMarkerType.end)
          ],
        );

        ExpectedSpans([
          'bbbbbbbb_______',
        ]).expectSpans(spans);

        spans.removeAttribution(attributionToRemove: boldAttribution, start: 0, end: 0);

        ExpectedSpans([
          '_bbbbbbb_______',
        ]).expectSpans(spans);
      });

      test('removes attribution from all units except the first', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 8, markerType: SpanMarkerType.end)
          ],
        );

        ExpectedSpans([
          'bbbbbbbb_______',
        ]).expectSpans(spans);

        spans.removeAttribution(attributionToRemove: boldAttribution, start: 1, end: 8);

        ExpectedSpans([
          'b________________',
        ]).expectSpans(spans);
      });

      test('removes attribution from inner text span', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 2, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 7, markerType: SpanMarkerType.end)
          ],
        )..removeAttribution(attributionToRemove: boldAttribution, start: 2, end: 7);

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 2, end: 7), false);
      });

      test('removes attribution from partial beginning span', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 2, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 7, markerType: SpanMarkerType.end)
          ],
        )..removeAttribution(attributionToRemove: boldAttribution, start: 2, end: 4);

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 5, end: 7), true);
      });

      test('removes attribution from partial inner span', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 2, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 7, markerType: SpanMarkerType.end)
          ],
        )..removeAttribution(attributionToRemove: boldAttribution, start: 4, end: 5);

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 2, end: 3), true);
        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 6, end: 7), true);
      });

      test('removes attribution from partial ending span', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 2, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 7, markerType: SpanMarkerType.end)
          ],
        )..removeAttribution(attributionToRemove: boldAttribution, start: 5, end: 7);

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 2, end: 4), true);
      });

      test('applies attribution when mixed span is toggled', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 8, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 16, markerType: SpanMarkerType.end)
          ],
        )..toggleAttribution(attribution: boldAttribution, start: 0, end: 16);

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 0, end: 16), true);
      });

      test('removes attribution when contiguous span is toggled', () {
        final spans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 16, markerType: SpanMarkerType.end)
          ],
        )..toggleAttribution(attribution: boldAttribution, start: 0, end: 16);

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 0, end: 16), false);
      });
    });

    group('multiple attributions', () {
      test('full length overlap', () {
        final spans = AttributedSpans()
          ..addAttribution(newAttribution: boldAttribution, start: 0, end: 9)
          ..addAttribution(newAttribution: italicsAttribution, start: 0, end: 9);

        ExpectedSpans([
          'bbbbbbbbbb',
          'iiiiiiiiii',
        ]).expectSpans(spans);
      });

      test('half and half', () {
        final spans = AttributedSpans()
          ..addAttribution(newAttribution: boldAttribution, start: 5, end: 9)
          ..addAttribution(newAttribution: italicsAttribution, start: 0, end: 4);

        ExpectedSpans([
          '_____bbbbb',
          'iiiii_____',
        ]).expectSpans(spans);
      });

      test('two partial overlap', () {
        final spans = AttributedSpans()
          ..addAttribution(newAttribution: boldAttribution, start: 4, end: 8)
          ..addAttribution(newAttribution: italicsAttribution, start: 1, end: 5);

        ExpectedSpans([
          '____bbbbb_',
          '_iiiii____',
        ]).expectSpans(spans);
      });

      test('three partial overlap', () {
        final spans = AttributedSpans()
          ..addAttribution(newAttribution: boldAttribution, start: 4, end: 8)
          ..addAttribution(newAttribution: italicsAttribution, start: 1, end: 5)
          ..addAttribution(newAttribution: strikethroughAttribution, start: 5, end: 9);

        ExpectedSpans([
          '____bbbbb_',
          '_iiiii____',
          '_____sssss',
        ]).expectSpans(spans);
      });

      test('many small segments', () {
        final spans = AttributedSpans()
          ..addAttribution(newAttribution: boldAttribution, start: 0, end: 1)
          ..addAttribution(newAttribution: italicsAttribution, start: 2, end: 3)
          ..addAttribution(newAttribution: strikethroughAttribution, start: 4, end: 5)
          ..addAttribution(newAttribution: boldAttribution, start: 6, end: 7)
          ..addAttribution(newAttribution: italicsAttribution, start: 8, end: 9);

        ExpectedSpans([
          'bb____bb__',
          '__ii____ii',
          '____ss____',
        ]).expectSpans(spans);
      });

      test('incompatible attributions cannot overlap', () {
        final spans = AttributedSpans();

        // Add link at beginning
        spans.addAttribution(
          newAttribution: _LinkAttribution(url: 'https://flutter.dev'),
          start: 0,
          end: 6,
        );

        // Try to add a different link at the end but overlapping
        // the first link. Expect an exception.
        expect(() {
          spans.addAttribution(
            newAttribution: _LinkAttribution(url: 'https://pub.dev'),
            start: 4,
            end: 12,
          );
        }, throwsA(isA<IncompatibleOverlappingAttributionsException>()));
      });

      test('compatible attributions are merged', () {
        final spans = AttributedSpans();

        // Add bold at beginning
        spans.addAttribution(
          newAttribution: boldAttribution,
          start: 0,
          end: 6,
        );

        // Add bold at end but overlapping earlier bold
        spans.addAttribution(
          newAttribution: boldAttribution,
          start: 4,
          end: 12,
        );

        expect(spans.hasAttributionsWithin(attributions: {boldAttribution}, start: 0, end: 12), true);
      });
    });

    group('collapse spans', () {
      test('empty spans', () {
        // Make sure no exceptions are thrown when collapsing
        // spans on an empty AttributedSpans.
        AttributedSpans().collapseSpans(contentLength: 0);
      });

      test('single continuous attribution', () {
        final collapsedSpans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 16, markerType: SpanMarkerType.end),
          ],
        ).collapseSpans(contentLength: 17);

        expect(collapsedSpans.length, 1);
        expect(collapsedSpans.first.start, 0);
        expect(collapsedSpans.first.end, 16);
        expect(collapsedSpans.first.attributions.length, 1);
        expect(collapsedSpans.first.attributions.first, boldAttribution);
      });

      test('single fractured attribution', () {
        final collapsedSpans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 3, markerType: SpanMarkerType.end),
            const SpanMarker(attribution: boldAttribution, offset: 7, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 10, markerType: SpanMarkerType.end),
          ],
        ).collapseSpans(contentLength: 17);

        expect(collapsedSpans.length, 4);
        expect(collapsedSpans[0].start, 0);
        expect(collapsedSpans[0].end, 3);
        expect(collapsedSpans[0].attributions.length, 1);
        expect(collapsedSpans[0].attributions.first, boldAttribution);
        expect(collapsedSpans[1].start, 4);
        expect(collapsedSpans[1].end, 6);
        expect(collapsedSpans[1].attributions.length, 0);
        expect(collapsedSpans[2].start, 7);
        expect(collapsedSpans[2].end, 10);
        expect(collapsedSpans[2].attributions.length, 1);
        expect(collapsedSpans[2].attributions.first, boldAttribution);
        expect(collapsedSpans[3].start, 11);
        expect(collapsedSpans[3].end, 16);
        expect(collapsedSpans[3].attributions.length, 0);
      });

      test('multiple non-overlapping attributions', () {
        final collapsedSpans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 3, markerType: SpanMarkerType.end),
            const SpanMarker(attribution: italicsAttribution, offset: 7, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: italicsAttribution, offset: 10, markerType: SpanMarkerType.end),
          ],
        ).collapseSpans(contentLength: 17);

        expect(collapsedSpans.length, 4);
        expect(collapsedSpans[0].start, 0);
        expect(collapsedSpans[0].end, 3);
        expect(collapsedSpans[0].attributions.length, 1);
        expect(collapsedSpans[0].attributions.first, boldAttribution);
        expect(collapsedSpans[1].start, 4);
        expect(collapsedSpans[1].end, 6);
        expect(collapsedSpans[1].attributions.length, 0);
        expect(collapsedSpans[2].start, 7);
        expect(collapsedSpans[2].end, 10);
        expect(collapsedSpans[2].attributions.length, 1);
        expect(collapsedSpans[2].attributions.first, italicsAttribution);
        expect(collapsedSpans[3].start, 11);
        expect(collapsedSpans[3].end, 16);
        expect(collapsedSpans[3].attributions.length, 0);
      });

      test('multiple overlapping attributions', () {
        final collapsedSpans = AttributedSpans(
          attributions: [
            const SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: boldAttribution, offset: 8, markerType: SpanMarkerType.end),
            const SpanMarker(attribution: italicsAttribution, offset: 6, markerType: SpanMarkerType.start),
            const SpanMarker(attribution: italicsAttribution, offset: 16, markerType: SpanMarkerType.end),
          ],
        ).collapseSpans(contentLength: 17);

        expect(collapsedSpans.length, 3);
        expect(collapsedSpans[0].start, 0);
        expect(collapsedSpans[0].end, 5);
        expect(collapsedSpans[0].attributions.length, 1);
        expect(collapsedSpans[0].attributions.first, boldAttribution);
        expect(collapsedSpans[1].start, 6);
        expect(collapsedSpans[1].end, 8);
        expect(collapsedSpans[1].attributions.length, 2);
        expect(collapsedSpans[1].attributions, equals({boldAttribution, italicsAttribution}));
        expect(collapsedSpans[2].start, 9);
        expect(collapsedSpans[2].end, 16);
        expect(collapsedSpans[2].attributions.length, 1);
        expect(collapsedSpans[2].attributions.first, italicsAttribution);
      });
    });

    group('equality', () {
      const boldStart = SpanMarker(attribution: boldAttribution, offset: 0, markerType: SpanMarkerType.start);
      final boldEnd = boldStart.copyWith(markerType: SpanMarkerType.end, offset: 1);

      const italicStart = SpanMarker(attribution: italicsAttribution, offset: 0, markerType: SpanMarkerType.start);
      final italicEnd = italicStart.copyWith(markerType: SpanMarkerType.end, offset: 1);

      test('it is equal to another AttributedSpans with equivalent markers that are stored in the same order', () {
        final span1 = AttributedSpans(attributions: [boldStart, italicStart, boldEnd, italicEnd]);
        final span2 = AttributedSpans(attributions: [boldStart, italicStart, boldEnd, italicEnd]);

        expect(span1 == span2, isTrue);
      });

      test('it is equal to another AttributedSpans with equivalent markers that are stored in a different order', () {
        final boldBeforeItalicSpan = AttributedSpans(attributions: [boldStart, italicStart, boldEnd, italicEnd]);
        final italicsBeforeBoldSpan = AttributedSpans(attributions: [italicStart, boldStart, italicEnd, boldEnd]);

        expect(boldBeforeItalicSpan == italicsBeforeBoldSpan, isTrue);
      });

      test('it is equal to another AttributedSpans with empty markers', () {
        final span1 = AttributedSpans(attributions: []);
        final span2 = AttributedSpans(attributions: []);

        expect(span1 == span2, isTrue);
      });

      test('it is NOT equal to another AttributedSpans with different markers', () {
        final span1 = AttributedSpans(attributions: [boldStart, boldEnd]);
        final span2 = AttributedSpans(attributions: [italicStart, italicEnd]);

        expect(span1 == span2, isFalse);
      });
    });
  });
}

class _LinkAttribution implements Attribution {
  _LinkAttribution({
    required this.url,
  });

  @override
  String get id => 'link';

  final String url;

  @override
  bool canMergeWith(Attribution other) {
    return this == other;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _LinkAttribution && runtimeType == other.runtimeType && url == other.url;

  @override
  int get hashCode => url.hashCode;
}
