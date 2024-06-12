import 'package:flutter/material.dart';
import 'package:wallet/counter/cubit/category_cubit.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/l10n/l10n.dart';

class AddCounterCategoryDialog extends StatefulWidget {
  const AddCounterCategoryDialog({
    required this.isMinus,
    this.value,
    super.key,
  });
  final bool isMinus;
  final CounterCategory? value;

  @override
  State<AddCounterCategoryDialog> createState() =>
      _AddCounterCategoryDialogState();
}

class _AddCounterCategoryDialogState extends State<AddCounterCategoryDialog> {
  final TextEditingController controller = TextEditingController();
  int? iconCode;
  int? colorCode;

  @override
  void initState() {
    if (widget.value != null) {
      controller.text = widget.value!.name;
      iconCode = widget.value!.iconCode;
      colorCode = widget.value!.colorCode;
    }
    super.initState();
  }

  void onSubmit() {
    if (widget.value != null) {
      CounterCategoryCubit.instance.updateCategory(
        uuid: widget.value!.uuid,
        name: controller.text,
        colorCode: colorCode,
        iconCode: iconCode,
      );
      Navigator.pop(
        context,
      );
    } else if (controller.text.isNotEmpty) {
      CounterCategoryCubit.instance.addCategory(
        name: controller.text,
        type: widget.isMinus ? CategoryType.expense : CategoryType.income,
        colorCode: colorCode,
        iconCode: iconCode,
      );
      Navigator.pop(
        context,
      );
    }
  }

  Future<void> onPressedForIcon() async {
    final value = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        // start: 0xe089
        // end: 0xe0e3
        return const IconSelectorBottomSheet();
      },
    );
    if (value != null) {
      setState(() {
        iconCode = value;
      });
    }
  }

  Future<void> onPressedForColor() async {
    final value = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        // start: 0xe089
        // end: 0xe0e3
        return ColorSelectorBottomSheet(
          colorCode: colorCode,
        );
      },
    );
    if (value != null) {
      setState(() {
        colorCode = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconButtonText = Text(context.l10n.icon);
    final colorButtonText = Text(context.l10n.color);
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(),
        resizeToAvoidBottomInset: false,
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              style: const TextStyle(
                fontSize: 20,
              ),
              decoration: InputDecoration(
                hintText: context.l10n.inputName,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.onPrimary,
                    width: 3,
                  ),
                ),
              ),
              // onSubmitted: () {},
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: iconCode != null
                      ? ElevatedButton.icon(
                          onPressed: onPressedForIcon,
                          icon: Icon(
                            IconData(
                              iconCode!,
                              fontFamily: 'MaterialIcons',
                            ),
                          ),
                          label: iconButtonText,
                        )
                      : ElevatedButton(
                          onPressed: onPressedForIcon,
                          child: iconButtonText,
                        ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: colorCode != null
                      ? ElevatedButton.icon(
                          onPressed: onPressedForColor,
                          icon: SizedBox(
                            height: 24,
                            width: 24,
                            child: ColoredBox(color: Color(colorCode!)),
                          ),
                          label: colorButtonText,
                        )
                      : ElevatedButton(
                          onPressed: onPressedForColor,
                          child: colorButtonText,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onSubmit,
              child: Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

class IconSelectorBottomSheet extends StatelessWidget {
  const IconSelectorBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 50,
      ),
      children: List.generate(0xf4dd - 0xe000, (index) {
        return IconButton(
          onPressed: () {
            Navigator.pop(context, 0xe089 + index);
          },
          icon: Icon(
            IconData(
              0xe089 + index,
              fontFamily: 'MaterialIcons',
            ),
            size: 30,
          ),
        );
      }),
    );
  }
}

class ColorSelectorBottomSheet extends StatefulWidget {
  const ColorSelectorBottomSheet({
    super.key,
    this.colorCode,
  });

  final int? colorCode;

  @override
  State<ColorSelectorBottomSheet> createState() =>
      _ColorSelectorBottomSheetState();
}

class _ColorSelectorBottomSheetState extends State<ColorSelectorBottomSheet> {
  int red = 0;

  int green = 0;

  int blue = 0;

  @override
  void initState() {
    if (widget.colorCode != null) {
      final color = Color(widget.colorCode!);
      red = color.red;
      green = color.green;
      blue = color.blue;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Color.fromARGB(255, red, green, blue),
              ),
            ),
          ),
        ),
        const Divider(),
        Row(
          children: [
            const SizedBox(
              height: 50,
              width: 50,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: ColoredBox(color: Colors.red),
              ),
            ),
            Expanded(
              child: Slider(
                value: red / 255,
                // divisions: 256,
                onChanged: (value) {
                  setState(() {
                    red = (value * 255).toInt();
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            const SizedBox(
              height: 50,
              width: 50,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: ColoredBox(color: Colors.green),
              ),
            ),
            Expanded(
              child: Slider(
                value: green / 255,
                // divisions: 256,
                onChanged: (value) {
                  setState(() {
                    green = (value * 255).toInt();
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            const SizedBox(
              height: 50,
              width: 50,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: ColoredBox(color: Colors.blue),
              ),
            ),
            Expanded(
              child: Slider(
                value: blue / 255,
                divisions: 256,
                onChanged: (value) {
                  setState(() {
                    blue = (value * 255).toInt();
                  });
                },
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                Color.fromARGB(255, red, green, blue).value,
              );
            },
            child: Text(context.l10n.save),
          ),
        ),
      ],
    );
  }
}
