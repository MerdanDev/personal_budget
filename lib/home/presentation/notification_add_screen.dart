import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wallet/home/application/notification_cubit.dart';
import 'package:wallet/l10n/l10n.dart';

class NotificationAddScreen extends StatefulWidget {
  const NotificationAddScreen({super.key});

  @override
  State<NotificationAddScreen> createState() => _NotificationAddScreenState();
}

class _NotificationAddScreenState extends State<NotificationAddScreen> {
  DateTime date = DateTime.now();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final dateFormat = DateFormat('y-mm-dd');
  final timeFormat = DateFormat('hh-mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.addNotification),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        this.date = this.date.copyWith(
                              year: date.year,
                              month: date.month,
                              day: date.day,
                            );
                      });
                    }
                  },
                  child: Text(
                    dateFormat.format(date),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        date = date.copyWith(
                          hour: time.hour,
                          minute: time.minute,
                        );
                      });
                    }
                  },
                  child: Text(
                    timeFormat.format(date),
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: context.l10n.notificationTitle,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _bodyController,
            decoration: InputDecoration(
              hintText: context.l10n.notificationBody,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () {
              NotificationCubit.instance.addNotification(
                dateTime: date,
                title: _titleController.text.isNotEmpty
                    ? _titleController.text
                    : null,
                body: _bodyController.text.isNotEmpty
                    ? _bodyController.text
                    : null,
              );
              Navigator.pop(context);
            },
            child: Text(context.l10n.save),
          ),
        ),
      ),
    );
  }
}
