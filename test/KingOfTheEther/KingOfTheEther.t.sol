// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {KingOfTheEther} from "../../contracts/KingOfTheEther/KingOfTheEther.sol";
import {Errors} from "../../contracts/utils/Errors.sol";

contract KingOfTheEtherTest is Test, Errors {
    event Transfer(address indexed sender, uint indexed value);

    KingOfTheEther public kingOfTheEther;

    address public owner = vm.addr(1);
    address public user1 = vm.addr(2);
    address public user2 = vm.addr(3);
    address public user3 = vm.addr(4);
    address public attackerUser = vm.addr(4);
    uint public constant START_BALANCE = 50000 ether;
    uint public constant PRIZE = 1 ether;

    function setUp() public {
        // vm.warp(0);
        vm.deal(owner, 15 ether);
        vm.prank(owner);
        kingOfTheEther = new KingOfTheEther{value: 1 ether}();

        vm.prank(attackerUser);
        vm.deal(user1, START_BALANCE);
        vm.deal(user2, START_BALANCE);
        vm.deal(attackerUser, 1000 ether);
    }

    function testDeploy() public {
        assertEq(kingOfTheEther.owner(), owner);
        assertEq(address(kingOfTheEther).balance, 1 ether);
        assertEq(kingOfTheEther.startTime(), block.timestamp);
    }

    function testStakeAfterStakingPeriodEnd() public {
        console.log(block.timestamp);
        vm.warp(62);
        console.log(block.timestamp);
        vm.prank(user1);
        vm.expectRevert(AlreadyEnded.selector);
        kingOfTheEther.stake{value: 20 ether}();
    }

    function testOnlyStake() public {
        uint user1FirstStake = 5 ether;
       
        vm.startPrank(user1);

        kingOfTheEther.stake{value: user1FirstStake}();

        (
            uint lastDepostiAmount,
            address person,
            uint timestamp,
            uint currentStakeAmount,
            bool staked
        ) = kingOfTheEther.stakers(user1);

        assertEq(lastDepostiAmount, user1FirstStake);
        assertEq(person, user1);
        assertEq(timestamp, block.timestamp);
        assertEq(currentStakeAmount, user1FirstStake);
        assertEq(staked, true);
        vm.stopPrank();

        vm.startPrank(user2);
        kingOfTheEther.stake{value: 5.1 ether}();
        vm.stopPrank();

        uint user1SecondStake = 10.1 ether;
        vm.startPrank(user1);
        kingOfTheEther.stake{value: user1SecondStake}();

        (
            uint _lastDepostiAmount,
            address _person,
            uint _timestamp,
            uint _currentStakeAmount,
            bool _staked
        ) = kingOfTheEther.stakers(user1);


        assertEq(_lastDepostiAmount, user1SecondStake);
        assertEq(_person, user1);
        assertEq(_timestamp, block.timestamp);
        assertEq(_currentStakeAmount, 5 ether + 10.1 ether);
        assertEq(_staked, true);
        vm.stopPrank();

        vm.startPrank(user2);
        kingOfTheEther.stake{value: 15.2 ether}();
        vm.warp(62);
        uint user2TotalStakeAmount = 5.1 ether + 15.2 ether;

        assertEq(kingOfTheEther.maximumStake(), user2TotalStakeAmount);
        kingOfTheEther.withdrawReward();
        console.log("User2 balance after withdraw", user2.balance);
        vm.stopPrank();

        vm.startPrank(user1);
        kingOfTheEther.withdrawReward();
        console.log("User1 balance after withdraw", user1.balance);
        vm.stopPrank();
    }

    function testWithdraw() public {
        uint user1FirstStake = 10 ether;
        uint user1SecondStake = 10.1 ether;

        uint user2FirstStake = 22.2 ether;
        uint user2SecondStake = 22.3 ether;

        vm.startPrank(user1);
        kingOfTheEther.stake{value: user1FirstStake}();
        kingOfTheEther.stake{value: user1SecondStake}();
        vm.stopPrank();

        vm.startPrank(user2);
        kingOfTheEther.stake{value: user2FirstStake}();
        kingOfTheEther.stake{value: user2SecondStake}();
        vm.expectRevert(NotEnded.selector);
        kingOfTheEther.withdrawReward();
        vm.stopPrank();

        vm.warp(62);

        vm.startPrank(user3);
        vm.expectRevert(NotStaker.selector);
        kingOfTheEther.withdrawReward();
        vm.stopPrank();

        vm.startPrank(user1);
        kingOfTheEther.withdrawReward();
        assertEq(user1.balance, START_BALANCE);

        vm.stopPrank();

        vm.startPrank(user2);
        kingOfTheEther.withdrawReward();
        assertEq(user2.balance, START_BALANCE + 1 ether);
        vm.stopPrank();
    }

    function testTransferToContract() public {
        vm.startPrank(user2);
        vm.expectRevert();
        payable(address(kingOfTheEther)).transfer(1 ether);
        vm.stopPrank();
    }

    function testSameMaxDeposit() public {
        uint user1FirstStake = 10 ether;
        uint user2FirstStake = 9 ether;
        uint user2SecondStake = 10 ether;
        uint user2ThirdStake = 10.1 ether;

        vm.startPrank(user1);
        kingOfTheEther.stake{value: user1FirstStake}();
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert(NotEnoughToStake.selector);
        kingOfTheEther.stake{value: user2FirstStake}();

        vm.expectRevert(NotEnoughToStake.selector);
        kingOfTheEther.stake{value: user2SecondStake}();

        kingOfTheEther.stake{value: user2ThirdStake}();
  
        vm.stopPrank();

        vm.warp(62);

        vm.startPrank(user1);
        kingOfTheEther.withdrawReward();
        assertEq(user1.balance, START_BALANCE);
        console.log("User 1 balance after receive prize: ", user1.balance);

        vm.stopPrank();

        vm.startPrank(user2);
        kingOfTheEther.withdrawReward();
        assertEq(user2.balance, START_BALANCE + 1 ether);
        console.log("User 2 balance after receive prize: ", user2.balance);
        vm.stopPrank();
    }
}
