import 'package:flutter/material.dart';
import 'package:webroulette/data/markdown_items.dart';
import 'package:webroulette/l10n/app_localizations.dart';

/// Result of the import dialog: the parsed items and whether they replace the existing list.
class MarkdownImportResult {
  const MarkdownImportResult({required this.items, required this.replace});

  final List<String> items;
  final bool replace;
}

/// Shows the "Paste from LLM" dialog and returns the user's choice, or null when cancelled.
Future<MarkdownImportResult?> showMarkdownImportDialog(BuildContext context) {
  return showDialog<MarkdownImportResult>(context: context, builder: (_) => const MarkdownImportDialog());
}

class MarkdownImportDialog extends StatefulWidget {
  const MarkdownImportDialog({super.key});

  @override
  State<MarkdownImportDialog> createState() => _MarkdownImportDialogState();
}

class _MarkdownImportDialogState extends State<MarkdownImportDialog> {
  final TextEditingController _controller = TextEditingController();
  List<String> _items = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish(bool replace) => Navigator.of(context).pop(MarkdownImportResult(items: _items, replace: replace));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasText = _controller.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(l10n.pasteFromLlmTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const ValueKey('markdown_import_field'),
                controller: _controller,
                autofocus: true,
                minLines: 5,
                maxLines: 10,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(hintText: l10n.pasteFromLlmHint, border: const OutlineInputBorder()),
                onChanged: (text) => setState(() => _items = parseMarkdownItems(text)),
              ),
              const SizedBox(height: 12),
              if (hasText) ...[
                Text(
                  _items.isEmpty ? l10n.importNothingFound : l10n.importPreviewCount(_items.length),
                  key: const ValueKey('markdown_import_preview_count'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                for (final item in _items) Text('• $item'),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        TextButton(
          key: const ValueKey('markdown_import_add'),
          onPressed: _items.isEmpty ? null : () => _finish(false),
          child: Text(l10n.addToExisting),
        ),
        FilledButton(
          key: const ValueKey('markdown_import_replace'),
          onPressed: _items.isEmpty ? null : () => _finish(true),
          child: Text(l10n.replaceItems),
        ),
      ],
    );
  }
}
