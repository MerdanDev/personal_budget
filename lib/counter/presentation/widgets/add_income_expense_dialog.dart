import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/cubit/category_cubit.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/counter/infrastructure/receipt_scanner_service.dart';
import 'package:wallet/counter/presentation/widgets/add_category_dialog.dart';
import 'package:wallet/counter/presentation/widgets/category_icon_widget.dart';
import 'package:wallet/l10n/l10n.dart';

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
  final TextEditingController descriptionController = TextEditingController();
  CounterCategory? category;
  final categoryTextController = TextEditingController();
  final ReceiptScannerService _scanner = ReceiptScannerService();
  bool _scanning = false;

  /// Explains that scanning is beta and how to take a good-quality photo.
  Future<void> _showScanInfo() async {
    final l10n = context.l10n;
    final tips = [l10n.scanTip1, l10n.scanTip2, l10n.scanTip3, l10n.scanTip4];
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(l10n.scanReceipt)),
              Chip(
                label: Text(l10n.scanBetaBadge),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.scanBetaNotice),
                const SizedBox(height: 16),
                Text(
                  l10n.scanTipsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final tip in tips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  /// Asks the user for a capture source, then runs OCR and pre-fills the form.
  Future<void> _scanReceipt() async {
    if (_scanning) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(context.l10n.scanFromCamera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(context.l10n.scanFromGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    setState(() => _scanning = true);
    try {
      final result = await _scanner.scan(source);
      if (!mounted || result == null) return;
      setState(() {
        if (result.amount != null) {
          final parts = result.amount!.toStringAsFixed(2).split('.');
          mainController.text = parts.first;
          secondaryController.text = parts.last;
        }
        final existing = descriptionController.text.trim();
        descriptionController.text = existing.isEmpty
            ? result.fullText
            : '$existing\n${result.fullText}';
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.scanFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void onSubmit(String value) {
    final main = mainController.text;
    final secondary = secondaryController.text;
    final description = descriptionController.text;
    if (main.isNotEmpty || secondary.isNotEmpty) {
      final amount = (main.isNotEmpty ? int.parse(main) : 0) +
          (secondary.isNotEmpty ? int.parse(secondary) : 0) * 0.01;
      if (widget.value != null) {
        context.read<CounterBloc>().add(
              UpdateIncomeExpenseEvent(
                uuid: widget.value!.uuid,
                amount: widget.isMinus ? amount * -1 : amount,
                description: description.isNotEmpty ? description : null,
                category: category,
              ),
            );
      } else {
        context.read<CounterBloc>().add(
              IncomeExpenseEvent(
                amount: widget.isMinus ? amount * -1 : amount,
                description: description.isNotEmpty ? description : null,
                category: category,
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
      category = widget.value?.category;
      categoryTextController.text = category?.name ?? '';
    }
    if (widget.value?.description != null) {
      descriptionController.text = widget.value!.description!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                onSubmit('');
              },
              child: Text(context.l10n.save),
            ),
          ),
        ),
        resizeToAvoidBottomInset: false,
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanning ? null : _scanReceipt,
                    icon: _scanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.document_scanner),
                    label: Text(
                      _scanning
                          ? context.l10n.scanningReceipt
                          : context.l10n.scanReceipt,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.scanInfo,
                  onPressed: _showScanInfo,
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
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
            const SizedBox(height: 20),
            BlocBuilder<CounterCategoryCubit, List<CounterCategory>>(
              bloc: CounterCategoryCubit.instance,
              builder: (context, state) {
                return DropdownMenu<CounterCategory>(
                  width: width - 40,
                  controller: categoryTextController,
                  initialSelection: category,
                  inputDecorationTheme: InputDecorationTheme(
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
                  onSelected: (value) {
                    setState(() {
                      category = value;
                    });
                  },
                  leadingIcon: category != null && category!.iconCode != null
                      ? CategoryIcon(
                          iconCode: category!.iconCode!,
                          colorCode: category!.colorCode,
                        )
                      : IconButton(
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) {
                                return AddCounterCategoryDialog(
                                  isMinus: widget.isMinus,
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.add),
                        ),
                  dropdownMenuEntries: state
                      .where((element) {
                        return widget.isMinus
                            ? element.type == CategoryType.expense
                            : element.type == CategoryType.income;
                      })
                      .map(
                        (e) => DropdownMenuEntry(
                          value: e,
                          label: e.name,
                          leadingIcon: e.iconCode != null
                              ? CategoryIcon(
                                  iconCode: e.iconCode!,
                                  colorCode: e.colorCode,
                                )
                              : null,
                          trailingIcon: IconButton(
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) {
                                  return AddCounterCategoryDialog(
                                    isMinus: widget.isMinus,
                                    value: e,
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.edit),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              maxLines: 5,
              style: const TextStyle(
                fontSize: 20,
              ),
              decoration: InputDecoration(
                hintText: context.l10n.description,
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
          ],
        ),
      ),
    );
  }
}
