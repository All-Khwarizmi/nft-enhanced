// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {NFT} from "../src/NFT.sol";
import {NFTBaseTest} from "./NFTBaseTest.t.sol";

contract NFTTest is NFTBaseTest {
    receive() external payable {}

    function test_initiateWithdrawalPeriodShouldRevert_whenNotOwner() public {
        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.initiateWithdrawalPeriod();
    }

    function test_withdrawCollectedEth_shouldRevert_whenNotOwner() public {
        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.withdrawCollectedEth();
    }

    function test_initiateWithdrawalPeriod_shouldWaitOneWeek() public {
        vm.prank(owner);
        nft.initiateWithdrawalPeriod();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(NFT.GracePeriodNotOver.selector));
        nft.withdrawCollectedEth();

        // Advance time by one week
        uint256 time = vm.getBlockTimestamp() + 1 weeks;
        vm.warp(time);

        vm.prank(owner);
        nft.withdrawCollectedEth();
    }

    function test_withdrawCollectedEth_shouldTransferEth() public {
        _mintOneToken();

        vm.prank(owner);
        nft.initiateWithdrawalPeriod();

        // Advance time by one week
        uint256 time = vm.getBlockTimestamp() + 1 weeks;
        vm.warp(time);

        uint256 balanceBefore = address(this).balance;
        vm.prank(owner);
        nft.withdrawCollectedEth();
        uint256 balanceAfter = address(this).balance;

        assertEq(balanceAfter - balanceBefore, 0.01 ether);
    }
}
