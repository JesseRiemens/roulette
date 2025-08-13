import 'package:flutter/material.dart';
import 'package:webroulette/l10n/app_localizations.dart';

class EditingWidget extends StatefulWidget {
  const EditingWidget({
    Key? key,
    required this.items,
    required this.onItemsChanged,
    required this.backgroundColor,
  }) : super(key: key);

  final List<String> items;
  final Function(List<String>) onItemsChanged;
  final Color backgroundColor;

  @override
  State<EditingWidget> createState() => _EditingWidgetState();
}

class _EditingWidgetState extends State<EditingWidget> {
  late List<String> _items;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant EditingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update _items if the reference actually changed (not just content)
    if (!identical(oldWidget.items, widget.items)) {
      _items = List<String>.from(widget.items);
      // Optionally clear controller if items changed from parent
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle unifiedTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.onPrimaryContainer,
      fontSize: 16,
    );

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
                  label: Text(
                    AppLocalizations.of(context)!.enterAnItem,
                    style: unifiedTextStyle,
                  ),
                  alignLabelWithHint: true,
                ),
                controller: _controller,
                style: unifiedTextStyle,
                onSubmitted: (String value) {
                  if (value.trim().isNotEmpty) {
                    setState(() {
                      _items.add(value.trim());
                    });
                    widget.onItemsChanged(List<String>.from(_items));
                    _controller.clear();
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
                if (_controller.text.trim().isNotEmpty) {
                  setState(() {
                    _items.add(_controller.text.trim());
                  });
                  widget.onItemsChanged(List<String>.from(_items));
                  _controller.clear();
                }
              },
              child: Text(
                AppLocalizations.of(context)!.add,
                style: unifiedTextStyle,
              ),
            ),
            const SizedBox(height: 10),
            buildListView(context, unifiedTextStyle),
          ],
        ),
      ),
    );
  }

  SizedBox buildListView(BuildContext context, TextStyle unifiedTextStyle) {
    return SizedBox(
      height: (_items.length * 48.0).clamp(48.0, 300.0),
      child: ReorderableListView(
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
          widget.onItemsChanged(List<String>.from(_items));
        },
        children: [
          for (int index = 0; index < _items.length; index++)
            Row(
              key: ValueKey('item_$index'),
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle_outline_sharp, size: 18),
                          SizedBox(width: 8),
                          Text('Remove'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      setState(() {
                        _controller.text = _items[index];
                        _items.removeAt(index);
                      });
                      widget.onItemsChanged(List<String>.from(_items));
                    } else if (value == 'remove') {
                      setState(() {
                        _items.removeAt(index);
                      });
                      widget.onItemsChanged(List<String>.from(_items));
                    }
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 2.0,
                    ),
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
                          TextSpan(
                            text: _items[index],
                            style: unifiedTextStyle,
                          ),
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
