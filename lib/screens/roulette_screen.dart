import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webroulette/bloc/storage_bloc.dart';
import 'package:webroulette/widgets/editing_widget.dart';
import 'package:webroulette/widgets/roulette_widget.dart';

class RouletteScreen extends StatelessWidget {
  const RouletteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: BlocBuilder<StorageCubit, StoredItems>(
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
}
