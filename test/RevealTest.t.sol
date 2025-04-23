// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {NFTBaseTest, console} from "./NFTBaseTest.t.sol";
import {NFT} from "../src/NFT.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title RevealTest
/// @notice Tests for NFT metadata reveal functionality
contract RevealTest is NFTBaseTest {
    // =========================================================================
    // Happy Paths
    // =========================================================================
    function test_revealTokenURI_canRevealWithCorrectHash() public {
        string memory baseUriValue = "ipfs://example/";
        vm.warp(1 days);

        // Reveal the URI
        nft.revealTokenURI(baseUriValue);

        // Check it was set correctly
        assertEq(nft.baseURI(), baseUriValue);
    }

    function test_isCollectionRevealed_returnsTrue() public {
        string memory baseUriValue = "ipfs://example/";

        vm.warp(1 days);

        // Reveal the URI
        nft.revealTokenURI(baseUriValue);

        // Check collection is revealed
        assertTrue(nft.isCollectionRevealed());
    }

    // =========================================================================
    // Unhappy Paths
    // =========================================================================
    function test_revealTokenURI_revertBeforeRevealTime() public {
        string memory baseUriValue = "ipfs://example/";

        vm.warp(0 days);

        // Try to reveal
        vm.expectRevert(abi.encodeWithSelector(NFT.NotRevealed.selector));
        nft.revealTokenURI(baseUriValue);
    }

    function test_revealTokenURI_revertWithIncorrectHash() public {
        string memory wrongUriValue = "ipfs://wrong/";

        vm.warp(1 days);

        // Try to reveal with wrong URI
        vm.expectRevert(abi.encodeWithSelector(NFT.NotExpectedValue.selector));
        nft.revealTokenURI(wrongUriValue);
    }

    function test_tokenURI_revertWhenNotRevealed() public {
        _mintOneToken();

        vm.expectRevert(abi.encodeWithSelector(NFT.NotRevealed.selector));
        nft.tokenURI(0);
    }

    // =========================================================================
    // Multiple Actions
    // =========================================================================
    function test_reveal_thenAccessTokenURI() public {
        _mintOneToken();

        // Try to get URI before reveal (should revert)
        vm.expectRevert(abi.encodeWithSelector(NFT.NotRevealed.selector));
        nft.tokenURI(0);

        // Reveal collection
        string memory baseUriValue = "ipfs://example/";
        vm.warp(1 days);
        nft.revealTokenURI(baseUriValue);

        // Now we should be able to get the URI
        string memory expectedURI = string(abi.encodePacked(baseUriValue, "0"));
        assertEq(nft.tokenURI(0), expectedURI);
    }

    function test_isCollectionRevealed_stateTransition() public {
        // Initially not revealed
        assertFalse(nft.isCollectionRevealed());

        // Reveal
        string memory baseUriValue = "ipfs://example/";
        vm.warp(2 days);
        nft.revealTokenURI(baseUriValue);

        console.log(nft.baseURI());

        // Should be revealed now
        assertTrue(nft.isCollectionRevealed());

        // Move time past revealTime
        vm.warp(4 days);

        // Should still be revealed (once revealed, stays revealed)
        assertTrue(nft.isCollectionRevealed());
    }

    // =========================================================================
    // Multiple Tokens
    // =========================================================================
    function test_tokenURI_multipleTokensAfterReveal() public {
        uint256 amount = 3;
        _mintTokens(amount);

        // Reveal collection
        string memory baseUriValue = "ipfs://example/";
        vm.warp(1 days);
        nft.revealTokenURI(baseUriValue);

        // Check each token URI
        for (uint256 i = 0; i < amount; i++) {
            string memory expectedURI = string(abi.encodePacked(baseUriValue, Strings.toString(i)));
            assertEq(nft.tokenURI(i), expectedURI);
        }
    }

    // =========================================================================
    // Edge Cases
    // =========================================================================
    function test_reveal_atExactRevealTime() public {
        string memory baseUriValue = "ipfs://example/";

        // Set time to exactly revealTime (1 day from deployment)
        vm.warp(1 days);

        // Should be able to reveal
        nft.revealTokenURI(baseUriValue);

        // Check it was set correctly
        assertEq(nft.baseURI(), baseUriValue);
    }

    function test_tokenURI_revertForNonExistentToken() public {
        // Reveal collection
        string memory baseUriValue = "ipfs://example/";
        vm.warp(1 days);
        nft.revealTokenURI(baseUriValue);

        // Try to get URI for non-existent token
        // Should revert with InvalidToken, but this might depend on the implementation
        vm.expectRevert(abi.encodeWithSelector(NFT.InvalidToken.selector, 0));
        nft.tokenURI(0);
    }
}
