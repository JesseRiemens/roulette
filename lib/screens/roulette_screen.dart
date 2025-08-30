import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/widgets/editing_widget.dart';
import 'package:webroulette/widgets/roulette_widget.dart';
import 'package:webroulette/l10n/app_localizations.dart';

class RouletteScreen extends StatelessWidget {
  const RouletteScreen({Key? key}) : super(key: key);

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
      child: BlocBuilder<StorageCubit, StoredItems>(
        builder: (context, state) {
          return Column(
            children: [
              // Two buttons side by side
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Share via Hastebin button
                  ElevatedButton.icon(
                    icon: state.isUploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.cloud_upload),
                    label: Text(state.isUploading ? 'Sharing...' : AppLocalizations.of(context)!.shareViaHastebin),
                    onPressed: state.isUploading || state.items.isEmpty
                        ? null
                        : () async {
                            try {
                              final url = await context.read<StorageCubit>().shareItems();
                              if (context.mounted) {
                                await Clipboard.setData(ClipboardData(text: url));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(const SnackBar(content: Text('Shareable URL copied to clipboard!')));
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text('Failed to share items: ${e.toString()}')));
                              }
                            }
                          },
                  ),
                  const SizedBox(width: 12),
                  // Share via URL button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    label: Text(AppLocalizations.of(context)!.shareViaUrl),
                    onPressed: state.items.isEmpty
                        ? null
                        : () async {
                            try {
                              final url = context.read<StorageCubit>().shareItemsViaUrl();
                              if (context.mounted) {
                                await Clipboard.setData(ClipboardData(text: url));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(const SnackBar(content: Text('Shareable URL copied to clipboard!')));
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text('Failed to share items: ${e.toString()}')));
                              }
                            }
                          },
                  ),
                ],
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Loading shared items...', style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
                ),
            ],
          );
        },
      ),
    );
  }
}
