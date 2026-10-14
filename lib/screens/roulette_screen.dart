import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/data/markdown_items.dart';
import 'package:webroulette/l10n/app_localizations.dart';
import 'package:webroulette/widgets/editing_widget.dart';
import 'package:webroulette/widgets/markdown_import_dialog.dart';
import 'package:webroulette/widgets/roulette_widget.dart';

class RouletteScreen extends StatelessWidget {
  const RouletteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          // Wrap BlocBuilder in a ResizeableKeyboardAware widget
          child: BlocBuilder<StorageCubit, StoredItems>(
            // Use buildWhen to limit rebuilds and preserve text field state
            buildWhen: (previous, current) {
              // Only rebuild when items actually change, not on every state change
              return previous.items != current.items;
            },
            builder: (context, state) {
              List<String> rouletteItems = state.items;

              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Copy URL button
                  _buildCopyButton(context),
                  _buildLlmButtons(context),
                  _buildEditWidget(rouletteItems, context),
                  if (rouletteItems.length > 1) RouletteWidget(rouletteItems: rouletteItems),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  SizedBox _buildEditWidget(List<String> rouletteItems, BuildContext context) {
    return SizedBox(
      width: 600,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: EditingWidget(
          key: const ValueKey('editing_widget'),
          items: rouletteItems,
          onItemsChanged: (items) => context.read<StorageCubit>().saveItems(items),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Padding _buildCopyButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.copy),
        label: const Text('Copy URL'),
        onPressed: () {
          final uri = context.read<StorageCubit>().uriWithData;
          Clipboard.setData(ClipboardData(text: uri.toString())).then(
            (_) => context.mounted
                ? ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copied to clipboard!')))
                : null,
          );
        },
      ),
    );
  }

  Widget _buildLlmButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          OutlinedButton.icon(
            key: const ValueKey('copy_for_llm_button'),
            icon: const Icon(Icons.smart_toy_outlined),
            label: Text(l10n.copyForLlm),
            onPressed: () async {
              final cubit = context.read<StorageCubit>();
              final messenger = ScaffoldMessenger.of(context);
              final text = formatItemsAsMarkdown(cubit.state.items);
              final message = l10n.copiedForLlm;
              await Clipboard.setData(ClipboardData(text: text));
              messenger.showSnackBar(SnackBar(content: Text(message)));
            },
          ),
          OutlinedButton.icon(
            key: const ValueKey('paste_from_llm_button'),
            icon: const Icon(Icons.content_paste),
            label: Text(l10n.pasteFromLlm),
            onPressed: () async {
              final cubit = context.read<StorageCubit>();
              final result = await showMarkdownImportDialog(context);
              if (result == null) return;
              cubit.saveItems(result.replace ? result.items : [...cubit.state.items, ...result.items]);
            },
          ),
        ],
      ),
    );
  }
}
