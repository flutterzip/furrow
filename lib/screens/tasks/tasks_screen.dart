import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';

/// Jobs around the farm. Tick them off, swipe them away, add new ones.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final title = TextEditingController();
  String? fieldId;

  /// The field the last task went to, shown until the next one is started.
  String? addedTo;

  String due(DateTime d) {
    final days = dateOnly(d).difference(dateOnly(ref.read(clockProvider)())).inDays;
    return switch (days) { < 0 => 'Overdue', 0 => 'Today', 1 => 'Tomorrow', _ => weekday(d) };
  }

  void remove(Task t) {
    final undo = ref.read(tasksProvider.notifier).remove(t.id);
    if (undo == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('"${t.title}" deleted'),
        action: SnackBarAction(label: 'Undo', onPressed: () => ref.read(tasksProvider.notifier).restore(undo.$1, undo.$2)),
      ));
  }

  void add() {
    if (title.text.trim().isEmpty || fieldId == null) return;
    ref.read(tasksProvider.notifier).add(title.text, fieldId!, ref.read(clockProvider)());
    title.clear();
    setState(() {
      addedTo = fieldId;
      fieldId = null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final tasks = ref.watch(sortedTasksProvider);
    final left = tasks.where((t) => !t.done).length;
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 12, Tokens.gutter, 130),
      children: [
        Text('Tasks', style: text.headlineSmall),
        Text(left == 0 ? 'All done. Go and have a cup of tea.' : '$left left to do. Tap one when it is done.', style: text.bodyMedium),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.card.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: title,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (v) => setState(() {
                  if (v.isNotEmpty) addedTo = null;
                }),
                onSubmitted: (_) => add(),
                style: text.bodyLarge!.copyWith(color: p.ink),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Add a task, like "Check the pump"',
                  hintStyle: text.bodyLarge!.copyWith(color: p.muted),
                ),
              ),
              const SizedBox(height: 12),
              Choices<String>(
                values: [for (final f in seed.fields) f.id],
                value: fieldId ?? '',
                label: (id) => seed.field(id).name,
                onChanged: (id) => setState(() {
                  fieldId = id;
                  addedTo = null;
                }),
              ),
              const SizedBox(height: 12),
              // Adding breaks the button into fragments that fly together as
              // the note of where the task went.
              ParticleMorph(
                child: addedTo != null
                    ? Container(
                        key: const ValueKey('added'),
                        height: Tokens.buttonHeight,
                        decoration: BoxDecoration(color: p.accentWash, borderRadius: BorderRadius.circular(Tokens.buttonRadius)),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 20, color: p.accentDeep),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Added to ${seed.field(addedTo!).name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelLarge!.copyWith(color: p.accentDeep),
                              ),
                            ),
                          ],
                        ),
                      )
                    : FurrowButton(
                        key: const ValueKey('add'),
                        label: fieldId == null ? 'Pick a field to add it' : 'Add task',
                        icon: Icons.add_rounded,
                        onPressed: title.text.trim().isEmpty || fieldId == null ? null : add,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final t in tasks) ...[
          Dismissible(
            key: ValueKey(t.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => remove(t),
            background: Container(
              decoration: BoxDecoration(color: p.accentWash, borderRadius: BorderRadius.circular(Tokens.fieldRadius + 2)),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 22),
              child: Icon(Icons.delete_outline_rounded, color: p.accentDeep),
            ),
            child: TaskTile(
              title: t.title,
              subtitle: '${seed.field(t.fieldId).name} · ${t.done ? 'Done' : due(t.due)}',
              done: t.done,
              onToggle: () => ref.read(tasksProvider.notifier).toggle(t.id),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }
}
