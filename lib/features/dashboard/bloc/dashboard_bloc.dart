import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:exp_manager_dap/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashBoardInitialFetchEvent>(dashBoardInitialFetchEvent);
    on<DashBoardDepositEvent>(dashBoardDepositEvent);
    on<DashBoardWithdrawEvent>(dashBoardWithdrawEvent);
  }

  List<TransactionModel> transactions = [];
  Web3Client? _web3client;
  late ContractAbi _abiCode;
  late EthereumAddress _contractAddress;
  late EthPrivateKey _creds;
  int balance = 0;

  // Functions from smart contract
  late ContractFunction _deposit;
  late ContractFunction _withdraw;
  late ContractFunction _getBalance;
  late ContractFunction _getAllTransactions;

  late DeployedContract _deployedContract;

  // 🧠 INITIAL SETUP + FETCH
  Future<void> dashBoardInitialFetchEvent(
    DashBoardInitialFetchEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoadingState());

    try {
      final String rpcUrl = "http://127.0.0.1:7545";
      final String socketUrl = "ws://127.0.0.1:7545";
      final String privateKey =
          "0x8c45827c338df3348eb2352bbc8600a59b593aa2cff6486493fb3559bf8c35a6";

      _web3client = Web3Client(
        rpcUrl,
        http.Client(),
        socketConnector: () =>
            IOWebSocketChannel.connect(socketUrl).cast<String>(),
      );

      // 🧩 Load ABI from build folder
      String abiFile =
          await rootBundle.loadString('build/contracts/ExpmanagerContract.json');
      var jsonDecoded = jsonDecode(abiFile);
      _abiCode = ContractAbi.fromJson(
        jsonEncode(jsonDecoded['abi']),
        'ExpmanagerContract',
      );

      // 🏠 Contract Address (replace with your latest one after redeploy)
      _contractAddress =
          EthereumAddress.fromHex("0xAC00389bb7c063e53d42CeF5403B2a17c9bF4f35");

      _creds = EthPrivateKey.fromHex(privateKey);
      _deployedContract = DeployedContract(_abiCode, _contractAddress);

      // 🔗 Get functions
      _deposit = _deployedContract.function("deposit");
      _withdraw = _deployedContract.function("withdraw");
      _getBalance = _deployedContract.function("getBalance");
      _getAllTransactions = _deployedContract.function("getAllTransactions");

      // 📦 Fetch all transactions
      final transactionsData = await _web3client!.call(
        contract: _deployedContract,
        function: _getAllTransactions,
        params: [],
      );

      // 💰 Fetch user balance
      final balanceData = await _web3client!.call(
        contract: _deployedContract,
        function: _getBalance,
        params: [
          EthereumAddress.fromHex(
              "0x9eCdac16459B38e7FBDF626E17018435bD5664C2"),
        ],
      );

      // 🧭 Map blockchain data to TransactionModel
      List<TransactionModel> trans = [];
      for (int i = 0; i < transactionsData[0].length; i++) {
        trans.add(
          TransactionModel(
            transactionsData[0][i].toString(), // user address
            transactionsData[1][i].toInt(), // amount
            transactionsData[2][i].toString(), // reason
            DateTime.fromMillisecondsSinceEpoch(
              transactionsData[3][i].toInt() * 1000,
            ),
          ),
        );
      }

      transactions = trans;
      balance = balanceData[0].toInt();

      log("✅ Dashboard data fetched successfully");
      log("Transactions: ${transactions.length}");
      log("Balance: $balance");

      emit(DashboardSuccessState(transactions: transactions, balance: balance));
    } catch (e) {
      log("❌ Error fetching dashboard data: $e");
      emit(DashboardErrorState());
    }
  }

  // 💸 DEPOSIT
  FutureOr<void> dashBoardDepositEvent(
    DashBoardDepositEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      log("🟢 Starting deposit of ${event.transactionModel.amount} wei");

      final transaction = Transaction.callContract(
        from: EthereumAddress.fromHex(
          "0x9eCdac16459B38e7FBDF626E17018435bD5664C2",
        ),
        contract: _deployedContract,
        function: _deposit,
        parameters: [
          event.transactionModel.reason,
        ],
        // Send actual ETH value
        value: EtherAmount.inWei(BigInt.from(event.transactionModel.amount)),
      );

      final result = await _web3client!.sendTransaction(
        _creds,
        transaction,
        chainId: 1337,
        fetchChainIdFromNetworkId: false,
      );

      log("✅ Deposit transaction hash: $result");

      // Optional: Refresh data
      add(DashBoardInitialFetchEvent());
    } catch (e) {
      log("❌ Deposit error: $e");
    }
  }

  // 💰 WITHDRAW
  FutureOr<void> dashBoardWithdrawEvent(
    DashBoardWithdrawEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      log("🔵 Starting withdraw of ${event.transactionModel.amount} wei");

      final transaction = Transaction.callContract(
        from: EthereumAddress.fromHex(
          "0x9eCdac16459B38e7FBDF626E17018435bD5664C2",
        ),
        contract: _deployedContract,
        function: _withdraw,
        parameters: [
          BigInt.from(event.transactionModel.amount),
          event.transactionModel.reason,
        ],
      );

      final result = await _web3client!.sendTransaction(
        _creds,
        transaction,
        chainId: 1337,
        fetchChainIdFromNetworkId: false,
      );

      log("✅ Withdraw transaction hash: $result");

      // Optional: Refresh data
      add(DashBoardInitialFetchEvent());
    } catch (e) {
      log("❌ Withdraw error: $e");
    }
  }
}
