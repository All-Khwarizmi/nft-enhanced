// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {NFTBaseTest} from "./NFTBaseTest.t.sol";

/// @title DeploymentTest
/// @notice Tests for NFT contract deployment and initial state
contract DeploymentTest is NFTBaseTest {
    // =========================================================================
    // Happy Paths
    // =========================================================================
    function test_deployment_initialStateCorrect() public view {
        assertEq(nft.totalSupply(), 0);
        assertEq(nft.MAX_SUPPLY(), 5);
        assertEq(nft.FEE(), 0.01 ether);
        assertEq(nft.owner(), owner);
        assertEq(nft.name(), "TestNFT");
        assertEq(nft.symbol(), "TNFT");
    }

    function test_deployment_interfaceSupported() public view {
        // ERC721 interface
        assertTrue(nft.supportsInterface(0x80ac58cd));
        // ERC165 interface
        assertTrue(nft.supportsInterface(0x01ffc9a7));
    }

    // =========================================================================
    // Unhappy Paths
    // =========================================================================
    function test_deployment_unsupportedInterface() public view {
        // Random interface ID that should not be supported
        assertFalse(nft.supportsInterface(0x12345678));
    }

    // Not needed for deployment, but included for completeness
    function test_deployment_collectionInitiallyNotRevealed() public view {
        assertFalse(nft.isCollectionRevealed());
    }
}
