import 'package:bloc/bloc.dart';
import 'package:wallet/counter/infrastructure/counter_repository.dart';

class CounterCubit extends Cubit<double> {
  CounterCubit() : super(0);

  void decrement() => emit(state - 1);
  void increment() => emit(state + 1);

  void calculate() {
    final data = CounterRepository.getIncomeExpenseList();
    emit(
      data
          .map((e) => e.amount)
          .toList()
          .reduce((value, element) => value + element),
    );
  }
}
