import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wallet/counter/presentation/counter_page.dart';
import 'package:wallet/home/application/notification_cubit.dart';
import 'package:wallet/home/domain/scheduled_notification.dart';
import 'package:wallet/home/presentation/notification_add_screen.dart';
import 'package:wallet/l10n/l10n.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        actions: [
          IconButton(
            onPressed: () async {
              // NotificationCubit.instance.addNotification(dateTime: dateTime);
              await Navigator.push(
                context,
                MaterialPageRoute<NotificationAddScreen>(
                  builder: (context) => const NotificationAddScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notification_add_outlined),
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, List<ScheduledNotification>>(
        bloc: NotificationCubit.instance,
        builder: (context, state) {
          return ListView.builder(
            itemBuilder: (context, index) {
              final notification = state[index];
              final format = DateFormat(
                'y MMMM d hh:mm',
                context.l10n.localeName,
              );
              return Dismissible(
                key: Key(notification.id.toString()),
                background: ColoredBox(
                  color: Colors.red.withOpacity(0.4),
                ),
                confirmDismiss: (direction) async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return const DeleteDialog();
                    },
                  );
                  return result;
                },
                onDismissed: (direction) {
                  NotificationCubit.instance.deleteNotification(
                    notification.id,
                  );
                },
                child: ListTile(
                  title: Text(
                    '${format.format(notification.dateTime)} - '
                    '${notification.title}',
                  ),
                  subtitle: Text(notification.body ?? ''),
                ),
              );
            },
            itemCount: state.length,
          );
        },
      ),
    );
  }
}
