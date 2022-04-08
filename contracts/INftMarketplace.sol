// SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.22 <0.9.0;

interface INftMarketplace {

function createItem(address _nftContract, uint256 _selectId, string memory _uri) external returns (uint256 _tokenId);

function listItemOnSale(uint256 _selectId, address _nftContract, uint256 _price, address _erc20Contract) external returns (bool);

function buyItem(uint _selectId) external returns (bool);

function cancel(uint256 _selectId, address _nftContract) external returns (bool);

function listItemOnAuction(uint256 _selectId,  address _nftContract, uint256 _minPrice, address _erc20Contract) external returns (bool);

function cancelAuction(uint256 _selectId) external returns (bool);

function cancelBid(uint256 _selectId) external;

function makeBid(uint256 _selectId, uint256 _bidPrice) external returns (bool);

function finishAuction(uint256 _selectId) external returns (address _winner, uint256 maxBid);

// сервисные функции: 

function addDealer(address _dealer) external;

function removeDealerItem(address _dealer, address _nftContract, uint256 _selectId) external;

// function removeAllItems(address _dealer, address _nftContract) external returns(bool);

function deleteDealerTradePosition(address _dealer, uint _selectId, address _nftContract) external;

function deleteDealerAuctionPosition(uint _selectId) external;

// function cancelDealerItemsPositions(address _dealer, address[] memory _nftContract, uint256[] memory _selectId) external;

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

// function getDealerAndNFTContrByTokenId(uint256 _selectId) external returns(address _dealer, address _nftContract); 

function getTokenURI(address _nftContract, uint256 _tokenId) external view returns (string memory uri);

// ивенты: 

event createItemEvent(
    address indexed _dealer,
    address indexed _nftContract, 
    uint _selectId, 
    string _uri
    ); 
// emit createItemEvent(msg.sender, _nftContract, _selectId, _uri);    
event buyItemEvent(
    address indexed _dealer,
    address indexed _nftContract,
    address indexed _erc20Contract,
    uint _selectId
    );      
// emit buyItemEvent(_dealer, _nftContract, _erc20Contract, _selectId);    
event listItemOnSaleEvent(
    address indexed _dealer,
    uint _selectId, 
    address indexed _nftContract, 
    uint _price, 
    address indexed _erc20Contract
    );
// emit listItemOnSaleEvent(msg.sender, _selectId, _nftContract, _price, _erc20Contract);    
event cancelEvent(
    address indexed _dealer,
    uint _selectId, 
    address indexed _nftContract
    );
// emit cancelEvent(_dealer, _selectId, _nftContract);    
event listItemOnAuctionEvent(
    address indexed _dealer,
    uint _selectId, 
    address indexed _nftContract, 
    uint _minPrice,
    address indexed _erc20Contract
    );
// emit listItemOnAuctionEvent(msg.sender, _selectId, _nftContract, _minPrice, _erc20Contract);    
event cancelAuctionEvent(
    address indexed _dealer,
    uint _selectId, 
    address indexed _nftContract
    );
// emit cancelAuctionEvent(msg.sender, _selectId, _nftContract);   
event cancelBidEvent(
    address indexed _bidder, 
    uint _selectId,
    uint _bid,
    address _erc20Contract
    );
// emit cancelBidEvent(msg.sender, _selectId, bid, _erc20Contract);    
event makeBidEvent(
    address indexed _bidder,
    uint _selectId, 
    uint _bidPrice
    );
// emit makeBidEvent(msg.sender, _bidPrice, _selectId); 
event finishAuctionEvent(
    address indexed _dealer,
    address indexed _nftContract,
    uint _selectId
    );
// emit finishAuctionEvent(msg.sender, _nftContract, _selectId);    

event addDealerEvent(
    address _dealer
    );
// emit addDealerEvent(_dealer);

event removeDealerItemEvent(
    address indexed _dealer, 
    address indexed _nftContract, 
    uint256 _selectId
    );
// emit removeDealerItemEvent(_dealer, _nftContract, _selectId);

event deleteDealerTradePositionEvent(
    address indexed _dealer, 
    uint _selectId, 
    address indexed _nftContract
    );
// emit deleteDealerTradePositionEvent(_dealer, _selectId, _nftContract);

event deleteDealerAuctionPositionEvent(
    uint _selectId
    );
// emit deleteDealerAuctionPositionEvent(_selectId);

event addNftContractEvent(
    address indexed _nftContract
    );
// emit addNftContractEvent(_nftContract);

event addERC20ContractEvent(
    address indexed _erc20Contract
    );
// emit addERC20ContractEvent(_erc20Contract);

event deleteNftContractEvent(
    address indexed _nftContract
    );
// emit deleteNftContractEvent(_nftContract);

event deleteERC20ContractEvent(
    address indexed _erc20Contract
    );
// emit deleteERC20ContractEvent(_erc20Contract)

event changeAucTimeEvent(
    uint32 _newTime);
// emit changeAucTimeEvent(_newTime);    
}