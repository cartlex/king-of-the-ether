// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

abstract contract Errors {
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
}
