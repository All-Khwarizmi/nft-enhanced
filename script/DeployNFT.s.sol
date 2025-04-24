// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {NFT} from "../src/NFT.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract DeployNFT is Script {
    function run() public {
        vm.startBroadcast();

        string memory name = "TestNFT";
        string memory symbol = "TNFT";
        string memory baseURI =
            "https://lime-active-caterpillar-261.mypinata.cloud/ipfs/bafybeiautnry6btvtsxqll52doyz5wuzlnt73423r53gmazct3njer5wae/";
        uint256 revealTime = 1 days;
        bytes32 hash = keccak256(bytes(baseURI));
        uint256 maxSupply = 1;
        console.log("Deploying NFT with parameters:");
        console.log("Name: ", name);
        console.log("Symbol: ", symbol);
        console.log("Base URI: ", baseURI);
        console.log("Reveal Time: ", revealTime);
        console.log("Max Supply: ", maxSupply);

        NFT nft = new NFT(name, symbol, revealTime, hash, maxSupply);
        console.log("NFT deployed to address: ", address(nft));

        vm.stopBroadcast();
    }
}
