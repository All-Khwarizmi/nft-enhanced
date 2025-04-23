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
        // Send ETH with excess amount to trigger remainder storage
        uint256 excessAmount = 0.005 ether;
        (bool success,) = address(nft).call{value: FEE + excessAmount}("");
        assertTrue(success);

        // Check balance before withdrawal
        assertEq(nft.ethBalances(address(this)), excessAmount);

        // Record ETH balance before withdrawal
        uint256 beforeBalance = address(this).balance;

        // Withdraw excess ETH
        nft.withdrawEth(excessAmount);

        // Check balance after withdrawal
        assertEq(nft.ethBalances(address(this)), 0);
        assertEq(address(this).balance, beforeBalance + excessAmount);
    }

    function test_initiateWithdrawalPeriod_ownerCanInitiate() public {
        vm.prank(nft.owner());
        nft.initiateWithdrawalPeriod();

        // We can't directly check the endGracePeriod as it's private,
        // but we can verify behavior in later tests
    }

    function test_withdrawCollectedEth_afterGracePeriod() public {
        // Mint tokens to generate collected ETH
        nft.buyTokens{value: FEE * 5}(5);

        // Initiate withdrawal period
        vm.prank(nft.owner());
        nft.initiateWithdrawalPeriod();

        // Fast forward past grace period
        vm.warp(block.timestamp + 1 weeks + 1);

        // Record balance before withdrawal
        uint256 beforeBalance = address(this).balance;

        // Withdraw collected ETH
        nft.withdrawCollectedEth();

        // Check balance increased by expected amount
        assertEq(address(this).balance, beforeBalance + (FEE * 5));
    }

    // =========================================================================
    // Unhappy Paths
    // =========================================================================
    function test_withdrawEth_revertWhenExceedingBalance() public {
        // Try to withdraw more than balance
        vm.expectRevert(abi.encodeWithSelector(NFT.NotEnoughEth.selector));
        nft.withdrawEth(1 ether);
    }

    function test_initiateWithdrawalPeriod_revertWhenCallerNotOwner() public {
        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.initiateWithdrawalPeriod();
    }

    function test_withdrawCollectedEth_revertBeforeGracePeriod() public {
        // Mint tokens to generate collected ETH
        nft.buyTokens{value: FEE * 3}(3);

        // Initiate withdrawal period
        vm.prank(nft.owner());
        nft.initiateWithdrawalPeriod();

        // Try to withdraw before grace period ends
        vm.expectRevert(abi.encodeWithSelector(NFT.GracePeriodNotOver.selector));
        nft.withdrawCollectedEth();
    }

    function test_withdrawCollectedEth_revertWithoutInitiation() public {
        // Mint tokens to generate collected ETH
        nft.buyTokens{value: FEE * 3}(3);

        // Try to withdraw without initiating grace period
        vm.expectRevert(abi.encodeWithSelector(NFT.GracePeriodNotOver.selector));
        nft.withdrawCollectedEth();
    }

    // =========================================================================
    // Multiple Actions
    // =========================================================================
    function test_withdrawEth_partialWithdrawals() public {
        // Send ETH with excess amount
        uint256 excessAmount = 0.005 ether;
        uint256 amount = 0.055 ether;
        (bool success,) = address(nft).call{value: FEE + amount}("");
        assertTrue(success);

        // Withdraw half of the excess
        uint256 halfAmount = excessAmount / 2;
        nft.withdrawEth(halfAmount);

        // Check remaining balance
        assertEq(nft.ethBalances(address(this)), excessAmount - halfAmount);

        // Withdraw the rest
        nft.withdrawEth(excessAmount - halfAmount);

        // Check balance is zero
        assertEq(nft.ethBalances(address(this)), 0);
    }

    function test_withdrawCollectedEth_resetsStateCorrectly() public {
        // Mint tokens to generate collected ETH
        nft.buyTokens{value: FEE * 2}(2);

        // Initiate withdrawal period
        vm.prank(nft.owner());
        nft.initiateWithdrawalPeriod();

        // Fast forward past grace period
        vm.warp(block.timestamp + 1 weeks + 1);

        // Withdraw collected ETH
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
        vm.deal(otherAccount, 1 ether); // Ensure account has enough ETH
        uint256 excessAmount2 = 0.007 ether;
        (bool success2,) = address(nft).call{value: FEE + excessAmount2}("");
        assertTrue(success2);

        // Verify each user's balance
        assertEq(nft.ethBalances(address(this)), excessAmount1);
        assertEq(nft.ethBalances(otherAccount), excessAmount2);

        // First user withdraws
        nft.withdrawEth(excessAmount1);

        // Second user withdraws
        uint256 otherAccountBalanceBefore = otherAccount.balance;
        vm.prank(otherAccount);
        nft.withdrawEth(excessAmount2);

        // Verify balances are zero
        assertEq(nft.ethBalances(address(this)), 0);
        assertEq(nft.ethBalances(otherAccount), 0);

        // Verify second user received the correct amount
        assertEq(otherAccount.balance, otherAccountBalanceBefore + excessAmount2);
    }

    // =========================================================================
    // Fuzz Testing
    // =========================================================================
    function test_fuzz_withdrawEth(uint256 excessAmount) public {
        // Bound to reasonable values
        excessAmount = bound(excessAmount, 0.0001 ether, 0.1 ether);
        uint256 remainingBalance = excessAmount % FEE;

        // Send ETH with excess amount
        (bool success,) = address(nft).call{value: FEE + excessAmount}("");
        assertTrue(success);

        // Record balance before withdrawal
        uint256 beforeBalance = address(this).balance;

        // Withdraw excess ETH
        nft.withdrawEth(remainingBalance);

        // Check balance after withdrawal
        assertEq(nft.ethBalances(address(this)), 0);
        assertEq(address(this).balance, beforeBalance + remainingBalance);
    }

    // Helper function to receive ETH
    receive() external payable {}
}
