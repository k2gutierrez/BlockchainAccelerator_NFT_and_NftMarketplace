// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {NFTMarketPlace} from "../src/NFTMarketPlace.sol";
import {NFTMock} from "../src/NFTMock.sol";

contract NFTMarketPlaceScript is Script {

    // Contract variables
    NFTMarketPlace public nftMarket;
    NFTMock public nftMock;
    NFTMock public nftMock2;

    // Constructor arguments
    address _owner = makeAddr("owner");
    string _name = "K2NFT";
    string _symbol = "K2";
    uint256 _price = .5 ether;
    uint256 _maxSupply = 3;
    uint8 _maxAmountPerWallet = 2;
    bool soulbound1 = false;

    // function setUp() public {}

    function run() public returns(NFTMock, NFTMarketPlace) {

        vm.startBroadcast();

        nftMock = new NFTMock(_name, _symbol, _owner, _price, _maxSupply, _maxAmountPerWallet, soulbound1);
        nftMarket = new NFTMarketPlace(_owner);

        vm.stopBroadcast();

        return (nftMock, nftMarket);
    }
}
