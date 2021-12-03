import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_budget/bloc/balance_bloc.dart';
import 'package:personal_budget/models/tbl_mv_acc_type.dart';
import 'package:personal_budget/models/tbl_mv_category.dart';

class NewValueScreen extends StatefulWidget {
  final List<TblMvCategory> categories;
  final List<TblMvAccType> accounts;
  final TblMvCategory? category;
  final int type;
  const NewValueScreen({
    Key? key,
    required this.categories,
    required this.accounts,
    required this.type,
    this.category,
  }) : super(key: key);

  @override
  _NewValueScreenState createState() => _NewValueScreenState();
}

class _NewValueScreenState extends State<NewValueScreen> {
  int? selected;
  int? accIndex;
  TextEditingController controller = TextEditingController();
  TextEditingController desc = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New value'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: Theme.of(context).primaryColor,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'VALUE',
                  hintStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.monetization_on_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  contentPadding: EdgeInsets.all(8.0),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: desc,
                cursorColor: Theme.of(context).primaryColor,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                ),
                onSubmitted: (String? text) {
                  if (controller.text.isNotEmpty &&
                      selected != null &&
                      accIndex != null) {
                    if (widget.type == -1) {
                      BlocProvider.of<BalanceBloc>(context).add(
                        AddExpenseEvent(
                          value: double.parse(controller.text),
                          catId: widget.categories[selected!].id,
                          accId: widget.accounts[accIndex!].id,
                          text: desc.text,
                        ),
                      );
                    } else if (widget.type == 1) {
                      BlocProvider.of<BalanceBloc>(context).add(
                        AddIncomeEvent(
                          value: double.parse(controller.text),
                          catId: widget.categories[selected!].id,
                          accId: widget.accounts[accIndex!].id,
                          text: desc.text,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Value and category are required!',
                        ),
                      ),
                    );
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Description',
                  hintStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.note_alt_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  contentPadding: EdgeInsets.all(8.0),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Account types:',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.all(8.0),
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: accIndex != null && accIndex == index
                          ? Colors.grey[300]
                          : Colors.transparent,
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.all(0.0),
                      ),
                      onPressed: () {
                        setState(() {
                          accIndex = index;
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: Image.memory(widget.accounts[index].image),
                          ),
                          Container(
                            child: Text(
                              widget.accounts[index].name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                // fontSize: 10,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                itemCount: widget.accounts.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Categories:',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 2 / 2.2,
              crossAxisCount: 4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Container(
                  margin: EdgeInsets.all(8.0),
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: selected != null && selected == index
                        ? Colors.grey[300]
                        : Colors.transparent,
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(0.0),
                    ),
                    onPressed: () {
                      setState(() {
                        selected = index;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Image.memory(widget.categories[index].image),
                        ),
                        Container(
                          child: Text(
                            widget.categories[index].name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              // fontSize: 10,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
              childCount: widget.categories.length,
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 75,
        width: 75,
        child: FloatingActionButton(
          onPressed: () {
            if (controller.text.isNotEmpty &&
                selected != null &&
                accIndex != null) {
              if (widget.type == -1) {
                BlocProvider.of<BalanceBloc>(context).add(
                  AddExpenseEvent(
                    value: double.parse(controller.text),
                    catId: widget.categories[selected!].id,
                    accId: widget.accounts[accIndex!].id,
                    text: desc.text,
                  ),
                );
              } else if (widget.type == 1) {
                BlocProvider.of<BalanceBloc>(context).add(
                  AddIncomeEvent(
                    value: double.parse(controller.text),
                    catId: widget.categories[selected!].id,
                    accId: widget.accounts[accIndex!].id,
                    text: desc.text,
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Value and category are required!',
                  ),
                ),
              );
            }
          },
          child: Icon(
            Icons.save,
            size: 50,
          ),
        ),
      ),
    );
  }
}
