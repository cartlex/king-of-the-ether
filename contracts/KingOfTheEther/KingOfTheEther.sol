// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title `KingOfTheEther` contract for staking ETH.
 * @author cartlex.
 * @notice You can use this contract for only the most basic simulation.
 * @dev All function calls are currently implemented without side effects.
 */
contract KingOfTheEther is Ownable2Step {
    error ZeroValue();
    error NotStaker();
    error AlreadyEnded();
    error NotStarted();
    error IncorrectStartAmount();
    error NotEnded();
    error FailedWinnerWithdrawal();
    error FailedUserWithdrawal();
    error NotAnOwner();
    error NotEnoughToStake();

    event UserWithdrawal(
        address indexed staker,
        uint indexed amount,
        uint timestamp
    );
    event WinnerWithdrawal(
        address indexed staker,
        uint indexed amount,
        uint timestamp
    );
    event Stake(address indexed staker, uint indexed amount);
    event Increased(
        address indexed sender,
        uint indexed amount,
        uint timestamp
    );
    event Transfer(address indexed sender, uint indexed value);

    uint256 private constant STAKING_DURATION = 60 seconds;
    uint256 private constant PRIZE = 1 ether;
    uint256 private constant MINIMUM_STAKE_INCREMENT = 0.1 ether;
    uint256 public immutable startTime;
    uint256 public maximumStake;

    mapping(address => Staker) public stakers;

    struct Staker {
        uint lastDepostiAmount;
        address person;
        uint timestamp;
        uint currentStakeAmount;
        bool staked;
    }

    constructor() payable {
        if (msg.value != 1 ether) revert IncorrectStartAmount();
        startTime = block.timestamp;
    }

    /**
     * @dev stake ETH to the `KingOfTheEther` contract.
     * User can stake their ETH until the end of the staking period.
     */
    function stake() external payable {
        if (msg.value == 0) revert ZeroValue();
        if (maximumStake + MINIMUM_STAKE_INCREMENT > msg.value)
            revert NotEnoughToStake();
        if (block.timestamp > startTime + STAKING_DURATION)
            revert AlreadyEnded();
        if (block.timestamp < startTime) revert NotStarted();

        Staker storage _staker = stakers[msg.sender];

        if (!_staker.staked) {
            uint currentStakeAmount = msg.value;

            stakers[msg.sender] = Staker(
                currentStakeAmount,
                msg.sender,
                block.timestamp,
                currentStakeAmount,
                true
            );

            if (currentStakeAmount > maximumStake) {
                maximumStake = currentStakeAmount;
            }

            emit Stake(msg.sender, msg.value);
        } else {
            uint currentStakeAmount = _staker.currentStakeAmount + msg.value;
            _staker.lastDepostiAmount = msg.value;
            _staker.currentStakeAmount += msg.value;
            _staker.timestamp = block.timestamp;

            if (currentStakeAmount > maximumStake) {
                maximumStake = currentStakeAmount;
            }

            emit Increased(msg.sender, msg.value, block.timestamp);
        }
    }

    /**
     * @dev withdraw ETH from the `KingOfTheEther` contract.
     * It allows to withdraw only after the staking period is end.
     * User with maximum stake amount receives a prize equal 1 ether from the `KingOfTheEther` contract.
     * Other users receives their ETH back.
     */
    function withdrawReward() external {
        if (block.timestamp <= startTime + STAKING_DURATION) revert NotEnded();

        Staker storage _staker = stakers[msg.sender];

        if (msg.sender != _staker.person) revert NotStaker();

        if (_staker.currentStakeAmount == maximumStake) {
            uint amountToWithdraw = _staker.currentStakeAmount + PRIZE;
            _staker.currentStakeAmount = 0;
            (bool ok, ) = _staker.person.call{value: amountToWithdraw}("");
            if (!ok) revert FailedWinnerWithdrawal();
            emit WinnerWithdrawal(
                msg.sender,
                amountToWithdraw,
                block.timestamp
            );
        } else {
            uint amountToWithdraw = _staker.currentStakeAmount;
            _staker.currentStakeAmount = 0;
            (bool ok, ) = _staker.person.call{value: amountToWithdraw}("");
            if (!ok) revert FailedUserWithdrawal();

            emit UserWithdrawal(msg.sender, amountToWithdraw, block.timestamp);
        }
    }
}
