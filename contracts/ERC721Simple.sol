// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// https://docs.openzeppelin.com/contracts/4.x/wizard 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

contract ERC721Simple is ERC721URIStorage,  PullPayment, Ownable {

    //  uint256 public constant MINT_PRICE = 0.001 ether;
    constructor() ERC721("NFT Contract for marketplace", "MTK") {}

    function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
//    function withdrawPayments(address payable payee) public override onlyOwner virtual {
//       super.withdrawPayments(payee);
//   }
}