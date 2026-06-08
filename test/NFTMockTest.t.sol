// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NFTMock} from "../src/NFTMock.sol";
import {NFTMarketPlace} from "../src/NFTMarketPlace.sol";
import {NFTMarketPlaceScript} from "../script/NFTMarketPlaceScript.s.sol";

contract NFTMockTest is Test {
    // Contract variables
    NFTMock public nftMock;
    NFTMarketPlace public nftMarket;

    // Constants and variables for testing
    uint256 constant PRICE = .5 ether;
    uint256 constant MAX_SUPPLY = 3;
    uint8 constant MAX_AMOUNT_PER_WALLET = 2;
    uint256 constant ethAmountForAccounts = 20 ether;
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address owner;

    function setUp() public {
        NFTMarketPlaceScript deployer = new NFTMarketPlaceScript();
        (nftMock, nftMarket) = deployer.run();
        owner = nftMock.owner();
        vm.deal(owner, ethAmountForAccounts);
        vm.deal(user1, ethAmountForAccounts);
        vm.deal(user2, ethAmountForAccounts);
    }

    // only Owner functions
    function testSetNFTPrice() external {

        uint256 oldPrice = nftMock.getNftPrice();
        uint256 newPrice = 1 ether;

        vm.prank(owner);
        nftMock.setNFTPrice(newPrice);
        uint256 price = nftMock.getNftPrice();

        assertNotEq(oldPrice, price);
    }

    function testSetNFTPriceRevertSamePrice() external {
        uint256 newPrice = nftMock.getNftPrice();

        vm.prank(owner);
        vm.expectRevert(NFTMock.NFTMock__PriceMustBeDifferent.selector);
        nftMock.setNFTPrice(newPrice);
    }

    function testSetNFTPriceRevertNotTheOwner() external {
        uint256 newPrice = 1 ether;

        vm.prank(user1);
        vm.expectRevert();
        nftMock.setNFTPrice(newPrice);
    }

    function testSetMaxPerWalletAllowed() external {
        uint8 oldAmount = nftMock.getMaxAmountToPurchasePerWallet();
        uint8 newAmount = 255;

        vm.prank(owner);
        nftMock.setMaxPerWalletAllowed(newAmount);
        
        uint8 amount = nftMock.getMaxAmountToPurchasePerWallet();

        assertNotEq(oldAmount, amount);
    }

    function testSetMaxPerWalletAllowedRevertSameAmount() external {
        uint8 amount = nftMock.getMaxAmountToPurchasePerWallet();

        vm.prank(owner);
        vm.expectRevert(NFTMock.NFTMock__CannotBeSameValue.selector);
        nftMock.setMaxPerWalletAllowed(amount);
    }

    function testSetMaxPerWalletAllowedRevertNotOwner() external {
        uint8 amount = 100;

        vm.prank(user1);
        vm.expectRevert();
        nftMock.setMaxPerWalletAllowed(amount);
    }

    function testWithdrawBalanceRevertNoBalance() external {

        vm.prank(owner);
        vm.expectRevert(NFTMock.NFTMock__NoBalanceInContract.selector);
        nftMock.withdrawBalance();

    }

    function testWithdrawBalanceRevertNotTheOwner() external {

        vm.prank(user1);
        vm.expectRevert();
        nftMock.withdrawBalance();
    }

    function testWithdrawBalance() external {
        uint256 amountOfNfts = nftMock.getMaxAmountToPurchasePerWallet();
        uint256 amountEth = amountOfNfts * nftMock.getNftPrice();

        vm.prank(user1);
        nftMock.mint{value: amountEth}(amountOfNfts);

        uint256 ownerBalanceBefore = address(owner).balance;
        uint256 contractBalanceBefore = address(nftMock).balance;

        vm.prank(owner);
        nftMock.withdrawBalance();

        uint256 ownerBalanceAfter = address(owner).balance;
        uint256 contractBalanceAfter = address(nftMock).balance;

        assert(contractBalanceBefore == amountEth);
        assert(contractBalanceAfter == 0);
        assertNotEq(contractBalanceBefore, contractBalanceAfter);
        assertNotEq(ownerBalanceBefore, ownerBalanceAfter);
    }

    // getter functions
    function testGetMaxSupply() external view {
        uint256 maxSupply = nftMock.getMaxSupply();

        assert(maxSupply == MAX_SUPPLY);
    }

    function testGetNftPrice() external view {
        uint256 nftPrice = nftMock.getNftPrice();

        assert(nftPrice == PRICE);
    }

    function testGetMaxAmountToPurchasePerWallet() external view {
        uint256 maxAmountPerWallet = nftMock.getMaxAmountToPurchasePerWallet();

        assert(maxAmountPerWallet == MAX_AMOUNT_PER_WALLET);
    }

    // Checking first nft starts on tokenId 1
    function testFisrtNftTokenIdIs1() external {
        uint256 amountOfNfts = nftMock.getMaxAmountToPurchasePerWallet();
        uint256 amountEth = amountOfNfts * nftMock.getNftPrice();

        vm.prank(user1);
        nftMock.mint{value: amountEth}(amountOfNfts);

        assert(nftMock.balanceOf(user1) == amountOfNfts);

        for (uint256 i; i < amountOfNfts; i++) {
            assert(nftMock.ownerOf(i + 1) == user1);
        }

        vm.expectRevert();
        nftMock.ownerOf(0);
    }

    // Mint function
    function testMint() external {
        uint256 amountOfNfts = nftMock.getMaxAmountToPurchasePerWallet();
        uint256 amountEth = amountOfNfts * nftMock.getNftPrice();

        uint256 user1BalanceBefore = user1.balance;

        vm.prank(user1);
        nftMock.mint{value: amountEth}(amountOfNfts);

        uint256 user1BalanceAfter = user1.balance;

        assert(nftMock.balanceOf(user1) == amountOfNfts);

        assertNotEq(user1BalanceBefore, user1BalanceAfter);
    }

    // if (totalSupply() + _quantity > getMaxSupply()) revert NFTMock__SoldOut();
    function testMintRevertsMaxSupplyReached() external {

        uint256 amountOfNfts = nftMock.getMaxAmountToPurchasePerWallet();
        uint256 amountEth = amountOfNfts * nftMock.getNftPrice();

        vm.prank(user1);
        nftMock.mint{value: amountEth}(amountOfNfts);

        uint256 user2Amount = 1;

        vm.startPrank(user2);
        nftMock.mint{value: PRICE}(user2Amount);

        uint256 totalSupply = nftMock.totalSupply();

        console2.log("Total Suppply: ", totalSupply);
        vm.stopPrank();

        vm.prank(user2);
        vm.expectRevert(NFTMock.NFTMock__SoldOut.selector);
        nftMock.mint{value: PRICE}(user2Amount);
    }

    function testMintRevertsAmountNotAllowed() external {

        uint256 amountOfNfts = nftMock.getMaxAmountToPurchasePerWallet() + 1;
        uint256 amountEth = amountOfNfts * nftMock.getNftPrice();

        vm.prank(user1);
        vm.expectRevert(NFTMock.NFTMock__CannotPurchaseThatAmount.selector);
        nftMock.mint{value: amountEth}(amountOfNfts);
    }

    function testMintRevertsAmountNotAllowedMaxPerWalletReached() external {

        uint256 amountOfNfts = nftMock.getMaxAmountToPurchasePerWallet();
        uint256 amountEth = amountOfNfts * nftMock.getNftPrice();

        vm.prank(user1);
        nftMock.mint{value: amountEth}(amountOfNfts);

        vm.prank(user1);
        vm.expectRevert(NFTMock.NFTMock__MaxAmountReachedOrInvalidPerWallet.selector);
        nftMock.mint{value: PRICE}((amountOfNfts - 1));
    }

    function testMintRevertIncorrectHigherPrice() external {
        uint256 amountOfNfts = nftMock.getMaxAmountToPurchasePerWallet();
        uint256 amountEth = amountOfNfts * (nftMock.getNftPrice() + 1 ether);

        vm.expectRevert(NFTMock.NFTMock__IncorrectPrice.selector);
        vm.prank(user1);
        nftMock.mint{value: amountEth}(amountOfNfts);

    }

    function testMintRevertIncorrectLowerPrice() external {
        uint256 amountOfNfts = nftMock.getMaxAmountToPurchasePerWallet();
        uint256 amountEth = nftMock.getNftPrice();

        vm.expectRevert(NFTMock.NFTMock__IncorrectPrice.selector);
        vm.prank(user1);
        nftMock.mint{value: amountEth}(amountOfNfts);

    }

}