import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:personal_budget/bloc/data_bloc.dart';
import 'package:personal_budget/models/tbl_mv_category.dart';
import 'package:personal_budget/models/tbl_mv_expense.dart';
import 'package:personal_budget/models/tbl_mv_income.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class CategoryScreen extends StatefulWidget {
  final TblMvCategory category;
  const CategoryScreen({Key? key, required this.category}) : super(key: key);

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: BlocBuilder<DataBloc, DataState>(builder: (context, state) {
        if (state is LoadedExpenseState) {
          ExpenseDataSource _dataSource =
              ExpenseDataSource(expenses: state.expenses);
          return SfDataGrid(
            source: _dataSource,
            allowEditing: true,
            selectionMode: SelectionMode.single,
            navigationMode: GridNavigationMode.cell,
            editingGestureType: EditingGestureType.tap,
            columns: [
              GridColumn(
                columnName: 'id',
                autoFitPadding: EdgeInsets.all(10.0),
                width: 50,
                label: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: Text(
                    'ID',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              GridColumn(
                columnName: 'value',
                autoFitPadding: EdgeInsets.all(10.0),
                width: 100,
                label: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Value',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              GridColumn(
                columnName: 'desc',
                width: width < 690 ? 200 : width - 490,
                autoFitPadding: EdgeInsets.all(10.0),
                label: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Description',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              GridColumn(
                columnName: 'created_date',
                autoFitPadding: EdgeInsets.all(10.0),
                width: 170,
                label: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Created Date',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              GridColumn(
                columnName: 'modified_date',
                autoFitPadding: EdgeInsets.all(10.0),
                width: 170,
                label: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Modified Date',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        } else if (state is LoadedIncomeState) {
          IncomeDataSource _dataSource =
              IncomeDataSource(incomes: state.incomes);
          return SfDataGrid(
            source: _dataSource,
            allowEditing: true,
            selectionMode: SelectionMode.single,
            navigationMode: GridNavigationMode.cell,
            editingGestureType: EditingGestureType.tap,
            columns: [
              GridColumn(
                columnName: 'id',
                autoFitPadding: EdgeInsets.all(10.0),
                width: 50,
                label: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: Text(
                    'ID',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              GridColumn(
                columnName: 'value',
                autoFitPadding: EdgeInsets.all(10.0),
                width: 100,
                label: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Value',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              GridColumn(
                columnName: 'desc',
                width: width < 690 ? 200 : width - 490,
                autoFitPadding: EdgeInsets.all(10.0),
                label: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Description',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              GridColumn(
                columnName: 'created_date',
                autoFitPadding: EdgeInsets.all(10.0),
                width: 170,
                label: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Created Date',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              GridColumn(
                columnName: 'modified_date',
                autoFitPadding: EdgeInsets.all(10.0),
                width: 170,
                label: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Modified Date',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        }
        return Container();
      }),
    );
  }
}

class ExpenseDataSource extends DataGridSource {
  ExpenseDataSource({required List<TblMvExpense> expenses}) {
    dataGridRows = expenses
        .map<DataGridRow>(
          (dataGridRow) => DataGridRow(
            cells: [
              DataGridCell<int>(
                columnName: 'id',
                value: dataGridRow.id,
              ),
              DataGridCell<double>(
                columnName: 'value',
                value: dataGridRow.value,
              ),
              DataGridCell<String>(
                columnName: 'desc',
                value: dataGridRow.desc,
              ),
              DataGridCell<Widget>(
                columnName: 'created_date',
                value: Text(
                  dataGridRow.createdDate != null
                      ? DateFormat('yyyy.MM.dd kk:mm:ss')
                          .format(dataGridRow.createdDate!)
                      : 'no date',
                ),
              ),
              DataGridCell<Widget>(
                columnName: 'modified_date',
                value: Text(
                  dataGridRow.modifiedDate != null
                      ? DateFormat('yyyy.MM.dd kk:mm:ss')
                          .format(dataGridRow.modifiedDate!)
                      : 'no date',
                ),
              ),
            ],
          ),
        )
        .toList();
  }

  dynamic newCellValue;

  /// Help to control the editable text in [TextField] widget.
  TextEditingController editingController = TextEditingController();

  @override
  Widget? buildEditWidget(
    DataGridRow dataGridRow,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
    CellSubmit submitCell,
  ) {
    // Text going to display on editable widget
    final String displayText = dataGridRow
            .getCells()
            .firstWhere((DataGridCell dataGridCell) =>
                dataGridCell.columnName == column.columnName)
            .value
            ?.toString() ??
        '';

    // The new cell value must be reset.
    // To avoid committing the [DataGridCell] value that was previously edited
    // into the current non-modified [DataGridCell].
    newCellValue = null;

    final bool isNumericType =
        column.columnName == 'id' || column.columnName == 'salary';

    return Container(
      padding: const EdgeInsets.all(8.0),
      alignment: isNumericType ? Alignment.centerRight : Alignment.centerLeft,
      child: TextField(
        autofocus: true,
        controller: editingController..text = displayText,
        textAlign: isNumericType ? TextAlign.right : TextAlign.left,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 16.0),
        ),
        keyboardType: isNumericType ? TextInputType.number : TextInputType.text,
        onChanged: (String value) {
          if (value.isNotEmpty) {
            if (isNumericType) {
              newCellValue = int.parse(value);
            } else {
              newCellValue = value;
            }
          } else {
            newCellValue = null;
          }
        },
        onSubmitted: (String value) {
          // In Mobile Platform.
          // Call [CellSubmit] callback to fire the canSubmitCell and
          // onCellSubmit to commit the new value in single place.
          submitCell();
        },
      ),
    );
  }

  @override
  bool onCellBeginEdit(
    DataGridRow dataGridRow,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
  ) {
    if (column.columnName == 'value') {
      // Return false, to restrict entering into the editing.
      return true;
    } else if (column.columnName == 'desc') {
      return true;
    } else {
      return false;
    }
  }

  @override
  void onCellSubmit(
    DataGridRow dataGridRow,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
  ) {
    final dynamic oldValue = dataGridRow
            .getCells()
            .firstWhere((DataGridCell dataGridCell) =>
                dataGridCell.columnName == column.columnName)
            .value ??
        '';

    final int dataRowIndex = dataGridRows.indexOf(dataGridRow);

    if (newCellValue == null || oldValue == newCellValue) {
      return;
    }

    // if (column.columnName == 'value') {
    //   dataGridRows[dataRowIndex].getCells();
    // }
  }

  List<DataGridRow> dataGridRows = [];

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((dataGridCell) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: dataGridCell.value is Widget
            ? dataGridCell.value
            : dataGridCell.columnName == 'value'
                ? Text(
                    dataGridCell.value.toString(),
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    dataGridCell.value.toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
      );
    }).toList());
  }
}

class IncomeDataSource extends DataGridSource {
  IncomeDataSource({required List<TblMvIncome> incomes}) {
    dataGridRows = incomes
        .map<DataGridRow>(
          (dataGridRow) => DataGridRow(
            cells: [
              DataGridCell<int>(
                columnName: 'id',
                value: dataGridRow.id,
              ),
              DataGridCell<double>(
                columnName: 'value',
                value: dataGridRow.value,
              ),
              DataGridCell<String>(
                columnName: 'desc',
                value: dataGridRow.desc,
              ),
              DataGridCell<Widget>(
                columnName: 'created_date',
                value: Text(
                  dataGridRow.createdDate != null
                      ? DateFormat('yyyy.MM.dd kk:mm:ss')
                          .format(dataGridRow.createdDate!)
                      : 'no date',
                ),
              ),
              DataGridCell<Widget>(
                columnName: 'modified_date',
                value: Text(
                  dataGridRow.modifiedDate != null
                      ? DateFormat('yyyy.MM.dd kk:mm:ss')
                          .format(dataGridRow.modifiedDate!)
                      : 'no date',
                ),
              ),
            ],
          ),
        )
        .toList();
  }
  dynamic newCellValue;

  /// Help to control the editable text in [TextField] widget.
  TextEditingController editingController = TextEditingController();

  @override
  Widget? buildEditWidget(
    DataGridRow dataGridRow,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
    CellSubmit submitCell,
  ) {
    // Text going to display on editable widget
    final String displayText = dataGridRow
            .getCells()
            .firstWhere((DataGridCell dataGridCell) =>
                dataGridCell.columnName == column.columnName)
            .value
            ?.toString() ??
        '';

    // The new cell value must be reset.
    // To avoid committing the [DataGridCell] value that was previously edited
    // into the current non-modified [DataGridCell].
    newCellValue = null;

    final bool isNumericType =
        column.columnName == 'id' || column.columnName == 'salary';

    return Container(
      padding: const EdgeInsets.all(8.0),
      alignment: isNumericType ? Alignment.centerRight : Alignment.centerLeft,
      child: TextField(
        autofocus: true,
        controller: editingController..text = displayText,
        textAlign: isNumericType ? TextAlign.right : TextAlign.left,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 16.0),
        ),
        keyboardType: isNumericType ? TextInputType.number : TextInputType.text,
        onChanged: (String value) {
          if (value.isNotEmpty) {
            if (isNumericType) {
              newCellValue = int.parse(value);
            } else {
              newCellValue = value;
            }
          } else {
            newCellValue = null;
          }
        },
        onSubmitted: (String value) {
          // In Mobile Platform.
          // Call [CellSubmit] callback to fire the canSubmitCell and
          // onCellSubmit to commit the new value in single place.
          submitCell();
        },
      ),
    );
  }

  @override
  bool onCellBeginEdit(
    DataGridRow dataGridRow,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
  ) {
    if (column.columnName == 'value') {
      // Return false, to restrict entering into the editing.
      return true;
    } else if (column.columnName == 'desc') {
      return true;
    } else {
      return false;
    }
  }

  List<DataGridRow> dataGridRows = [];

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((dataGridCell) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(10.0),
        child: dataGridCell.value is Widget
            ? dataGridCell.value
            : dataGridCell.columnName == 'value'
                ? Text(
                    dataGridCell.value.toString(),
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    dataGridCell.value.toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
      );
    }).toList());
  }
}
