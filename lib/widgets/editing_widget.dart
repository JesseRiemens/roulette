import 'package:flutter/material.dart';
import 'package:webroulette/l10n/app_localizations.dart';

class EditingWidget extends StatelessWidget {
  const EditingWidget(
      {Key? key,
      required this.items,
      required this.onItemsChanged,
      required this.backgroundColor})
      : super(key: key);

  final List<String> items;
  final Function(List<String>) onItemsChanged;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    TextStyle unifiedTextStyle = TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 16);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border.all(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: double.infinity,
              height: 75,
              child: TextField(
                decoration: InputDecoration(
                  hintStyle: unifiedTextStyle.copyWith(color: Colors.grey),
                  hintText: AppLocalizations.of(context)!.beCreative,
                  contentPadding: const EdgeInsets.all(8),
                  label: Text(AppLocalizations.of(context)!.enterAnItem,
                      style: unifiedTextStyle),
                  alignLabelWithHint: true,
                ),
                controller: controller,
                style: unifiedTextStyle,
                onSubmitted: (String value) {
                  if (value.trim().isNotEmpty) {
                    onItemsChanged([...items, value.trim()]);
                  }
                },
                expands: true,
                minLines: null,
                maxLines: null,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onItemsChanged([...items, controller.text.trim()]);
                  controller.clear();
                }
              },
              child: Text(AppLocalizations.of(context)!.add,
                  style: unifiedTextStyle),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '${index + 1}: ${items[index]}',
                        style: unifiedTextStyle,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                    TextButton(
                      child: const Icon(
                        Icons.remove_circle_outline_sharp,
                      ),
                      onPressed: () {
                        onItemsChanged([...items]..removeAt(index));
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
