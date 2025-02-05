import 'package:flutter/cupertino.dart';

class EditingWidget extends StatelessWidget {
  const EditingWidget(
      {Key? key,
      required List<String> items,
      required Function(List<String>) onItemsChanged})
      : _items = items,
        _onItemsChanged = onItemsChanged,
        super(key: key);

  final List<String> _items;
  final Function(List<String>) _onItemsChanged;

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CupertinoTextField(
          controller: controller,
          placeholder: 'Vul item in',
          onSubmitted: (String value) {
            _onItemsChanged([..._items, value]);
          },
        ),
        CupertinoButton(
          child: const Text('Voeg toe'),
          onPressed: () {
            if (controller.text.isNotEmpty) {
              _onItemsChanged([..._items, controller.text]);
              controller.clear();
            }
          },
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _items.length,
          itemBuilder: (context, index) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(_items[index]),
                CupertinoButton(
                  child: const Text('Verwijder'),
                  onPressed: () {
                    _onItemsChanged([..._items]..removeAt(index));
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
