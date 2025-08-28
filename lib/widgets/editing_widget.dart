import 'package:flutter/material.dart';
import 'package:webroulette/l10n/app_localizations.dart';

class EditingWidget extends StatefulWidget {
  const EditingWidget({Key? key, required this.items, required this.onItemsChanged, required this.backgroundColor})
    : super(key: key);

  final List<String> items;
  final Function(List<String>) onItemsChanged;
  final Color backgroundColor;

  @override
  State<EditingWidget> createState() => _EditingWidgetState();
}

class _EditingWidgetState extends State<EditingWidget> with AutomaticKeepAliveClientMixin {
  late final TextEditingController textController;
  late final FocusNode focusNode;

  @override
  bool get wantKeepAlive => true; // This preserves the state

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(EditingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Preserve text controller state across widget updates
    // The ValueKey should prevent widget recreation, but this provides extra safety
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return _EditingWidgetBody(
      items: widget.items,
      onItemsChanged: widget.onItemsChanged,
      backgroundColor: widget.backgroundColor,
      textController: textController,
      focusNode: focusNode,
    );
  }
}

// Removed obsolete _EditingWidgetBodyState and old _EditingWidgetBody StatefulWidget

// Move _EditingWidgetBody to top level
class _EditingWidgetBody extends StatelessWidget {
  const _EditingWidgetBody({
    Key? key,
    required this.items,
    required this.onItemsChanged,
    required this.backgroundColor,
    required this.textController,
    required this.focusNode,
  }) : super(key: key);

  final List<String> items;
  final Function(List<String>) onItemsChanged;
  final Color backgroundColor;
  final TextEditingController textController;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    TextStyle unifiedTextStyle = TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 16);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border.all(color: Theme.of(context).colorScheme.onPrimaryContainer, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Wrap TextField in Container to provide more stability during resizes
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                key: const ValueKey('main_text_field'),
                decoration: InputDecoration(
                  hintStyle: unifiedTextStyle.copyWith(color: Colors.grey),
                  hintText: AppLocalizations.of(context)!.beCreative,
                  contentPadding: const EdgeInsets.all(8),
                  label: Text(AppLocalizations.of(context)!.enterAnItem, style: unifiedTextStyle),
                  alignLabelWithHint: true,
                ),
                controller: textController,
                focusNode: focusNode,
                autofocus: false,
                style: unifiedTextStyle,
                // Prevent the field from losing text on rebuilds
                enableInteractiveSelection: true,
                onSubmitted: (String value) {
                  if (value.trim().isNotEmpty) {
                    final newItems = List<String>.from(items);
                    newItems.add(value.trim());
                    onItemsChanged(newItems);
                    textController.clear();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      focusNode.requestFocus();
                    });
                  }
                },
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  final newItems = List<String>.from(items);
                  newItems.add(textController.text.trim());
                  onItemsChanged(newItems);
                  textController.clear();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    focusNode.requestFocus();
                  });
                }
              },
              child: Text(AppLocalizations.of(context)!.add, style: unifiedTextStyle),
            ),
            const SizedBox(height: 10),
            _buildListView(context, unifiedTextStyle, items, onItemsChanged),
          ],
        ),
      ),
    );
  }

  SizedBox _buildListView(
    BuildContext context,
    TextStyle unifiedTextStyle,
    List<String> items,
    Function(List<String>) onItemsChanged,
  ) {
    return SizedBox(
      height: (items.length * 48.0).clamp(48.0, 300.0),
      child: ReorderableListView(
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        onReorder: (int oldIndex, int newIndex) {
          final newItems = List<String>.from(items);
          if (newIndex > oldIndex) newIndex--;
          final item = newItems.removeAt(oldIndex);
          newItems.insert(newIndex, item);
          onItemsChanged(newItems);
        },
        children: [
          for (int index = 0; index < items.length; index++)
            Row(
              key: ValueKey('item_$index'),
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(Icons.drag_handle, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit',
                  onPressed: () async {
                    final newValue = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        final controller = TextEditingController(text: items[index]);
                        return AlertDialog(
                          title: const Text('Edit Item'),
                          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                          content: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 200,
                              maxWidth: MediaQuery.of(context).size.width * 0.9,
                              minHeight: 48,
                              maxHeight: 200,
                            ),
                            child: TextField(
                              controller: controller,
                              autofocus: true,
                              maxLines: null,
                              expands: true,
                              decoration: const InputDecoration(labelText: 'Edit Item'),
                              onSubmitted: (value) {
                                Navigator.of(context).pop(value);
                              },
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(controller.text),
                              child: const Text('Save'),
                            ),
                          ],
                        );
                      },
                    );
                    if (newValue != null && newValue.trim().isNotEmpty && newValue != items[index]) {
                      final newItems = List<String>.from(items);
                      newItems[index] = newValue.trim();
                      onItemsChanged(newItems);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_sharp, size: 20),
                  tooltip: 'Remove',
                  onPressed: () {
                    final newItems = List<String>.from(items)..removeAt(index);
                    onItemsChanged(newItems);
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${index + 1}: ',
                            style: unifiedTextStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          TextSpan(text: items[index], style: unifiedTextStyle),
                        ],
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
