// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Ownable } from "@Openzeppelin/contracts/access/Ownable.sol";
import { IERC721A } from "@ERC721A/IERC721A.sol";
import { ReentrancyGuard } from "@Openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFT Marketplace
 * @author Carlos Gutiérrez
 * @notice NFT marketplace with fee per purchase
 */
contract NFTMarketPlace is Ownable, ReentrancyGuard {
    
    error NFTMarketPlace__YouDontOwnTheToken();
    error NFTMarketPlace__PriceCannotBeZero();
    error NFTMarketPlace__NFTNotListed();
    error NFTMarketPlace__IncorrectPrice();
    error NFTMarketPlace__TransferFailed();
    error NFTMarketPlace__CannotExceed100Percent();
    error NFTMarketPlace__CannotBeZeroAddress();
    error NFTMarketPlace__NoBalanceInContract();

    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }

    uint16 private constant PERCENTAGE_BASIS = 1000;

    uint16 private s_feeBasisPoints;   // basis of 1000 e.g., 25 = 2.5%
    address private s_feeRecipient;
    mapping(address nftAddress => mapping(uint256 tokenId => Listing sellingInfo)) private s_listing;

    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NFTCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event NFTSold(address indexed buyer, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256);
    event FeeUpdated(uint256 newFeeBasisPoints);
    event FeeRecipientUpdated(address newFeeRecipient);

    constructor(address _owner) Ownable(_owner) {
        s_feeRecipient = _owner;
        s_feeBasisPoints = 25; // 2.5% on a 1000 basis
    }

    // OnlyOwner functions
    /**
     * @dev Set fee basis Points
     * @param _feeBasisPoints specify the % of fee considering 1000 as 100%.
     */
    function setFeeBasisPoints(uint16 _feeBasisPoints) external onlyOwner {
        if (_feeBasisPoints > PERCENTAGE_BASIS) revert NFTMarketPlace__CannotExceed100Percent();
        s_feeBasisPoints = _feeBasisPoints;
        emit FeeUpdated(_feeBasisPoints);
    }

    /**
     * @dev Set Fee recipients
     * @param _feeRecipient the address that will be receiving the fees per purchase of NFT.
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        if (_feeRecipient == address(0)) revert NFTMarketPlace__CannotBeZeroAddress();
        s_feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    // General functions
    /**
     * @dev List NFT
     * @param _nftAddress nft address of the NFT you want to list.
     * @param _tokenId token ID of the nFT you want to list.
     * @param _price price that you want to receive for your NFT, there is a 2.5 fee to marketplace which will be substracted from the price.
     */
    function listNFT(address _nftAddress, uint256 _tokenId, uint256 _price) external nonReentrant {
        if (_price == 0) revert NFTMarketPlace__PriceCannotBeZero();
        if (IERC721A(_nftAddress).ownerOf(_tokenId) != msg.sender) revert NFTMarketPlace__YouDontOwnTheToken();

        Listing memory _listing = Listing({
            seller: msg.sender,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            price: _price
        });

        s_listing[_nftAddress][_tokenId] = _listing;

        emit NFTListed(msg.sender, _nftAddress, _tokenId, _price);
    }

    /**
     * @dev Buy NFT
     * @param _nftAddress nft address of the token you want to purchase.
     * @param _tokenId tokenId of the NFT you want to purchase.
     */
    function buyNFT(address _nftAddress, uint256 _tokenId) external payable nonReentrant {
        Listing memory listing = s_listing[_nftAddress][_tokenId];
        if (listing.price == 0) revert NFTMarketPlace__NFTNotListed();
        if (msg.value != listing.price) revert NFTMarketPlace__IncorrectPrice();

        delete s_listing[_nftAddress][_tokenId];

        IERC721A(_nftAddress).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);

        uint256 feeAmount = (listing.price * getFeeBasisPoints()) / uint256(PERCENTAGE_BASIS);
        uint256 sellerProceeds = listing.price - feeAmount;

        if (feeAmount > 0) {
            (bool feeSuccess, ) = getFeeRecipient().call{value: feeAmount}("");
            if (!feeSuccess) revert NFTMarketPlace__TransferFailed();
        }

        (bool sellerSuccess, ) = listing.seller.call{value: sellerProceeds}("");
        if (!sellerSuccess) revert NFTMarketPlace__TransferFailed();

        emit NFTSold(msg.sender, listing.seller, listing.nftAddress, listing.tokenId, listing.price);

    }

    /**
     * @dev Cancel listing
     * @param _nftAddress nftAddress of the token you want to cancel the listing.
     * @param _tokenId tokenId of the NFT you want to cancel the listing.
     */
    function cancelListing(address _nftAddress, uint256 _tokenId) external {
        Listing memory listing = s_listing[_nftAddress][_tokenId];
        if (listing.seller != msg.sender) revert NFTMarketPlace__YouDontOwnTheToken();

        delete s_listing[_nftAddress][_tokenId];

        emit NFTCanceled(msg.sender, _nftAddress, _tokenId);
    }

    /**
     * @dev Get fee basis points
     * @return feeBasisPoints
     */
    function getFeeBasisPoints() public view returns(uint256 feeBasisPoints) {
        feeBasisPoints = uint256(s_feeBasisPoints);
    }

    /**
     * @dev Get fee recipient
     * @return recipient
     */
    function getFeeRecipient() public view returns(address recipient) {
        recipient = s_feeRecipient;
    }

    /**
     * @dev Get NFT list Info
     * @param _nftAddress NFT address
     * @param _tokenId token ID
     * @return listedNft
     */
    function getnftListInfo(address _nftAddress, uint256 _tokenId) external view returns(Listing memory listedNft) {
        listedNft = s_listing[_nftAddress][_tokenId];
    }
    
}
