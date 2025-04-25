// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {NFTBaseTest} from "./NFTBaseTest.t.sol";
import {IERC721} from "../src/interface/IERC721.sol";
import {NFT} from "../src/NFT.sol";


/// @title MintingTest
/// @notice Tests for NFT minting functionality
contract MintingTest is NFTBaseTest {
    // =========================================================================
    // Happy Paths
    // =========================================================================
    function test_buyTokens_mintSingleToken() public {
        nft.buyTokens{value: FEE}(1);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(0), owner);
        assertEq(nft.balanceOf(owner), 1);
    }

    function test_buyTokens_mintMultipleTokens() public {
        uint256 amount = 3;
        nft.buyTokens{value: FEE * amount}(amount);

        assertEq(nft.totalSupply(), amount);
        assertEq(nft.balanceOf(owner), amount);

        // Verify each token is assigned to the right owner
        for (uint256 i = 0; i < amount; i++) {
            assertEq(nft.ownerOf(i), owner);
        }
    }

    function test_receiveFunction_mintTokensWithExactAmount() public {
        (bool success,) = address(nft).call{value: FEE}("");

        assertTrue(success);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(0), address(this));
    }

    function test_receiveFunction_mintTokensWithExcessAmount() public {
        uint256 excessAmount = 0.005 ether;
        (bool success,) = address(nft).call{value: FEE + excessAmount}("");

        assertTrue(success);
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(0), address(this));
        assertEq(nft.ethBalances(address(this)), excessAmount);
    }

    // =========================================================================
    // Events
    // =========================================================================
    function test_buyTokens_emitsTransferEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(address(0), owner, 0);

        nft.buyTokens{value: FEE}(1);
    }

    // =========================================================================
    // Unhappy Paths
    // =========================================================================
    function test_buyTokens_revertWhenIncorrectPayment() public {
        uint256 incorrectAmount = FEE - 0.001 ether;

        vm.expectRevert(abi.encodeWithSelector(NFT.NotExpectedValue.selector));
        nft.buyTokens{value: incorrectAmount}(1);
    }

    function test_buyTokens_revertWhenExceedingMaxSupply() public {
        vm.assume(nft.MAX_SUPPLY() > 0);

        uint256 initialSupply = nft.totalSupply();
        uint256 amountToMint = nft.MAX_SUPPLY() - initialSupply;

        if (amountToMint > 0) {
            nft.buyTokens{value: FEE * amountToMint}(amountToMint);
        }

        // Try to mint one more - should revert
        vm.expectRevert(abi.encodeWithSelector(NFT.NotEnoughSupply.selector));
        nft.buyTokens{value: FEE}(1);
    }

    // =========================================================================
    // Multiple Actors
    // =========================================================================
    function test_buyTokens_multipleUsersMint() public {
        _mintOneToken();

        vm.prank(otherAccount);
        nft.buyTokens{value: FEE}(1);

        vm.prank(thirdParty);
        nft.buyTokens{value: FEE}(1);

        assertEq(nft.totalSupply(), 3);

        assertEq(nft.balanceOf(owner), 1);
        assertEq(nft.balanceOf(otherAccount), 1);
        assertEq(nft.balanceOf(thirdParty), 1);

        assertEq(nft.ownerOf(0), owner);
        assertEq(nft.ownerOf(1), otherAccount);
        assertEq(nft.ownerOf(2), thirdParty);
    }

    // =========================================================================
    // Fuzz Testing
    // =========================================================================
    function test_fuzz_buyTokens(uint256 amount) public {
        amount = bound(amount, 1, 10);
        uint256 supplyLeft = nft.getSupplyLeft();
        vm.assume(supplyLeft >= amount);

        nft.buyTokens{value: FEE * amount}(amount);

        assertEq(nft.totalSupply(), amount);
        assertEq(nft.balanceOf(owner), amount);
    }
}
