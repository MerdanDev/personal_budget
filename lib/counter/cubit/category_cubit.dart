import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/infrastructure/counter_repository.dart';

class CounterCategoryCubit extends Cubit<List<CounterCategory>> {
  factory CounterCategoryCubit() => instance;
  CounterCategoryCubit._internal() : super([]) {
    final categories = CounterRepository.getCounterCategoryList();
    emit(categories);
  }

  static CounterCategoryCubit instance = CounterCategoryCubit._internal();

  void addCategory({
    required String name,
    required CategoryType type,
    int? colorCode,
    int? iconCode,
  }) {
    final uuid = const Uuid().v1();
    final now = DateTime.now();
    final categories = [
      ...state,
      CounterCategory(
        uuid: uuid,
        name: name,
        type: type,
        colorCode: colorCode,
        iconCode: iconCode,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    CounterRepository.setCounterCategoryList(categories);
    emit(categories);
  }

  void updateCategory({
    required String uuid,
    String? name,
    int? colorCode,
    int? iconCode,
  }) {
    final now = DateTime.now();
    final element = state.firstWhere(
      (element) => element.uuid == uuid,
    );
    final index = state.indexWhere((element) => element.uuid == uuid);
    final update = [...state]
      ..removeAt(index)
      ..insert(
        index,
        element.copyWith(
          name: name,
          colorCode: colorCode,
          iconCode: iconCode,
          updatedAt: now,
        ),
      );
    CounterRepository.setCounterCategoryList(update);
    CounterBloc.instance.add(CategoryUpdate(category: update[index]));
    emit(update);
  }

  void deleteCategory({required String uuid}) {
    final update = [...state]..removeWhere((element) => element.uuid == uuid);
    CounterRepository.setCounterCategoryList(update);
    CounterBloc.instance.add(CategoryDelete(uuid: uuid));
    emit(update);
  }

  List<CounterCategory> restoreBackup(List<CounterCategory> categoryList) {
    final categories = [...state];
    final updateList = <CounterCategory>[];

    for (final category in categoryList) {
      final elements = state.where(
        (element) => element.uuid == category.uuid,
      );
      final compare = elements.firstOrNull?.updatedAt.compareTo(
        category.updatedAt,
      );
      if (compare != null && compare != 0) {
        final element = elements.first;

        final index = state.indexWhere(
          (element) => element.uuid == category.uuid,
        );
        categories
          ..removeAt(index)
          ..insert(
            index,
            compare > 0 ? element : category,
          );
        updateList.add(compare > 0 ? element : category);
      } else if (compare == null) {
        categories.add(category);
      }
    }
    CounterRepository.setCounterCategoryList(categories);
    emit(categories);
    return updateList;
  }
}
