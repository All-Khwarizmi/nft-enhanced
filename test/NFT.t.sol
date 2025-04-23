// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/NFT.sol";

contract NFTTest is Test {
    NFT nft;
    address owner;
    address otherAccount;
    address thirdParty;

    // Setup function (equivalent to deployNFTFixture)
    function setUp() public {
        owner = address(this);
        otherAccount = makeAddr("otherAccount");
        thirdParty = makeAddr("thirdParty");

        // Adjust constructor parameters according to your updated contract
        nft = new NFT("TestNFT", "TNFT", 1 days, bytes32(0), 5);
    }

    // Helper function for mintFixture
    function mintOneToken() public {
        nft.buyTokens{value: 0.01 ether}(1);
    }

    // Deployment tests
    function testDeployment() public view {
        assertEq(nft.totalSupply(), 0);
        assertEq(nft.MAX_SUPPLY(), 5); // Updated to match your contract's value
        assertEq(nft.FEE(), 0.01 ether);
    }

    // Mint tests
    function testRevertIfNotExactAmount() public {
        vm.expectRevert(abi.encodeWithSelector(NFT.NotExpectedValue.selector));
        nft.buyTokens{value: 0.02 ether}(1);
    }

    function testMintToken() public {
        nft.buyTokens{value: 0.01 ether}(1);
        assertEq(nft.totalSupply(), 1);
    }

    function testMintFixture() public {
        mintOneToken();
        assertEq(nft.ownerOf(0), owner);
    }

    // ownerOf tests
    function testOwnerOfZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(NFT.InvalidToken.selector, 0));
        nft.ownerOf(0);
    }

    function testOwnerOfCorrectAddress() public {
        mintOneToken();
        assertEq(nft.ownerOf(0), owner);
    }

    // balanceOf tests
    function testBalanceOf() public {
        mintOneToken();
        assertEq(nft.balanceOf(owner), 1);

        nft.buyTokens{value: 0.01 ether}(1);
        assertEq(nft.balanceOf(owner), 2);
    }

    // getApproved tests
    function testGetApproved() public {
        mintOneToken();
        nft.approve(otherAccount, 0);
        assertEq(nft.getApproved(0), otherAccount);
    }

    function testGetApprovedZeroAddress() public {
        // Note: This test might fail if your contract doesn't allow querying approvals for non-existent tokens
        address zeroAddress = address(0);
        assertEq(nft.getApproved(0), zeroAddress);
    }

    // isApprovedForAll tests
    function testIsApprovedForAll() public {
        mintOneToken();
        nft.setApprovalForAll(otherAccount, true);
        assertTrue(nft.isApprovedForAll(owner, otherAccount));
    }

    function testIsApprovedForAllFalse() public {
        mintOneToken();
        assertFalse(nft.isApprovedForAll(owner, otherAccount));
    }

    // Approve tests
    function testApproveNotAuthorized() public {
        mintOneToken();
        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.approve(owner, 0);
    }

    function testApproveByOwner() public {
        mintOneToken();
        nft.approve(otherAccount, 0);
        assertEq(nft.getApproved(0), otherAccount);
    }

    function testApproveByOperator() public {
        mintOneToken();
        nft.setApprovalForAll(otherAccount, true);

        vm.prank(otherAccount);
        nft.approve(thirdParty, 0);

        assertEq(nft.getApproved(0), thirdParty);
    }

    // setApprovalForAll tests
    function testSetApprovalForAll() public {
        mintOneToken();
        nft.setApprovalForAll(otherAccount, true);
        assertTrue(nft.isApprovedForAll(owner, otherAccount));
    }

    function testDisableApprovalForAll() public {
        mintOneToken();
        nft.setApprovalForAll(otherAccount, true);
        nft.setApprovalForAll(otherAccount, false);
        assertFalse(nft.isApprovedForAll(owner, otherAccount));
    }

    function testEmitApprovalForAllEvent() public {
        mintOneToken();

        vm.expectEmit(true, true, true, true);
        emit IERC721.ApprovalForAll(owner, otherAccount, true);

        nft.setApprovalForAll(otherAccount, true);
    }

    // transferFrom tests
    function testTransferFromNotAuthorized() public {
        mintOneToken();

        vm.prank(thirdParty);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, thirdParty));
        nft.transferFrom(owner, otherAccount, 0);
    }

    function testTransferFromWrongOwner() public {
        mintOneToken();
        nft.approve(otherAccount, 0);

        vm.prank(otherAccount);
        vm.expectRevert(abi.encodeWithSelector(NFT.NotAuthorized.selector, otherAccount));
        nft.transferFrom(otherAccount, thirdParty, 0);
    }

    function testTransferFrom() public {
        mintOneToken();
        nft.transferFrom(owner, otherAccount, 0);
        assertEq(nft.ownerOf(0), otherAccount);
    }

    function testTransferFromByOperator() public {
        mintOneToken();
        nft.setApprovalForAll(otherAccount, true);

        vm.prank(otherAccount);
        nft.transferFrom(owner, thirdParty, 0);

        assertEq(nft.ownerOf(0), thirdParty);
    }

    function testTransferFromToZeroAddress() public {
        mintOneToken();

        vm.expectRevert(abi.encodeWithSelector(NFT.ZeroAddress.selector));
        nft.transferFrom(owner, address(0), 0);
    }

    function testEmitTransferEvent() public {
        mintOneToken();

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(owner, otherAccount, 0);

        nft.transferFrom(owner, otherAccount, 0);
    }
}
