part of 'dashboard_bloc.dart';

@immutable
sealed class DashboardEvent {}

class DashBoardInitialFetchEvent extends DashboardEvent {}

class DashBoardDepositEvent extends DashboardEvent {
  final TransactionModel transactionModel;

  DashBoardDepositEvent({required this.transactionModel});
  
}


class DashBoardWithdrawEvent extends DashboardEvent {
  final TransactionModel transactionModel;

  DashBoardWithdrawEvent({required this.transactionModel});
  
}