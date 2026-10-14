/// Markdown import/export of the item list, for pasting to/from an LLM.
///
/// The format matches the sibling TypeScript app (task-roulette).
library;

const String llmPreamble =
    'Here are my task lists (Markdown). When you reply, keep this exact format: '
    '"## Section name" headings with "- task" bullets, and nothing else.';

/// Heading used for the single flat list when exporting.
const String defaultSectionName = 'Items';

final RegExp _heading = RegExp(r'^\s{0,3}#{1,6}\s+(.*?)\s*#*\s*$');
final RegExp _bullet = RegExp(r'^\s*(?:[-*+]|\d+[.)])\s+(.*\S)\s*$');
final RegExp _checkbox = RegExp(r'^\[[ xX]\]\s+');
final RegExp _wrapped = RegExp(r'^(\*\*|__)(.+)\1$');

String _clean(String text) {
  var t = text.trim().replaceFirst(_checkbox, '');
  final m = _wrapped.firstMatch(t);
  if (m != null) {
    final inner = m.group(2)!;
    // Only strip when the whole item is wrapped, not "**a** and **b**".
    if (!inner.contains(m.group(1)!)) t = inner.trim();
  }
  return t;
}

/// Formats [items] as Markdown: optional preamble, a `## Items` heading and `- item` bullets.
String formatItemsAsMarkdown(List<String> items, {bool withPreamble = true}) {
  final body = ['## $defaultSectionName', ...items.map((i) => '- $i')].join('\n');
  return withPreamble ? '$llmPreamble\n\n$body\n' : '$body\n';
}

/// Forgiving parse of LLM-style Markdown. Every list item (`-`, `*`, `+`, `1.`, `1)`) becomes an
/// item; headings, blank lines and prose are ignored. All sections are flattened; nothing is deduped.
List<String> parseMarkdownItems(String markdown) {
  final result = <String>[];
  for (final line in markdown.split(RegExp(r'\r?\n'))) {
    if (_heading.hasMatch(line)) continue;
    final bullet = _bullet.firstMatch(line);
    if (bullet == null) continue;
    final item = _clean(bullet.group(1)!);
    if (item.isNotEmpty) result.add(item);
  }
  return result;
}
