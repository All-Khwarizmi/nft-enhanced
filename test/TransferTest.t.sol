// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {NFTBaseTest} from "./NFTBaseTest.t.sol";
import {IERC721} from "../src/interface/IERC721.sol";
import {NFT} from "../src/NFT.sol";

/// @title TransferTest
/// @notice Tests for NFT transfer functionality
contract TransferTest is NFTBaseTest {
    // =========================================================================
    // Happy Paths
    // =========================================================================
    function test_transferFrom_ownerCanTransfer() public {
        _mintOneToken();

        nft.transferFrom(owner, otherAccount, 0);

        assertEq(nft.ownerOf(0), otherAccount);
        assertEq(nft.balanceOf(owner), 0);
        assertEq(nft.balanceOf(otherAccount), 1);
    }

    function test_transferFrom_approvedAddressCanTransfer() public {
        _mintOneToken();

        // Approve otherAccount to transfer token 0
        nft.approve(otherAccount, 0);

        // otherAccount transfers token to thirdParty
        vm.prank(otherAccount);
        nft.transferFrom(owner, thirdParty, 0);

        assertEq(nft.ownerOf(0), thirdParty);
    }

    function test_transferFrom_operatorCanTransfer() public {
        _mintOneToken();

        // Approve otherAccount as operator for all owner's tokens
        nft.setApprovalForAll(otherAccount, true);

        // otherAccount transfers token to thirdParty
        vm.prank(otherAccount);
        nft.transferFrom(owner, thirdParty, 0);

        assertEq(nft.ownerOf(0), thirdParty);
    }

    function test_safeTransferFrom_toEOA() public {
        _mintOneToken();

        nft.safeTransferFrom(owner, otherAccount, 0);

        assertEq(nft.ownerOf(0), otherAccount);
    }

    // =========================================================================
    // Events
    // =========================================================================
    function test_transferFrom_emitsTransferEvent() public {
        _mintOneToken();

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(owner, otherAccount, 0);

        nft.transferFrom(owner, otherAccount, 0);
    }

    function test_safeTransferFrom_emitsTransferEvent() public {
        _mintOneToken();

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(owner, otherAccount, 0);

        nft.safeTransferFrom(owner, otherAccount, 0);
    }

    // =========================================================================
    // Unhappy Paths
    // =========================================================================
    function test_transferFrom_revertWhenCallerNotAuthorized() public {
        _mintOneToken();

        vm.prank(thirdParty);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, thirdParty));
        nft.transferFrom(owner, otherAccount, 0);
    }

    function test_transferFrom_revertWhenFromAddressNotOwner() public {
        _mintOneToken();

        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.transferFrom(otherAccount, thirdParty, 0);
    }

    function test_transferFrom_revertWithInvalidToken() public {
        vm.expectRevert(abi.encodeWithSelector(NFT.InvalidToken.selector, 0));
        nft.transferFrom(owner, otherAccount, 0);
    }

    function test_transferFrom_revertWithZeroAddress() public {
        _mintOneToken();

        vm.expectRevert(abi.encodeWithSelector(NFT.ZeroAddress.selector));
        nft.transferFrom(owner, address(0), 0);
    }

    function test_safeTransferFrom_revertWhenNonERC721Receiver() public {
        _mintOneToken();

        // Deploy a minimal contract that doesn't implement onERC721Received
        NonERC721ReceiverMock nonReceiver = new NonERC721ReceiverMock();

        vm.expectRevert(abi.encodeWithSelector(NFT.NotOnReceivedImplementer.selector));
        nft.safeTransferFrom(owner, address(nonReceiver), 0);
    }

    // =========================================================================
    // Multiple Actions
    // =========================================================================
    function test_transferFrom_multipleTransfers() public {
        _mintOneToken();

        // First transfer: owner -> otherAccount
        nft.transferFrom(owner, otherAccount, 0);
        assertEq(nft.ownerOf(0), otherAccount);

        // Second transfer: otherAccount -> thirdParty
        vm.prank(otherAccount);
        nft.transferFrom(otherAccount, thirdParty, 0);
        assertEq(nft.ownerOf(0), thirdParty);

        // Third transfer: thirdParty -> owner
        vm.prank(thirdParty);
        nft.transferFrom(thirdParty, owner, 0);
        assertEq(nft.ownerOf(0), owner);
    }

    function test_transferFrom_clearsApprovalAfterTransfer() public {
        _mintOneToken();

        // Approve otherAccount for token 0
        nft.approve(otherAccount, 0);
        assertEq(nft.getApproved(0), otherAccount);

        // Transfer token to thirdParty
        nft.transferFrom(owner, thirdParty, 0);

        // Check approval is cleared
        assertEq(nft.getApproved(0), address(0));
    }

    // =========================================================================
    // Multiple Actors
    // =========================================================================
    function test_transferFrom_complexScenario() public {
        // Mint 3 tokens
        _mintTokens(3);

        // Approve otherAccount for token 0
        nft.approve(otherAccount, 0);

        // Approve thirdParty for token 1
        nft.approve(thirdParty, 1);

        // Set otherAccount as operator for all tokens
        nft.setApprovalForAll(otherAccount, true);

        // otherAccount transfers token 0 to thirdParty
        vm.prank(otherAccount);
        nft.transferFrom(owner, thirdParty, 0);

        // thirdParty transfers token 1 to otherAccount
        vm.prank(thirdParty);
        nft.transferFrom(owner, otherAccount, 1);

        // otherAccount transfers token 2 to thirdParty
        vm.prank(otherAccount);
        nft.transferFrom(owner, thirdParty, 2);

        // Check final ownership
        assertEq(nft.ownerOf(0), thirdParty);
        assertEq(nft.ownerOf(1), otherAccount);
        assertEq(nft.ownerOf(2), thirdParty);

        // Check final balances
        assertEq(nft.balanceOf(owner), 0);
        assertEq(nft.balanceOf(otherAccount), 1);
        assertEq(nft.balanceOf(thirdParty), 2);
    }

    // =========================================================================
    // Fuzz Testing
    // =========================================================================
    function test_fuzz_transferFrom(address recipient) public {
        // Filter out invalid addresses
        vm.assume(recipient != address(0));
        vm.assume(recipient != owner);
        vm.assume(recipient.code.length == 0); // Ensure it's an EOA

        _mintOneToken();

        nft.transferFrom(owner, recipient, 0);

        assertEq(nft.ownerOf(0), recipient);
        assertEq(nft.balanceOf(owner), 0);
        assertEq(nft.balanceOf(recipient), 1);
    }
}

/// @notice Mock contract that doesn't implement onERC721Received
contract NonERC721ReceiverMock {
// Intentionally empty
}
