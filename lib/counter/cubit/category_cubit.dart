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
}
