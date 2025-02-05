import 'package:flutter/material.dart';
import 'package:webroulette/widgets/editing_widget.dart';
import 'package:webroulette/widgets/roulette_widget.dart';

class RouletteScreen extends StatelessWidget {
  RouletteScreen({required this.pageURL}) : super(key: ValueKey(pageURL));

  final Uri pageURL;

  @override
  Widget build(BuildContext context) {
    List<String> rouletteItems = [];
    final items = pageURL.queryParameters['items'];
    if (items != null) {
      rouletteItems = items.split(',');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              SizedBox(
                width: 600,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: EditingWidget(
                    items: rouletteItems,
                    onItemsChanged: (items) => Navigator.pushReplacementNamed(
                      context,
                      '?${createQueryFromItems(items)}',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (rouletteItems.length > 1)
                RouletteWidget(rouletteItems: rouletteItems),
            ],
          ),
        ),
      ),
    );
  }

  String createQueryFromItems(List<String> items) => 'items=${items.join(',')}';
}
