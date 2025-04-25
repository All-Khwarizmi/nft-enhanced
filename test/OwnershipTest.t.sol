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

        address pendingOwner = nft.getPendingOwner();
        assertEq(pendingOwner, otherAccount);
    }

    function test_acceptOwnership_pendingOwnerCanAccept() public {
        vm.prank(nft.owner());
        nft.setPendingOwner(otherAccount);

        vm.prank(otherAccount);
        nft.acceptOwnership();

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
        vm.prank(nft.owner());
        nft.setPendingOwner(otherAccount);

        vm.prank(thirdParty);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, thirdParty));
        nft.acceptOwnership();
    }

    // =========================================================================
    // Multiple Actions
    // =========================================================================
    function test_ownershipTransfer_fullSequence() public {
        assertEq(nft.owner(), owner);

        vm.prank(nft.owner());
        nft.setPendingOwner(otherAccount);

        vm.prank(otherAccount);
        nft.acceptOwnership();

        assertEq(nft.owner(), otherAccount);

        vm.prank(otherAccount);
        nft.setPendingOwner(thirdParty);

        vm.prank(thirdParty);
        nft.acceptOwnership();

        assertEq(nft.owner(), thirdParty);
    }

    function test_ownershipTransfer_changePendingOwnerBeforeAcceptance() public {
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

        assertEq(nft.owner(), thirdParty);
    }

    // =========================================================================
    // Ownership Privileges
    // =========================================================================
    function test_onlyOwnerFunctions_revealTokenURI() public {
        string memory baseUriValue = "ipfs://example/";

        vm.warp(0);

        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        vm.warp(1 days);

        nft.revealTokenURI(baseUriValue);

        vm.prank(nft.owner());
        nft.revealTokenURI(baseUriValue);

        assertEq(nft.baseURI(), baseUriValue);
    }

    function test_onlyOwnerFunctions_initiateWithdrawalPeriod() public {
        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.initiateWithdrawalPeriod();

        vm.prank(nft.owner());
        nft.initiateWithdrawalPeriod();

        uint256 endGracePeriod = nft.getEndGracePeriod();
        assertTrue(endGracePeriod > 0); 
    }

    // =========================================================================
    // Ownership Change Effects
    // =========================================================================
    function test_ownershipChange_privilegesTransferred() public {
        vm.prank(nft.owner());
        nft.setPendingOwner(otherAccount);

        vm.prank(otherAccount);
        nft.acceptOwnership();

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
