// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NFTMock} from "../src/NFTMock.sol";
import {NFTMarketPlace} from "../src/NFTMarketPlace.sol";
import {NFTMarketPlaceScript} from "../script/NFTMarketPlaceScript.s.sol";

contract NFTMarketPlaceTest is Test {

    // Contract variables
    NFTMock public nftMock;
    NFTMock public nftMock2;
    NFTMarketPlace public nftMarket;

    // Constants and variables for testing
    uint256 constant PRICE = .5 ether;
    uint256 constant ethAmountForAccounts = 100 ether;
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");
    address public owner;

    function setUp() public {
        NFTMarketPlaceScript deployer = new NFTMarketPlaceScript();
        (nftMock, nftMarket) = deployer.run();

        owner = nftMarket.owner();
        vm.deal(nftMock.owner(), ethAmountForAccounts);
        vm.deal(user1, ethAmountForAccounts);
        vm.deal(user2, ethAmountForAccounts);
        vm.deal(user3, ethAmountForAccounts);
        vm.deal(owner, ethAmountForAccounts);

        vm.startBroadcast();

        nftMock2 = new NFTMock("VaneNft", "VANSAN", owner, .5 ether, 3, 2, true);

        vm.stopBroadcast();

        // User1 has 1 nft minted from nftMock and nftMock2 - TokenId 1
        vm.startPrank(user1);
        nftMock.mint{value: PRICE}(1);
        nftMock2.mint{value: PRICE}(1);
        vm.stopPrank();

        // User2 has 1 nft minted TokenId 1
        vm.prank(user2);
        nftMock.mint{value: PRICE}(1);

    }

    // OnlyOwner functions
    function testSetFeeBasisPoints() external {
        uint16 basis = 50; // 5%, starint at 2.5%
        uint256 actualPercentage = nftMarket.getFeeBasisPoints(); // must be 25

        vm.prank(owner);
        nftMarket.setFeeBasisPoints(basis);
        
        uint256 newPercentage = nftMarket.getFeeBasisPoints();
        console2.log("First percentage: ", actualPercentage);
        console2.log("Second percentage: ", newPercentage);
        assertNotEq(actualPercentage, newPercentage);
        assert(newPercentage == basis);
    }

    function testSetFeeBasisPointsRevertsNotOwner() external {
        uint16 basis = 50; // 5%, starint at 2.5%

        vm.prank(user1);
        vm.expectRevert();
        nftMarket.setFeeBasisPoints(basis);
        
    }

    function testSetFeeBasisPointsRevertsCannotExceed100Percent() external {
        uint16 basis = 1000 + 1; // 5%, starint at 2.5%

        vm.prank(owner);
        vm.expectRevert(NFTMarketPlace.NFTMarketPlace__CannotExceed100Percent.selector);
        nftMarket.setFeeBasisPoints(basis);
        
    }

    function testSetFeeRecipient() external {
        address newReceiver = user1;
        address currentAddress = nftMarket.getFeeRecipient();

        vm.prank(owner);
        nftMarket.setFeeRecipient(newReceiver);

        address newAddress = nftMarket.getFeeRecipient();

        assertNotEq(newAddress, currentAddress);
        assert(newAddress == newReceiver);
    }

    function testSetFeeRecipientRevertsCannotBeAddressZero() external {
        address newReceiver = address(0);

        vm.prank(owner);
        vm.expectRevert(NFTMarketPlace.NFTMarketPlace__CannotBeZeroAddress.selector);
        nftMarket.setFeeRecipient(newReceiver);
    }

    function testSetFeeRecipientNotTheOwner() external {
        address newReceiver = user1;

        vm.prank(newReceiver);
        vm.expectRevert();
        nftMarket.setFeeRecipient(newReceiver);
    }

    // Getter functions
    function testGetFeeBasisPoints() external view {
        uint256 actualBasisPoints = nftMarket.getFeeBasisPoints(); // 25 starting on constructor
        
        assert(actualBasisPoints == 25);
    }

    function testGetFeeRecipient() external view {
        address currentFeeRecipient = nftMarket.getFeeRecipient(); // starts as an address created on script, we are calling it vía a variable called owner here

        assert(currentFeeRecipient == owner);
    
    }

    function testGetnftListInfo() external {
        address nftAddress = address(nftMock);
        uint256 tokenId = 1;
        uint256 nftPrice = PRICE;

        vm.startPrank(user1);
        nftMock.approve(address(nftMarket), tokenId);
        nftMarket.listNFT(nftAddress, tokenId, nftPrice);
        vm.stopPrank();

        NFTMarketPlace.Listing memory listingInfoUser1 = nftMarket.getnftListInfo(nftAddress, tokenId);

        assert(user1 == listingInfoUser1.seller);
        assert(nftAddress == listingInfoUser1.nftAddress);
        assert(tokenId == listingInfoUser1.tokenId);
        assert(nftPrice == listingInfoUser1.price);
    }

    // List function
    function testListNFT() external {

        address nftAddress = address(nftMock);
        uint256 tokenId = 1;
        uint256 nftPrice = PRICE;

        vm.startPrank(user1);
        nftMock.approve(address(nftMarket), tokenId);
        nftMarket.listNFT(nftAddress, tokenId, nftPrice);
        vm.stopPrank();

        NFTMarketPlace.Listing memory listingInfoUser1 = nftMarket.getnftListInfo(nftAddress, tokenId);

        assert(user1 == listingInfoUser1.seller);
        assert(nftAddress == listingInfoUser1.nftAddress);
        assert(tokenId == listingInfoUser1.tokenId);
        assert(nftPrice == listingInfoUser1.price);
    }

    function testListNFTRevertsPrizeCannotBeZero() external {
        address currentSender = user1;
        address nftAddress = address(nftMock);
        uint256 tokenId = 1;
        uint256 nftPrice = 0;

        vm.prank(currentSender);
        vm.expectRevert(NFTMarketPlace.NFTMarketPlace__PriceCannotBeZero.selector);
        nftMarket.listNFT(nftAddress, tokenId, nftPrice);

    }

    function testListNFTRevertsNotTheOwnerOfTheNFT() external {

        address nftAddress = address(nftMock);
        uint256 tokenId = 1; // user1 minted the first token so user2 is not owner of tokenId 1
        uint256 nftPrice = PRICE;
        vm.prank(user2);
        vm.expectRevert(NFTMarketPlace.NFTMarketPlace__YouDontOwnTheToken.selector);
        nftMarket.listNFT(nftAddress, tokenId, nftPrice);
    }

    // Cancel listing function
    function testCancelListing() external {
        address nftAddress = address(nftMock);
        uint256 tokenId = 1;
        uint256 nftPrice = PRICE;

        vm.startPrank(user1);
        nftMock.approve(address(nftMarket), tokenId);
        nftMarket.listNFT(nftAddress, tokenId, nftPrice);
        vm.stopPrank();

        NFTMarketPlace.Listing memory listingInfoUser1 = nftMarket.getnftListInfo(nftAddress, tokenId);

        assert(user1 == listingInfoUser1.seller);
        assert(nftAddress == listingInfoUser1.nftAddress);
        assert(tokenId == listingInfoUser1.tokenId);
        assert(nftPrice == listingInfoUser1.price);

        vm.prank(user1);
        nftMarket.cancelListing(nftAddress, tokenId);

        NFTMarketPlace.Listing memory listingInfoUse1Cancelled = nftMarket.getnftListInfo(nftAddress, tokenId);

        assert(address(0) == listingInfoUse1Cancelled.seller);
        assert(address(0) == listingInfoUse1Cancelled.nftAddress);
        assert(0 == listingInfoUse1Cancelled.tokenId);
        assert(0 == listingInfoUse1Cancelled.price);
    }

    function testCancelListingRevertsNotTheSeller() external {
        address nftAddress = address(nftMock);
        uint256 tokenId = 1;
        uint256 nftPrice = PRICE;

        vm.startPrank(user1);
        nftMock.approve(address(nftMarket), tokenId);
        nftMarket.listNFT(nftAddress, tokenId, nftPrice);
        vm.stopPrank();

        NFTMarketPlace.Listing memory listingInfoUser1 = nftMarket.getnftListInfo(nftAddress, tokenId);

        assert(user1 == listingInfoUser1.seller);
        assert(nftAddress == listingInfoUser1.nftAddress);
        assert(tokenId == listingInfoUser1.tokenId);
        assert(nftPrice == listingInfoUser1.price);

        vm.prank(user2);
        vm.expectRevert(NFTMarketPlace.NFTMarketPlace__YouDontOwnTheToken.selector);
        nftMarket.cancelListing(nftAddress, tokenId);
    }

    // Buy NFT function
    function testBuyNFT() external {
        address nftAddress = address(nftMock);
        uint256 tokenId = 1;
        uint256 nftPrice = PRICE;

        uint256 nftBalanceOfUserBefore1 = nftMock.balanceOf(user1);
        uint256 nftBalanceOfUserBefore2 = nftMock.balanceOf(user2);

        vm.startPrank(user1);
        nftMock.approve(address(nftMarket), tokenId);
        nftMarket.listNFT(nftAddress, tokenId, nftPrice);
        vm.stopPrank();

        uint256 ethBalanceUserBeforeUser1 = user1.balance;
        uint256 ethBalanceUserBeforeUser2 = user2.balance;
        uint256 ethBalanceUserBeforeFeeRecipient = nftMarket.getFeeRecipient().balance;

        vm.prank(user2);
        nftMarket.buyNFT{value: (PRICE)}(nftAddress, tokenId);

        uint256 nftBalanceOfUserAfter1 = nftMock.balanceOf(user1);
        uint256 nftBalanceOfUserAfter2 = nftMock.balanceOf(user2);

        assert(nftBalanceOfUserBefore1 != nftBalanceOfUserAfter1);
        assertNotEq(nftBalanceOfUserBefore1, nftBalanceOfUserAfter1);
        assert(nftBalanceOfUserBefore2 != nftBalanceOfUserAfter2);
        assertNotEq(nftBalanceOfUserBefore2, nftBalanceOfUserAfter2);
        assert(nftBalanceOfUserAfter1 == 0);
        assert(nftBalanceOfUserAfter2 == 2);

        uint256 ethBalanceUserAfterUser1 = user1.balance;
        uint256 ethBalanceUserAfterUser2 = user2.balance;
        uint256 ethBalanceUserAfterFeeRecipient = nftMarket.getFeeRecipient().balance;

        assertNotEq(ethBalanceUserBeforeUser1, ethBalanceUserAfterUser1);
        assert(ethBalanceUserBeforeUser1 < ethBalanceUserAfterUser1);

        assertNotEq(ethBalanceUserBeforeUser2, ethBalanceUserAfterUser2);
        assert(ethBalanceUserBeforeUser2 > ethBalanceUserAfterUser2);

        assertNotEq(ethBalanceUserBeforeFeeRecipient, ethBalanceUserAfterFeeRecipient);
        assert(ethBalanceUserBeforeFeeRecipient < ethBalanceUserAfterFeeRecipient);

        assert(nftMock.ownerOf(1) == user2);

    }

    function testBuyNFTFromMock2RevertsIsSouldound() external {
        address nftAddress = address(nftMock2);
        uint256 tokenId = 1;
        uint256 nftPrice = PRICE;

        vm.startPrank(user1);
        nftMock2.approve(address(nftMarket), tokenId);
        nftMarket.listNFT(nftAddress, tokenId, nftPrice);
        vm.stopPrank();

        vm.prank(user2);
        vm.expectRevert(NFTMock.NFTMock__NftIsSoulbound.selector);
        nftMarket.buyNFT{value: (PRICE)}(nftAddress, tokenId);

    }

    function testBuyNFTRevertsNFTNotListed() external {
        address nftAddress = address(nftMock);
        uint256 tokenId = 1;
        uint256 nftPrice = PRICE;

        vm.prank(user2); // user wants to purchase tokenId but there is no listing yet of that NFT
        vm.expectRevert(NFTMarketPlace.NFTMarketPlace__NFTNotListed.selector);
        nftMarket.buyNFT{value: nftPrice}(nftAddress, tokenId);
        
    }

    function testBuyNFTRevertsIncorrectPriceSentHigherPrice() external {
        address nftAddress = address(nftMock);
        uint256 tokenId = 1;
        uint256 nftPrice = PRICE;

        vm.startPrank(user1);
        nftMock.approve(address(nftMarket), tokenId);
        nftMarket.listNFT(nftAddress, tokenId, nftPrice);
        vm.stopPrank();

        vm.prank(user2);
        vm.expectRevert(NFTMarketPlace.NFTMarketPlace__IncorrectPrice.selector);
        nftMarket.buyNFT{value: (PRICE + 1)}(nftAddress, tokenId);
        
    }

    function testBuyNFTRevertsIncorrectPriceSentLowerPrice() external {
        address nftAddress = address(nftMock);
        uint256 tokenId = 1;
        uint256 nftPrice = PRICE;

        vm.startPrank(user1);
        nftMock.approve(address(nftMarket), tokenId);
        nftMarket.listNFT(nftAddress, tokenId, nftPrice);
        vm.stopPrank();

        vm.prank(user2);
        vm.expectRevert(NFTMarketPlace.NFTMarketPlace__IncorrectPrice.selector);
        nftMarket.buyNFT{value: (PRICE - 2)}(nftAddress, tokenId);
        
    }

}
