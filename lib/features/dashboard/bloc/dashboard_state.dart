part of 'dashboard_bloc.dart';

@immutable
sealed class DashboardState {}

final class DashboardInitial extends DashboardState {}

final class DashboardLoadingState extends DashboardState {}

final class DashboardErrorState extends DashboardState {}

final class DashboardSuccessState extends DashboardState {
  final List<TransactionModel> transactions;
  final int balance;

  DashboardSuccessState({required this.transactions, required this.balance});

  
}
