// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {NFTBaseTest} from "./NFTBaseTest.t.sol";
import {IERC721} from "../src/interface/IERC721.sol";
import {NFT} from "../src/NFT.sol";

/// @title ApprovalsTest
/// @notice Tests for NFT approval functionality
contract ApprovalsTest is NFTBaseTest {
    // =========================================================================
    // Happy Paths
    // =========================================================================
    function test_approve_ownerCanApprove() public {
        _mintOneToken();

        nft.approve(otherAccount, 0);
        assertEq(nft.getApproved(0), otherAccount);
    }

    function test_approve_operatorCanApprove() public {
        _mintOneToken();

        // First approve an operator
        nft.setApprovalForAll(otherAccount, true);

        // Operator approves a third party for a specific token
        vm.prank(otherAccount);
        nft.approve(thirdParty, 0);

        assertEq(nft.getApproved(0), thirdParty);
    }

    function test_setApprovalForAll_enableApproval() public {
        nft.setApprovalForAll(otherAccount, true);
        assertTrue(nft.isApprovedForAll(owner, otherAccount));
    }

    function test_setApprovalForAll_disableApproval() public {
        // First enable approval
        nft.setApprovalForAll(otherAccount, true);
        assertTrue(nft.isApprovedForAll(owner, otherAccount));

        // Then disable it
        nft.setApprovalForAll(otherAccount, false);
        assertFalse(nft.isApprovedForAll(owner, otherAccount));
    }

    function test_getApproved_initiallyZeroAddress() public {
        _mintOneToken();
        assertEq(nft.getApproved(0), address(0));
    }

    function test_isApprovedForAll_initiallyFalse() public view {
        assertFalse(nft.isApprovedForAll(owner, otherAccount));
    }

    // =========================================================================
    // Events
    // =========================================================================
    function test_approve_emitsApprovalEvent() public {
        _mintOneToken();

        vm.expectEmit(true, true, true, true);
        emit IERC721.Approval(owner, otherAccount, 0);

        nft.approve(otherAccount, 0);
    }

    function test_setApprovalForAll_emitsApprovalForAllEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IERC721.ApprovalForAll(owner, otherAccount, true);

        nft.setApprovalForAll(otherAccount, true);
    }

    // =========================================================================
    // Unhappy Paths
    // =========================================================================
    function test_approve_revertWhenCallerNotAuthorized() public {
        _mintOneToken();

        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.approve(thirdParty, 0);
    }

    function test_setApprovalForAll_revertWithZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(NFT.ZeroAddress.selector));
        nft.setApprovalForAll(address(0), true);
    }

    // =========================================================================
    // Multiple Actions
    // =========================================================================
    function test_approve_thenTransfer_clearsApproval() public {
        _mintOneToken();

        // Approve otherAccount to transfer token 0
        nft.approve(otherAccount, 0);
        assertEq(nft.getApproved(0), otherAccount);

        // Transfer token to thirdParty
        nft.transferFrom(owner, thirdParty, 0);

        // Check that approval is cleared after transfer
        assertEq(nft.getApproved(0), address(0));
    }

    function test_setApprovalForAll_enableDisableMultipleTimes() public {
        // Enable approval
        nft.setApprovalForAll(otherAccount, true);
        assertTrue(nft.isApprovedForAll(owner, otherAccount));

        // Disable approval
        nft.setApprovalForAll(otherAccount, false);
        assertFalse(nft.isApprovedForAll(owner, otherAccount));

        // Enable again
        nft.setApprovalForAll(otherAccount, true);
        assertTrue(nft.isApprovedForAll(owner, otherAccount));
    }

    // =========================================================================
    // Multiple Actors
    // =========================================================================
    function test_approve_multipleUsers() public {
        // Mint tokens to multiple users
        _mintOneToken(); // Token 0 to owner

        vm.prank(otherAccount);
        nft.buyTokens{value: FEE}(1); // Token 1 to otherAccount

        vm.prank(thirdParty);
        nft.buyTokens{value: FEE}(1); // Token 2 to thirdParty

        // Each user approves someone else for their token
        nft.approve(thirdParty, 0); // Owner approves thirdParty for token 0

        vm.prank(otherAccount);
        nft.approve(owner, 1); // otherAccount approves owner for token 1

        vm.prank(thirdParty);
        nft.approve(otherAccount, 2); // thirdParty approves otherAccount for token 2

        // Verify approvals
        assertEq(nft.getApproved(0), thirdParty);
        assertEq(nft.getApproved(1), owner);
        assertEq(nft.getApproved(2), otherAccount);
    }
}
