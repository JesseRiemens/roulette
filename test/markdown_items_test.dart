import 'package:flutter_test/flutter_test.dart';
import 'package:webroulette/data/markdown_items.dart';

void main() {
  group('formatItemsAsMarkdown', () {
    test('emits preamble, blank line, heading and bullets', () {
      expect(formatItemsAsMarkdown(['a', 'b']), '$llmPreamble\n\n## Items\n- a\n- b\n');
    });

    test('preamble text is exact', () {
      expect(
        llmPreamble,
        'Here are my task lists (Markdown). When you reply, keep this exact format: '
        '"## Section name" headings with "- task" bullets, and nothing else.',
      );
    });

    test('without preamble', () {
      expect(formatItemsAsMarkdown(['a'], withPreamble: false), '## Items\n- a\n');
    });

    test('empty list still has heading', () {
      expect(formatItemsAsMarkdown([]), '$llmPreamble\n\n## Items\n');
    });
  });

  group('parseMarkdownItems', () {
    test('accepts all bullet styles', () {
      expect(parseMarkdownItems('- a\n* b\n+ c\n  - d'), ['a', 'b', 'c', 'd']);
    });

    test('accepts numbering with . and )', () {
      expect(parseMarkdownItems('1. one\n2) two\n10. ten'), ['one', 'two', 'ten']);
    });

    test('handles CRLF', () {
      expect(parseMarkdownItems('## H\r\n- a\r\n- b\r\n'), ['a', 'b']);
    });

    test('ignores preamble prose, headings and blank lines', () {
      const input = '$llmPreamble\n\nSure! Here you go:\n\n## Chores\n\n- dishes\n\nHope that helps.\n';
      expect(parseMarkdownItems(input), ['dishes']);
    });

    test('empty and whitespace input', () {
      expect(parseMarkdownItems(''), isEmpty);
      expect(parseMarkdownItems('  \n\n \t\n'), isEmpty);
    });

    test('headings only', () {
      expect(parseMarkdownItems('# A\n## B\n### C ###'), isEmpty);
    });

    test('flattens multiple sections and keeps duplicates', () {
      expect(parseMarkdownItems('## A\n- x\n- y\n\n## B\n- x\n'), ['x', 'y', 'x']);
    });

    test('bullets before any heading are kept', () {
      expect(parseMarkdownItems('- a\n## H\n- b'), ['a', 'b']);
    });

    test('strips wrapping bold only when whole item is wrapped', () {
      expect(parseMarkdownItems('- **Bold**\n- __Under__\n- **a** and **b**\n- a **b**'), [
        'Bold',
        'Under',
        '**a** and **b**',
        'a **b**',
      ]);
    });

    test('strips checkbox markers', () {
      expect(parseMarkdownItems('- [ ] todo\n- [x] done'), ['todo', 'done']);
    });

    test('trims whitespace', () {
      expect(parseMarkdownItems('-    spaced out   '), ['spaced out']);
    });

    test('ignores bullets with no content and non-list lines', () {
      expect(parseMarkdownItems('-\n- \n-nospace\n1.x\ntext - not bullet'), isEmpty);
    });

    test('unicode', () {
      expect(parseMarkdownItems('- café ☕\n- 日本語\n- 🎲 roll'), ['café ☕', '日本語', '🎲 roll']);
    });
  });

  test('round trip format -> parse', () {
    final items = ['one', 'two words', 'café ☕', 'one'];
    expect(parseMarkdownItems(formatItemsAsMarkdown(items)), items);
  });
}
