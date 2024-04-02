import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/domain/income_expense.dart';

class IncomeExpenseDialog extends StatefulWidget {
  const IncomeExpenseDialog({
    required this.isMinus,
    this.value,
    super.key,
  });

  final bool isMinus;
  final IncomeExpense? value;

  @override
  State<IncomeExpenseDialog> createState() => _IncomeExpenseDialogState();
}

class _IncomeExpenseDialogState extends State<IncomeExpenseDialog> {
  final TextEditingController mainController = TextEditingController();
  final TextEditingController secondaryController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void onSubmit(String value) {
    final main = mainController.text;
    final secondary = secondaryController.text;
    final title = titleController.text;
    final description = descriptionController.text;
    if (main.isNotEmpty || secondary.isNotEmpty) {
      final amount = (main.isNotEmpty ? int.parse(main) : 0) +
          (secondary.isNotEmpty ? int.parse(secondary) : 0) * 0.01;
      if (widget.value != null) {
        context.read<CounterBloc>().add(
              UpdateIncomeExpenseEvent(
                uuid: widget.value!.uuid,
                amount: widget.isMinus ? amount * -1 : amount,
                title: title.isNotEmpty ? title : null,
                description: description.isNotEmpty ? description : null,
              ),
            );
      } else {
        context.read<CounterBloc>().add(
              IncomeExpenseEvent(
                amount: widget.isMinus ? amount * -1 : amount,
                title: title.isNotEmpty ? title : null,
                description: description.isNotEmpty ? description : null,
              ),
            );
      }
    }
    Navigator.pop(context);
  }

  @override
  void initState() {
    if (widget.value != null) {
      final stringDouble = widget.value!.amount.toString();
      final parts = stringDouble.replaceAll('-', '').split('.');
      mainController.text = parts.first;
      secondaryController.text = parts.last;
    }
    if (widget.value?.title != null) {
      titleController.text = widget.value!.title!;
    }
    if (widget.value?.description != null) {
      descriptionController.text = widget.value!.description!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(),
        resizeToAvoidBottomInset: false,
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: mainController,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 40,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixIcon: widget.isMinus
                            ? const Icon(
                                Icons.remove,
                                color: Colors.redAccent,
                                size: 30,
                              )
                            : const Icon(
                                Icons.add,
                                color: Colors.greenAccent,
                                size: 30,
                              ),
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: secondaryController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      maxLength: 2,
                      style: const TextStyle(
                        fontSize: 40,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: '00',
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
                      onSubmitted: onSubmit,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: titleController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                style: const TextStyle(
                  fontSize: 20,
                ),
                decoration: InputDecoration(
                  hintText: 'title',
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
                onSubmitted: onSubmit,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: descriptionController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                maxLines: 5,
                style: const TextStyle(
                  fontSize: 20,
                ),
                decoration: InputDecoration(
                  hintText: 'description',
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
                onSubmitted: onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
