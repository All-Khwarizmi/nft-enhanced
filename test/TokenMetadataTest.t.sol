// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {NFTBaseTest} from "./NFTBaseTest.t.sol";
import {NFT} from "../src/NFT.sol";

/// @title TokenTest
/// @notice Tests for NFT token information and metadata functions
contract TokenTest is NFTBaseTest {
    // =========================================================================
    // Happy Paths
    // =========================================================================
    function test_ownerOf_returnsCorrectOwner() public {
        _mintOneToken();
        assertEq(nft.ownerOf(0), owner);
    }

    function test_balanceOf_returnsCorrectBalance() public {
        _mintOneToken();
        assertEq(nft.balanceOf(owner), 1);

        nft.buyTokens{value: FEE}(1);
        assertEq(nft.balanceOf(owner), 2);
    }

    function test_tokenURI_returnsCorrectURI() public {
        _mintOneToken();

        // Reveal collection
        string memory baseUriValue = "ipfs://example/";
        vm.warp(0); // Set time to 0 to ensure we're before revealTime
        nft.revealTokenURI(baseUriValue);

        string memory expectedURI = string(abi.encodePacked(baseUriValue, "0"));
        assertEq(nft.tokenURI(0), expectedURI);
    }

    function test_name_returnsCorrectValue() public view {
        assertEq(nft.name(), "TestNFT");
    }

    function test_symbol_returnsCorrectValue() public view {
        assertEq(nft.symbol(), "TNFT");
    }

    function test_baseURI_returnsCorrectValue() public {
        string memory baseUriValue = "ipfs://example/";
        vm.warp(0);
        nft.revealTokenURI(baseUriValue);

        assertEq(nft.baseURI(), baseUriValue);
    }

    // =========================================================================
    // Unhappy Paths
    // =========================================================================
    function test_ownerOf_revertForInvalidToken() public {
        vm.expectRevert(abi.encodeWithSelector(NFT.InvalidToken.selector, 0));
        nft.ownerOf(0);
    }

    function test_balanceOf_revertForZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(NFT.ZeroAddress.selector));
        nft.balanceOf(address(0));
    }

    function test_tokenURI_revertWhenNotRevealed() public {
        _mintOneToken();

        vm.expectRevert(abi.encodeWithSelector(NFT.NotRevealed.selector));
        nft.tokenURI(0);
    }

    // =========================================================================
    // Multiple Actions
    // =========================================================================
    function test_tokenURIAndReveal_sequence() public {
        _mintOneToken();

        // Try to get URI before reveal (should revert)
        vm.expectRevert(abi.encodeWithSelector(NFT.NotRevealed.selector));
        nft.tokenURI(0);

        // Reveal collection
        string memory baseUriValue = "ipfs://example/";
        vm.warp(0); // Set time to 0 to ensure we're before revealTime
        nft.revealTokenURI(baseUriValue);

        // Now we should be able to get the URI
        string memory expectedURI = string(abi.encodePacked(baseUriValue, "0"));
        assertEq(nft.tokenURI(0), expectedURI);
    }

    // =========================================================================
    // Fuzz Testing
    // =========================================================================
    function test_fuzz_balanceOf(uint256 amountToMint) public {
        // Bound amount to reasonable limits
        amountToMint = bound(amountToMint, 1, 5);

        _mintTokens(amountToMint);
        assertEq(nft.balanceOf(owner), amountToMint);
    }
}
