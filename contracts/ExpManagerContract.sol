// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ExpmanagerContract {
    address public owner;

    struct Transaction {
        address user;
        uint amount;
        string reason;
        uint timestamp;
    }

    Transaction[] public transactions;
    mapping(address => uint) public balances;

    event Deposit(address indexed _from, uint _amount, string _reason, uint _timestamp);
    event Withdraw(address indexed _to, uint _amount, string _reason, uint _timestamp);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this");
        _;
    }

    function deposit(string memory _reason) public payable {
        require(msg.value > 0, "Deposit amount should be greater than 0");
        balances[msg.sender] += msg.value;

        transactions.push(Transaction(msg.sender, msg.value, _reason, block.timestamp));
        emit Deposit(msg.sender, msg.value, _reason, block.timestamp);
    }

    function withdraw(uint _amount, string memory _reason) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        transactions.push(Transaction(msg.sender, _amount, _reason, block.timestamp));

        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount, _reason, block.timestamp);
    }

    function getBalance(address _account) public view returns (uint) {
        return balances[_account];
    }

    function getTransactionsCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _index) public view returns (address, uint, string memory, uint) {
        require(_index < transactions.length, "Index out of bounds");
        Transaction memory transaction = transactions[_index];
        return (transaction.user, transaction.amount, transaction.reason, transaction.timestamp);
    }

    function getAllTransactions()
        public
        view
        returns (address[] memory, uint[] memory, string[] memory, uint[] memory)
    {
        uint len = transactions.length;
        address[] memory users = new address[](len);
        uint[] memory amounts = new uint[](len);
        string[] memory reasons = new string[](len);
        uint[] memory timestamps = new uint[](len);

        for (uint i = 0; i < len; i++) {
            Transaction memory t = transactions[i];
            users[i] = t.user;
            amounts[i] = t.amount;
            reasons[i] = t.reason;
            timestamps[i] = t.timestamp;
        }

        return (users, amounts, reasons, timestamps);
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}
