// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/NFT.sol";

/// @title NFTBaseTest
/// @notice Base test contract with common setup for all NFT tests
contract NFTBaseTest is Test {
    // Constants
    uint256 public constant FEE = 0.01 ether;
    bytes32 public constant EXAMPLE_URI_HASH = keccak256(bytes("ipfs://example/"));

    // Contract instance
    NFT nft;

    // Test accounts
    address owner;
    address otherAccount;
    address thirdParty;

    // Setup function
    function setUp() public virtual {
        owner = address(this);
        otherAccount = makeAddr("otherAccount");
        thirdParty = makeAddr("thirdParty");

        // Deploy NFT contract with test parameters
        nft = new NFT("TestNFT", "TNFT", 1 days, EXAMPLE_URI_HASH, 5);

        // Fund test accounts
        vm.deal(otherAccount, 10 ether);
        vm.deal(thirdParty, 10 ether);
    }

    // Helper function to mint one token
    function _mintOneToken() internal {
        nft.buyTokens{value: FEE}(1);
    }

    // Helper function to mint multiple tokens
    function _mintTokens(uint256 amount) internal {
        nft.buyTokens{value: FEE * amount}(amount);
    }
}
