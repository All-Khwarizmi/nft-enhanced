// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {NFTBaseTest} from "./NFTBaseTest.t.sol";
import {NFT} from "../src/NFT.sol";

/// @title OwnershipTest
/// @notice Tests for contract ownership transfer functionality
contract OwnershipTest is NFTBaseTest {
    // =========================================================================
    // Happy Paths
    // =========================================================================
    function test_setPendingOwner_ownerCanSetPendingOwner() public {
        vm.prank(nft.owner());
        nft.setPendingOwner(otherAccount);

        // We can't directly check pendingOwner as it's private,
        // but we can verify behavior in the acceptance test
    }

    function test_acceptOwnership_pendingOwnerCanAccept() public {
        // Set pending owner
        vm.prank(nft.owner());
        nft.setPendingOwner(otherAccount);

        // Accept ownership
        vm.prank(otherAccount);
        nft.acceptOwnership();

        // Verify new owner
        assertEq(nft.owner(), otherAccount);
    }

    function test_owner_returnsCorrectOwner() public view {
        assertEq(nft.owner(), owner);
    }

    // =========================================================================
    // Unhappy Paths
    // =========================================================================
    function test_setPendingOwner_revertWhenCallerNotOwner() public {
        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.setPendingOwner(thirdParty);
    }

    function test_acceptOwnership_revertWhenCallerNotPendingOwner() public {
        // Set pending owner
        vm.prank(nft.owner());
        nft.setPendingOwner(otherAccount);

        // Try to accept ownership from wrong account
        vm.prank(thirdParty);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, thirdParty));
        nft.acceptOwnership();
    }

    // =========================================================================
    // Multiple Actions
    // =========================================================================
    function test_ownershipTransfer_fullSequence() public {
        // Initial owner
        assertEq(nft.owner(), owner);

        // Set pending owner
        vm.prank(nft.owner());
        nft.setPendingOwner(otherAccount);

        // Accept ownership
        vm.prank(otherAccount);
        nft.acceptOwnership();

        // Verify new owner
        assertEq(nft.owner(), otherAccount);

        // New owner sets another pending owner
        vm.prank(otherAccount);
        nft.setPendingOwner(thirdParty);

        // Accept ownership again
        vm.prank(thirdParty);
        nft.acceptOwnership();

        // Verify final owner
        assertEq(nft.owner(), thirdParty);
    }

    function test_ownershipTransfer_changePendingOwnerBeforeAcceptance() public {
        // Set pending owner
        vm.prank(nft.owner());
        nft.setPendingOwner(otherAccount);

        // Change mind and set different pending owner
        vm.prank(nft.owner());
        nft.setPendingOwner(thirdParty);

        // Try to accept from first pending owner (should fail)
        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.acceptOwnership();

        // Accept from correct pending owner
        vm.prank(thirdParty);
        nft.acceptOwnership();

        // Verify new owner
        assertEq(nft.owner(), thirdParty);
    }

    // =========================================================================
    // Ownership Privileges
    // =========================================================================
    function test_onlyOwnerFunctions_revealTokenURI() public {
        string memory baseUriValue = "ipfs://example/";

        // Set time to 0 to ensure we're before revealTime
        vm.warp(0);

        // Try to reveal from non-owner
        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        vm.warp(1 days);

        nft.revealTokenURI(baseUriValue);

        // Reveal from owner
        vm.prank(nft.owner());
        nft.revealTokenURI(baseUriValue);

        // Verify URI was set
        assertEq(nft.baseURI(), baseUriValue);
    }

    function test_onlyOwnerFunctions_initiateWithdrawalPeriod() public {
        // Try to initiate from non-owner
        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.initiateWithdrawalPeriod();

        // Initiate from owner
        vm.prank(nft.owner());
        nft.initiateWithdrawalPeriod();

        // We can't directly check the endGracePeriod as it's private,
        // but we can verify behavior in the withdrawCollectedEth test
    }

    // =========================================================================
    // Ownership Change Effects
    // =========================================================================
    function test_ownershipChange_privilegesTransferred() public {
        // Set pending owner
        vm.prank(nft.owner());
        nft.setPendingOwner(otherAccount);

        // Accept ownership
        vm.prank(otherAccount);
        nft.acceptOwnership();

        // New owner should be able to call owner-only functions
        string memory baseUriValue = "ipfs://example/";
        vm.warp(1 days);

        vm.prank(otherAccount);
        nft.revealTokenURI(baseUriValue);

        assertEq(nft.baseURI(), baseUriValue);

        // Old owner should not have privileges anymore
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, owner));
        nft.initiateWithdrawalPeriod();
    }
}
