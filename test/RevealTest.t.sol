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

        nft.revealTokenURI(baseUriValue);

        assertEq(nft.baseURI(), baseUriValue);
    }

    function test_isCollectionRevealed_returnsTrue() public {
        string memory baseUriValue = "ipfs://example/";

        vm.warp(1 days);

        nft.revealTokenURI(baseUriValue);

        assertTrue(nft.isCollectionRevealed());
    }

    // =========================================================================
    // Unhappy Paths
    // =========================================================================
    function test_revealTokenURI_revertBeforeRevealTime() public {
        string memory baseUriValue = "ipfs://example/";

        vm.warp(0 days);

        vm.expectRevert(abi.encodeWithSelector(NFT.NotRevealed.selector));
        nft.revealTokenURI(baseUriValue);
    }

    function test_revealTokenURI_revertWithIncorrectHash() public {
        string memory wrongUriValue = "ipfs://wrong/";

        vm.warp(1 days);

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

        vm.expectRevert(abi.encodeWithSelector(NFT.NotRevealed.selector));
        nft.tokenURI(0);

        string memory baseUriValue = "ipfs://example/";
        vm.warp(1 days);
        nft.revealTokenURI(baseUriValue);

        string memory expectedURI = string(abi.encodePacked(baseUriValue, "0.json"));
        assertEq(nft.tokenURI(0), expectedURI);
    }

    function test_isCollectionRevealed_stateTransition() public {
        assertFalse(nft.isCollectionRevealed());

        string memory baseUriValue = "ipfs://example/";
        vm.warp(2 days);
        nft.revealTokenURI(baseUriValue);

        console.log(nft.baseURI());

        assertTrue(nft.isCollectionRevealed());

        vm.warp(4 days);

        assertTrue(nft.isCollectionRevealed());
    }

    // =========================================================================
    // Multiple Tokens
    // =========================================================================
    function test_tokenURI_multipleTokensAfterReveal() public {
        uint256 amount = 3;
        _mintTokens(amount);

        string memory baseUriValue = "ipfs://example/";
        vm.warp(1 days);
        nft.revealTokenURI(baseUriValue);

        for (uint256 i = 0; i < amount; i++) {
            string memory expectedURI = string(string.concat(baseUriValue, Strings.toString(i), ".json"));
            assertEq(nft.tokenURI(i), expectedURI);
        }
    }

    // =========================================================================
    // Edge Cases
    // =========================================================================
    function test_reveal_atExactRevealTime() public {
        string memory baseUriValue = "ipfs://example/";

        vm.warp(1 days);

        nft.revealTokenURI(baseUriValue);

        assertEq(nft.baseURI(), baseUriValue);
    }

    function test_tokenURI_revertForNonExistentToken() public {
        string memory baseUriValue = "ipfs://example/";
        vm.warp(1 days);
        nft.revealTokenURI(baseUriValue);

        vm.expectRevert(abi.encodeWithSelector(NFT.InvalidToken.selector, 0));
        nft.tokenURI(0);
    }
}
