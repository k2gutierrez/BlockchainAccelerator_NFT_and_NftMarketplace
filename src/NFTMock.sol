// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC721A } from "@ERC721A/ERC721A.sol";
import { Ownable } from "@Openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@Openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMock is ERC721A, Ownable, ReentrancyGuard {

    error NFTMock__SoldOut();
    error NFTMock__IncorrectPrice();
    error NFTMock__CannotPurchaseThatAmount();
    error NFTMock__NoBalanceInContract();
    error NFTMock__TransferFailed();
    error NFTMock__CannotSetMoreThan255();
    error NFTMock__PriceMustBeDifferent();
    error NFTMock__CannotBeSameValue();
    error NFTMock__MaxAmountReachedOrInvalidPerWallet();
    error NFTMock__NftIsSoulbound();

    uint256 private immutable i_MaxSupply;
    uint256 private s_nftPrice;
    uint8 private s_maxAmountPerWallet;
    bool private i_soulbound;

    constructor(string memory _name, string memory _symbol, address _owner, uint256 _price, uint256 _maxSupply, uint8 _maxAmountPerWallet, bool _soulbound) ERC721A(_name, _symbol) Ownable(_owner) {
        s_nftPrice = _price;
        i_MaxSupply = _maxSupply;
        s_maxAmountPerWallet = _maxAmountPerWallet;
        i_soulbound = _soulbound;
    }

    // Only Owner functions
    /**
     * @dev Set Nft price
     * @param _price new price
     */
    function setNFTPrice(uint256 _price) external onlyOwner {
        if (_price == getNftPrice()) revert NFTMock__PriceMustBeDifferent();
        s_nftPrice = _price;
    }

    /**
     * @dev Set max per wallet allowed - only owner
     */
    function setMaxPerWalletAllowed(uint8 newAmount) external onlyOwner {
        if (newAmount > 255) revert NFTMock__CannotSetMoreThan255();
        if (newAmount == getMaxAmountToPurchasePerWallet()) revert NFTMock__CannotBeSameValue();
        s_maxAmountPerWallet = newAmount;
    }

    /**
     * @dev Only owner function to withdraw balance
     */
    function withdrawBalance() external onlyOwner nonReentrant {
        if (address(this).balance == 0) revert NFTMock__NoBalanceInContract();
        uint256 balanceToWithdraw = address(this).balance;

        (bool success, ) = owner().call{value: balanceToWithdraw}("");
        if (!success) revert NFTMock__TransferFailed();
    }

    // General functions
    /**
     * @dev Mint function
     * @param _quantity Amount of NFTs to purchase
     */
    function mint(uint256 _quantity) external payable nonReentrant {
        uint256 maxamountPerWallet = getMaxAmountToPurchasePerWallet();
        if (totalSupply() + _quantity > getMaxSupply()) revert NFTMock__SoldOut();
        if (_quantity > maxamountPerWallet) revert NFTMock__CannotPurchaseThatAmount();
        if (balanceOf(msg.sender) + _quantity > maxamountPerWallet) revert NFTMock__MaxAmountReachedOrInvalidPerWallet();
        if (msg.value != getNftPrice() * _quantity) revert NFTMock__IncorrectPrice();
        
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @dev Hook to make soulbound
     * @param from address sending token
     * @param to address to receive token
     * @param startTokenId start token ID
     * @param quantity amount to transfer
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (i_soulbound) {
            if (from != address(0) && to != address(0)) revert NFTMock__NftIsSoulbound();
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * @dev NFT Collection starts with TokenId 1
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Get max supply
     * @return maxSupply
     */
    function getMaxSupply() public view returns(uint256 maxSupply) {
        maxSupply = i_MaxSupply;
    }

    /**
     * @dev Get nft price
     * @return nftPrice
     */
    function getNftPrice() public view returns(uint256 nftPrice) {
        nftPrice = s_nftPrice;
    }

    /**
     * @dev Get max amount to purchase per wallet
     * @return maxAmountPerWallet
     */
    function getMaxAmountToPurchasePerWallet() public view returns(uint8 maxAmountPerWallet) {
        maxAmountPerWallet = s_maxAmountPerWallet;
    }

}