// SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.22 <0.9.0;

interface INftMarketplace {

function createItem(address _nftContract, address _to, string memory _uri) external returns (uint256 _tokenId);

function listItems(uint256 _selectId, uint256 _price, address _erc20Contract) external returns (bool);

function buyItem(uint256 _selectId) external returns (bool);

function cancel(uint256 _selectId) external returns (bool);

function listItemOnAuction(uint256 _selectId, uint256 _minPrice, address _erc20Contract) external returns (bool);

function cancelAuction(uint256 _selectId) external returns (bool);

function cancelBid(uint256 _selectId) external;

function makeBid(uint256 _selectId, uint256 _bidPrice) external returns (bool);

function finishAuction(uint256 _selectId) external returns (address _winner, uint256 maxBid);

// сервисные функции: 

function addDealer(address _dealer) external ;

function deleteDealers(address _dealer, uint256 _selectId) external;

function addNftContract(address _nftContract) external;

function addERC20Contract(address _erc20Contract) external;

function deleteNftContract(address _nftContract) external;

function deleteERC20Contract(address _erc20Contract) external;        

function isDealer(address _address) external returns (bool);

function isNftContract(address _nftContract) external returns (bool);

function isERC20Contract(address _address) external returns (bool);

function changeAucTime(uint32 _time) external;

function getDealerIdTokenExist(address _dealer, address _nftContract, uint256 _selectId) external returns(bool);

function getDealersItemsValueByIndex(address _dealerAddr, address _nftContract, uint256 index) external view returns (uint256);

function getDealersItemsLength(address _dealerAddr, address _nftContract) external view returns (uint256);

function getDealersIdList(address _dealerAddr, address _nftContract) external view returns (uint256[] memory);

function getDealerByTokenId(uint256 _selectId) external returns(address _dealer, address _nftContract); 

function getTokenUri(address _nftContract, uint256 _tokenId) external view returns (string memory uri);


// ивенты: 
    // event someEvent(
    //     address indexed stakeholder,
    //     uint256 amount,
    //     uint256 timestamp
    // );

    // event someEvent1(
    //     address indexed stakeholder,
    //     uint256 amount,
    //     uint256 timestamp
    // );

    // event someEvent2(
    //     address indexed stakeholder,
    //     uint256 amount,
    //     uint256 timestamp
    // );

}