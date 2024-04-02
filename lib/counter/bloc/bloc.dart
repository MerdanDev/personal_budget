import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/core/utils.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/date_filter.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/counter/infrastructure/counter_repository.dart';

part 'event.dart';
part 'state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc()
      : super(
          const CounterState(
            data: [],
            dateFilter: DateFilter.all,
            loading: true,
          ),
        ) {
    on<InitEvent>(
      (event, emit) {
        // get data from cache;
        final dataFromCache = CounterRepository.getIncomeExpenseList();
        data.addAll(dataFromCache);
        // get date filter from cache;
        dateFilter = CounterRepository.getDateFilter();
        // complete loading;
        emit(
          CounterState(
            loading: false,
            dateFilter: dateFilter,
            data: [...filterByDate()],
          ),
        );
      },
    );
    on<IncomeExpenseEvent>((event, emit) {
      final now = DateTime.now();
      data.add(
        IncomeExpense(
          uuid: event.uuid,
          amount: event.amount,
          title: event.title,
          category: event.category,
          description: event.description,
          createdAt: now,
          updatedAt: now,
        ),
      );

      CounterRepository.setIncomeExpenseList(data);
      emit(
        CounterState(
          data: [...filterByDate()],
          dateFilter: dateFilter,
          loading: false,
        ),
      );
    });

    on<UpdateIncomeExpenseEvent>(
      (event, emit) {
        final now = DateTime.now();
        final element = data.firstWhere(
          (element) => element.uuid == event.uuid,
        );
        final index = data.indexWhere((element) => element.uuid == event.uuid);
        data
          ..removeAt(index)
          ..insert(
            index,
            element.copyWith(
              amount: event.amount,
              category: event.category,
              title: event.title,
              description: event.description,
              updatedAt: now,
            ),
          );

        CounterRepository.setIncomeExpenseList(data);
        emit(
          CounterState(
            data: [...filterByDate()],
            dateFilter: dateFilter,
            loading: false,
          ),
        );
      },
    );

    on<RemoveEvent>(
      (event, emit) {
        data.removeWhere((element) => element.uuid == event.uuid);

        CounterRepository.setIncomeExpenseList(data);
        emit(
          CounterState(
            data: [...filterByDate()],
            dateFilter: dateFilter,
            loading: false,
          ),
        );
      },
    );

    on<ChangeDateFilter>((event, emit) {
      dateFilter = event.dateFilter;
      CounterRepository.setDateFilter(event.dateFilter);
      final filteredData = filterByDate();
      emit(
        CounterState(
          data: [...filteredData],
          dateFilter: dateFilter,
          loading: false,
        ),
      );
    });

    add(InitEvent());
  }

  final List<IncomeExpense> data = [];
  DateFilter dateFilter = DateFilter.all;

  List<IncomeExpense> filterByDate() {
    return data.reversed.where(
      (element) {
        final now = DateTime.now();
        print('Is same week ${isSameWeek(
          now,
          element.createdAt,
        )} now:$now, '
            'element:${element.createdAt}');
        if (dateFilter == DateFilter.all) {
          return true;
        } else if (dateFilter == DateFilter.year &&
            element.createdAt.year == now.year) {
          return true;
        } else if (dateFilter == DateFilter.month &&
            isSameMonth(
              now,
              element.createdAt,
            )) {
          return true;
        } else if (dateFilter == DateFilter.week &&
            isSameWeek(
              now,
              element.createdAt,
            )) {
          return true;
        } else if (dateFilter == DateFilter.day &&
            isSameDay(
              now,
              element.createdAt,
            )) {
          return true;
        } else {
          return false;
        }
      },
    ).toList();
  }
}
