import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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

    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: 600,
              child: EditingWidget(
                items: rouletteItems,
                onItemsChanged: (items) => Navigator.pushReplacementNamed(
                  context,
                  '?${createQueryFromItems(items)}',
                ),
              ),
            ),
            const SizedBox(height: 20),
            CupertinoButton(
              child: const Text('Copy URL'),
              onPressed: () {
                final uri =
                    pageURL.replace(query: createQueryFromItems(rouletteItems));
                Clipboard.setData(ClipboardData(text: uri.toString()));
              },
            ),
            const SizedBox(height: 20),
            if (rouletteItems.length > 3)
              RouletteWidget(rouletteItems: rouletteItems),
          ],
        ),
      ),
    );
  }

  String createQueryFromItems(List<String> items) => 'items=${items.join(',')}';
}
