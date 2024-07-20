// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
  uint256 public deadline;
  uint256 constant DURATION = 72 hours; // 72 hours in seconds

  // Mapping to track individyal balances
  mapping ( address => uint256 ) public balances;

  // List of all stakers
  address[] public stakers;

  // Threshold that needs to be met in order to stake.
  uint256 constant THRESHOLD = 1 ether;

  // Event to be emitted when staking
  event Stake(address indexed staker, uint256 amount);

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    deadline = block.timestamp + DURATION;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  function stake() public payable {
    require(msg.value > 0, "You must send some ether to stake.");
    require(block.timestamp < deadline, "Deadline has passed");

    // If the sender hasn't staked before, we add them to the stakers array
    if (balances[msg.sender] == 0) {
      stakers.push(msg.sender);
    }

    balances[msg.sender] += msg.value;

    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  modifier onlyAfterDeadline() {
    require(block.timestamp > deadline, "Deadline has not passed yet.");
    _;
  }

  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(completed == false, "Staking has completed.");
    _;
  }

  function execute() external onlyAfterDeadline notCompleted {
    uint256 total_staked = totalStaked();

    if (total_staked > THRESHOLD) {
      exampleExternalContract.complete{value: address(this).balance}();
    }
  }

  function totalStaked() internal view returns(uint256) {
    uint256 total = 0;

    for(uint i = 0; i < stakers.length; i++) {
      total += balances[stakers[i]];
    }

    return total;
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() external onlyAfterDeadline notCompleted {
    uint256 total_balance = 0;

    total_balance = totalStaked();

    require(total_balance < THRESHOLD, "Threshold was met");

    uint256 amount = balances[msg.sender];
    require(amount > 0, "No balance to withdraw.");

    balances[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256){
    if (block.timestamp >= deadline) {
      return 0;
    }

    return deadline - block.timestamp;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

  // fallback function
  fallback() external payable {
    stake();
  }
}
