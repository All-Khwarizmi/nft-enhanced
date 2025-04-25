// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {NFTBaseTest} from "./NFTBaseTest.t.sol";
import {NFT} from "../src/NFT.sol";

/// @title ETHWithdrawalTest
/// @notice Tests for ETH withdrawal functionality
contract ETHWithdrawalTest is NFTBaseTest {
    // =========================================================================
    // Happy Paths
    // =========================================================================
    function test_withdrawEth_userCanWithdrawExcessEth() public {
        uint256 excessAmount = 0.005 ether;
        (bool success,) = address(nft).call{value: FEE + excessAmount}("");
        assertTrue(success);

        assertEq(nft.ethBalances(address(this)), excessAmount);

        uint256 beforeBalance = address(this).balance;

        nft.withdrawEth(excessAmount);

        assertEq(nft.ethBalances(address(this)), 0);
        assertEq(address(this).balance, beforeBalance + excessAmount);
    }

    function test_initiateWithdrawalPeriod_ownerCanInitiate() public {
        vm.prank(nft.owner());
        nft.initiateWithdrawalPeriod();

        uint256 endGracePeriod = nft.getEndGracePeriod();
        assertTrue(endGracePeriod > 0);
    }

    function test_withdrawCollectedEth_afterGracePeriod() public {
        nft.buyTokens{value: FEE * 5}(5);

        vm.prank(nft.owner());
        nft.initiateWithdrawalPeriod();

        vm.warp(block.timestamp + 1 weeks + 1);

        uint256 beforeBalance = address(this).balance;

        nft.withdrawCollectedEth();

        assertEq(address(this).balance, beforeBalance + (FEE * 5));
    }

    // =========================================================================
    // Unhappy Paths
    // =========================================================================
    function test_withdrawEth_revertWhenExceedingBalance() public {
        vm.expectRevert(abi.encodeWithSelector(NFT.NotEnoughEth.selector));
        nft.withdrawEth(1 ether);
    }

    function test_initiateWithdrawalPeriod_revertWhenCallerNotOwner() public {
        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.initiateWithdrawalPeriod();
    }

    function test_withdrawCollectedEth_revertBeforeGracePeriod() public {
        nft.buyTokens{value: FEE * 3}(3);

        vm.prank(nft.owner());
        nft.initiateWithdrawalPeriod();

        vm.expectRevert(abi.encodeWithSelector(NFT.GracePeriodNotOver.selector));
        nft.withdrawCollectedEth();
    }

    function test_withdrawCollectedEth_revertWithoutInitiation() public {
        nft.buyTokens{value: FEE * 3}(3);

        vm.expectRevert(abi.encodeWithSelector(NFT.GracePeriodNotOver.selector));
        nft.withdrawCollectedEth();
    }

    // =========================================================================
    // Multiple Actions
    // =========================================================================
    function test_withdrawEth_partialWithdrawals() public {
        uint256 excessAmount = 0.005 ether;
        uint256 amount = 0.055 ether;

        uint256 supplyLeft = nft.getSupplyLeft();
        vm.assume(supplyLeft >= amount / FEE);

        (bool success,) = address(nft).call{value: amount}("");
        assertTrue(success);

        // Withdraw half of the excess
        uint256 halfAmount = excessAmount / 2;
        nft.withdrawEth(halfAmount);

        assertEq(nft.ethBalances(address(this)), excessAmount - halfAmount);

        // Withdraw the rest
        nft.withdrawEth(excessAmount - halfAmount);

        assertEq(nft.ethBalances(address(this)), 0);
    }

    function test_withdrawCollectedEth_resetsStateCorrectly() public {
        nft.buyTokens{value: FEE * 2}(2);

        vm.prank(nft.owner());
        nft.initiateWithdrawalPeriod();

        vm.warp(block.timestamp + 1 weeks + 1);

        nft.withdrawCollectedEth();

        // Add more funds
        nft.buyTokens{value: FEE}(1);

        // Try to withdraw again (should fail because grace period was reset)
        vm.expectRevert(abi.encodeWithSelector(NFT.GracePeriodNotOver.selector));
        nft.withdrawCollectedEth();
    }

    // =========================================================================
    // Multiple Actors
    // =========================================================================
    function test_withdrawEth_multipleUsers() public {
        // First user sends ETH with excess
        uint256 excessAmount1 = 0.003 ether;
        (bool success1,) = address(nft).call{value: FEE + excessAmount1}("");
        assertTrue(success1);

        // Second user sends ETH with excess
        vm.prank(otherAccount);
        vm.deal(otherAccount, 1 ether);
        uint256 excessAmount2 = 0.007 ether;
        (bool success2,) = address(nft).call{value: FEE + excessAmount2}("");
        assertTrue(success2);

        assertEq(nft.ethBalances(address(this)), excessAmount1);
        assertEq(nft.ethBalances(otherAccount), excessAmount2);

        // First user withdraws
        nft.withdrawEth(excessAmount1);

        // Second user withdraws
        uint256 otherAccountBalanceBefore = otherAccount.balance;
        vm.prank(otherAccount);
        nft.withdrawEth(excessAmount2);

        assertEq(nft.ethBalances(address(this)), 0);
        assertEq(nft.ethBalances(otherAccount), 0);

        assertEq(otherAccount.balance, otherAccountBalanceBefore + excessAmount2);
    }

    // =========================================================================
    // Fuzz Testing
    // =========================================================================
    function test_fuzz_withdrawEth(uint256 amount) public {
        amount = bound(amount, 0.0001 ether, 0.1 ether);
        uint256 remainingBalance = amount % FEE;

        uint256 supplyLeft = nft.getSupplyLeft();
        vm.assume(supplyLeft >= amount / FEE);

        // Send ETH with excess amount
        (bool success,) = address(nft).call{value: amount}("");
        assertTrue(success);

        // Record balance before withdrawal
        uint256 beforeBalance = address(this).balance;

        nft.withdrawEth(remainingBalance);

        assertEq(nft.ethBalances(address(this)), 0);
        assertEq(address(this).balance, beforeBalance + remainingBalance);
    }

    receive() external payable {}
}
