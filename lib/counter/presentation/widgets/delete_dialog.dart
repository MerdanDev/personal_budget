import 'package:flutter/material.dart';
import 'package:wallet/l10n/l10n.dart';

class DeleteDialog extends StatelessWidget {
  const DeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      icon: const Icon(Icons.info_outline),
      title: Text(context.l10n.deleteTitle),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text(context.l10n.yes),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text(context.l10n.no),
        ),
      ],
    );
  }
}
