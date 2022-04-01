// SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.22 <0.9.0;

import "./INftMarketplace.sol"; //
// import "./ERC721NFTBase.sol"; //  ...
// import "./ERC20token.sol"; //  ...
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
// import "./NFTMarketplaceLib.sol";

abstract contract NftMarketplace is ERC721, ERC721URIStorage, INftMarketplace, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint128;
    using SafeERC20 for IERC20;
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address[] public nftContract = new address[](0);
    address[] public erc20Contract = new address[](0);
    address[] private dealers = new address[](0); // барыги
    address[] bidders = new address[](0); // массив размерность 0 что бы потом методом push растягивать его новыми bidders 
    uint256[] bidPrice = new uint256[](0); // 

    string _uri; // создай маппинг для uri и возьми реализацию setTokenUri из старого проекта ERC1155
    uint256 public auctionPeriod; // можно 3 days, (259200 in sec)
    mapping(address => mapping(address => uint256[])) internal dealersItems; // dealer=>nftContract=>arrayTokenId
    mapping(uint256 => Dealers) internal dealerTokenId;  
    mapping(uint256 => Deal) private _dealerInDeal; // id 
    mapping(address => mapping(uint256 => bool)) public _dealerInDealStatus;// адрессдилера=> айди токена => статус в продаже 
    mapping(uint256 => Auction) private _dealerInAuction; 
    mapping(address => mapping(uint256 => bool)) public _dealerInAuctionStatus; //
    mapping(address => mapping(uint256 => uint256)) private _bidPrice; // адрес того кто сделал ставку => tokenid => сумма ставки 
    constructor(
        uint256 _auctionPeriod // address _nftContract, // address _erc20Contract,
    )
        {
        auctionPeriod = _auctionPeriod;
        // nftContract = ERC721NFTBase(_nftContract); // только под 1 nft конракт
        // erc20Contract = ERC20token(_erc20Contract); // только для 1 erc20 контракта 
    }
    
    struct Dealers { 
    address dealerAddress;   
    address nftContract;
    }

    struct Deal {
        address dealer;
        uint256 id;
        uint256 price;
        bool salesStatus;
        address erc20Conract;
    }

    struct Auction {
        uint256 startTime;
        uint256 minPrice;
        uint256[] currentBidPrice;
        uint256 countBid;
        address[] lastBidder;
        address auctioner;
        bool actionStatus;
        bool salesStatus;
        uint256 tokenId;
        address erc20Conract;
    }
    // обязат overriden functions from ERC721, ERC721URIStorage
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    //-------------------------------------------------------



    modifier onlyDealer(address _dealer) {
        bool _isdealer = isDealer(_dealer);
        require(_isdealer, "this address is not the dealer");
        require(_dealer == msg.sender, "your not the dealer");
        _;
    }

    modifier chekDealer(address _dealer) {
        bool _isdealer = isDealer(_dealer);
        require(_isdealer, "this address is not the dealer");
        _;
    }

    modifier checkNftContract(address _nftContract) {
        bool _isNftContract = isNftContract(_nftContract);
        require(_isNftContract, "this address is not the NftContract");
        _;
    }

    modifier checkERC20Contract(address _erc20Contract) {
        bool _isErc20Contract = isERC20Contract(_erc20Contract);
        require(_isErc20Contract, "this address is not the ERC20Contract");
        _;
    }

     modifier checkAucPeriod(uint256 _selectId) {
        uint256 startTime = _dealerInAuction[_selectId].startTime;
         require(_dealerInAuction[_selectId].actionStatus == true, "actionStatus not true");
        require(_dealerInAuction[_selectId].salesStatus == false, "salesStatus not false");
        require(
            block.timestamp < startTime + auctionPeriod,
            "auction time out"
        );
        _;
    }

    modifier AucTimeIsOut(uint256 _selectId) {
        uint256 startTime = _dealerInAuction[_selectId].startTime;
        require(_dealerInAuction[_selectId].actionStatus == true, "actionStatus not false");
        require(_dealerInAuction[_selectId].salesStatus == false, "salesStatus not false");
        require(block.timestamp > startTime + auctionPeriod, "auction time has not yet expired");
        _;
    }

    // Ивенты : 

   // SERVICE FUNC'S START---------------------------------------------------------------
    function addDealer(
        // сперва owner добавляет контракт(ы) в список, и потом они могут чеканить токены
        address _dealer
    ) external override onlyOwner {
        bool _isDealers = isDealer(_dealer);
        if (!_isDealers) dealers.push(_dealer);
    }

     function deleteDealers(
        // сперва owner добавляет контракт(ы) в список, и потом они могут чеканить токены
        address _dealer, 
        uint256 _selectId
    ) external  override onlyOwner {

        bool _isDealers = isDealer(_dealer);
        require(_isDealers, "no such dealer");

        if (_dealer == _dealerInDeal[_selectId].dealer) {
        cancel( _selectId); // отмена подажи
        dealers.pop();
        } 
        else if (_dealer == _dealerInAuction[_selectId].auctioner) {
        cancelAuction(_selectId); // отмена аукциона 
        dealers.pop();
        } else {console.log("this Dealer does not have such position: ", _selectId);
        }
    }

    function addNftContract(
        // сперва owner добавляет контракт(ы) в список, и потом они могут чеканить токены
        address _nftContract
    ) external override onlyOwner {
        bool _isNftContract = isNftContract(_nftContract);
        if (!_isNftContract) nftContract.push(_nftContract);
    }

    function addERC20Contract(
        // сперва owner добавляет контракт(ы) в список, и потом они могут чеканить токены
        address _erc20Contract
    ) external override onlyOwner {
        bool _isErc20Contract = isERC20Contract(_erc20Contract);
        if (!_isErc20Contract) erc20Contract.push(_erc20Contract);
    }

    function deleteNftContract(
        // сперва owner добавляет контракт(ы) в список, и потом они могут чеканить токены
        address _nftContract
    ) external override onlyOwner {
        bool _isNftContract = isNftContract(_nftContract);
        if (_isNftContract) nftContract.pop();
    }

    function deleteERC20Contract(
        // сперва owner добавляет контракт(ы) в список, и потом они могут чеканить токены
        address _erc20Contract
    ) external override onlyOwner {
        bool _isErc20Contract = isERC20Contract(_erc20Contract);
        if (_isErc20Contract) erc20Contract.pop();
    }

    function isDealer(address _address) public view override returns (bool) {
        for (uint256 s = 0; s < dealers.length; s++) {
            if (_address == dealers[s]) return (true);
        }
        return (false);
    }

    function isNftContract(address _nftContract) public view override returns (bool) {
        for (uint256 s = 0; s < nftContract.length; s++) {
            if (_nftContract == nftContract[s]) return (true);
        }
        return (false);
    }

    function isERC20Contract(address _address) public view override returns (bool) {
        for (uint256 s = 0; s < erc20Contract.length; s++) {
            if (_address == erc20Contract[s]) return (true);
        }
        return (false);
    }

    function changeAucTime(uint32 _time) external override onlyOwner {
        require(_time < 864000, "auction time more than 10 days");
        auctionPeriod = _time; // барыга или owner может выставлять время аукциона но не более 10 дней
    } 

    function getDealersItemsLength(
        address _dealerAddr,
        address _nftContract
    )
        public
        view
        override
        chekDealer(_dealerAddr)
        checkNftContract(_nftContract)
        returns (uint256)
    {
        return dealersItems[_dealerAddr][_nftContract].length; // вернет длинну массива
    }

    function getDealersItemsValueByIndex(
        // tokenId по индексу
        address _dealerAddr,
        address _nftContract,
        uint256 index
    )
        public
        view
        override
        chekDealer(_dealerAddr)
        checkNftContract(_nftContract)
        returns (uint256)
    {
        return dealersItems[_dealerAddr][_nftContract][index];
    }

    function getDealerIdTokenExist(address _dealer, address _nftContract, uint256 _selectId) public view override returns(bool) 
    {
        for (
            uint256 i = 0;
            i < dealersItems[_dealer][_nftContract].length;) 
            {
            if (_selectId == dealersItems[_dealer][_nftContract][i]) {
                return true; 
            } i++;
        }
        console.log("this contract does not have such IDs: ", _selectId);
        return false;
    }

    function getDealersIdList(
        address _dealerAddr,
        address _nftContract // весь список id(ов)
    )
        public
        view
        override
        chekDealer(_dealerAddr)
        checkNftContract(_nftContract)
        returns (uint256[] memory)
    {
        return dealersItems[_dealerAddr][_nftContract];
    }
    
    function getDealerByTokenId(uint256 _selectId) 
    public 
    view
    override
    returns(
        address _dealer,  
        address _nftContract
        ) {
    
    _dealer = dealerTokenId[_selectId].dealerAddress;
    _nftContract = dealerTokenId[_selectId].nftContract;
    require(_dealer != address(0), "dealer address under this id does not exist");
    require(_nftContract != address(0), "nftContract address under this id does not exist");
    return (_dealer, _nftContract); 
    }

    function getTokenUri(
        // вернут uri по _tokenId (_tokenId привязан к _tokenIdCounter)
        address _nftContract,
        uint256 _tokenId
    )
        external
        view
        override
        checkNftContract(_nftContract)
        returns (string memory uri)
    {
        (uri) = ERC721URIStorage(_nftContract).tokenURI(_tokenId);
        return _uri;
    }

    // SERVICE FUNC'S END----------------------------------------------------------------

// создать токен 
    function createItem(
        address _nftContract, // должен реализовывать safeMint как ERC721NFTBase (иначе false)
        address _to,
        string memory uri
    )
        public
        override
        onlyDealer(msg.sender)
        checkNftContract(_nftContract)
        returns (uint256 _tokenId)
    {
        _uri = uri;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        ERC721(_nftContract)._safeMint(_to, tokenId);
        // (_tokenId) = ERC721NFTBase(_nftContract).safeMint(_to, _uri); // привязка к одному контракту ERC721NFTBase
        ERC721URIStorage(_nftContract)._setTokenURI(tokenId, _uri); // сохранить uri под tokenId
        dealersItems[msg.sender][_nftContract].push(tokenId);
        dealerTokenId[tokenId] = Dealers(
        { dealerAddress: msg.sender, nftContract: _nftContract
        });
        return _tokenId;
    }

    // РАЗМЕЩЕНИЕ КОЛЛЕКЦИИ:
    function listItems(
        uint256 _selectId,
        uint256 _price, 
        address _erc20Contract
    )   
        external
        override
        chekDealer(msg.sender)
        returns (bool)
    {
        // выставка на продажу предмета
        require(_dealerInAuction[_selectId].actionStatus == false, "this token is already up for auction"); // проверка стои ли на уакционе
        // ЗДЕЛАЙ ЕЩЕ ОДНУ ПРОВЕРКУ ЧТО ОДНОВРЕМЕННО НЕЛЬЗЯ ПОСТАВИТЬ И НА ПРОДАЖУ И НА АУКЦИОН ТОКЕН
        (, address _nftContract) = getDealerByTokenId(_selectId);
        // (address _erc20Contract)  = getErc20Contract(_selectId);
        erc20Contract.push(_erc20Contract);
        for (
            uint256 i = 0;
            i < dealersItems[msg.sender][_nftContract].length;

        ) {
            if (_selectId == dealersItems[msg.sender][_nftContract][i]) {
                ERC721(_nftContract).transferFrom(
                    _nftContract,
                    address(this),
                    _selectId
                );
                _dealerInDeal[_selectId] = Deal({
                    dealer: msg.sender,
                    id: _selectId,
                    price: _price,
                    salesStatus: true,
                    erc20Conract: _erc20Contract
                });
                _dealerInDealStatus[msg.sender][_selectId] == true;
                return true;
            }
            i++;
        }
        console.log("this contract does not have such IDs: ", _selectId);
        return false;
    }

    // КУПИТЬ ПО ID
    function buyItem(
        uint256 _selectId
    )
        public
        override
        returns (bool)
    {
        address _erc20Contract;
        _erc20Contract = _dealerInDeal[_selectId].erc20Conract;
        (address _dealer, address _nftContract) = getDealerByTokenId(_selectId);
        uint256 _price;
        for (
            uint256 i = 0;
            i < dealersItems[_dealer][_nftContract].length;

        ) {
            if (_selectId == dealersItems[_dealer][_nftContract][i]) {
                require(
                    _dealerInDeal[_selectId].salesStatus == true,
                    "saleStatus - the item exist but it's sold"
                );
                _price = _dealerInDeal[_selectId].price;
                IERC20(_erc20Contract).safeTransferFrom(
                    msg.sender,
                    _dealerInDeal[_selectId].dealer,
                    _price
                );
                _dealerInDealStatus[_dealer][_selectId] == false;
                return true;
            }
            i++;
        }
        console.log("this contract does not have such IDs: ", _selectId);
        return false;
    }

    // отмена продажи выставленного предмета
    function cancel(uint256 _selectId)
        public
        override
        onlyDealer(msg.sender)
        returns (bool)
    {
        (, address _nftContract) = getDealerByTokenId(_selectId);
        for (
            uint256 i = 0;
            i < dealersItems[msg.sender][_nftContract].length;

        ) {
            if (_selectId == dealersItems[msg.sender][_nftContract][i]) {
                require(_dealerInDeal[_selectId].salesStatus == true, "salesStatus not true");
                require(_dealerInDealStatus[msg.sender][_selectId] == true, "the item exist but it's sold");
                ERC721(_nftContract).transferFrom(
                    address(this),
                    _nftContract,
                    _selectId
                );
                _dealerInDeal[_selectId].salesStatus = false;
              _dealerInDealStatus[msg.sender][_selectId] == false;
                _dealerInDeal[_selectId].price = 0;
                return true;
            }
        }
        console.log("this contract does not have such IDs: ", _selectId);
        return false;
    }

    // выставка предмета на продажу в аукционе.
    function listItemOnAuction(
        uint256 _selectId,
        uint256 _minPrice,
        address _erc20Contract
    )
        public
        override
        onlyDealer(msg.sender)
        returns (bool)
    {
        require(_dealerInDeal[_selectId].salesStatus == false, "this token is already up for sale"); // 
        (, address _nftContract) = getDealerByTokenId(_selectId); 
        bidders[0] = address(0); // первый 0 адрес для иницализации 
        bidPrice.push(0); // первая cтавка также равно 0
        for (
            uint256 i = 0;
            i < dealersItems[msg.sender][_nftContract].length;

        ) {
            if (_selectId == dealersItems[msg.sender][_nftContract][i]) {
                require(_dealerInAuction[_selectId].actionStatus != true, "actionStatus not true");
                require(_dealerInAuction[_selectId].salesStatus != true, "salesStatus not false");
                ERC721(_nftContract).transferFrom(
                    _nftContract,
                    address(this),
                    _selectId
                );
                _dealerInAuction[_selectId] = Auction({
                    startTime: block.timestamp,
                    minPrice: _minPrice,
                    currentBidPrice: bidPrice, // массив 
                    countBid: 0,
                    lastBidder: bidders, // нулевой адрес если не передаем какие то значения 
                    auctioner: msg.sender,
                    actionStatus: true,
                    salesStatus: false, 
                    tokenId: _selectId,
                    erc20Conract: _erc20Contract
                });
                _dealerInDealStatus[msg.sender][_selectId] == true;
                return true;
            } 
            i++;
        }
        console.log("this contract does not have such IDs: ", _selectId);
        return false;
    }

    // отменить аукцион
    function cancelAuction(uint256 _selectId) 
        public
        override
        onlyDealer(msg.sender)
        returns (bool _ok)
    {
        require(_dealerInAuction[_selectId].tokenId == _selectId, "wrong ID");
        (, address _nftContract) = getDealerByTokenId(_selectId);
        for (
            uint256 i = 0;
            i < dealersItems[msg.sender][_nftContract].length;

        ) {
            if (_selectId == dealersItems[msg.sender][_nftContract][i]) {
                require(_dealerInAuction[_selectId].actionStatus == true, "actionStatus not true");
                require(_dealerInAuction[_selectId].salesStatus == false, "salesStatus not false");

                _dealerInAuction[_selectId].actionStatus = false;
                _dealerInDealStatus[msg.sender][_selectId] == false; //  
                _ok = true;
                return _ok;
            } else {
        console.log("this contract does not have such IDs: ", _selectId);
         i++;
            } 
       }
    }

    function cancelBid(uint256 _selectId) AucTimeIsOut(_selectId) public override {
    uint256 bid;
    address bidderAddress;
    address _erc20Contract;
    _erc20Contract  = _dealerInAuction[_selectId].erc20Conract;
    require(_dealerInAuction[_selectId].actionStatus == false, "actionStatus not true"); 
    require(_dealerInAuction[_selectId].salesStatus == true, "salesStatus not false");

    
    for(uint256 i = 0; i < _dealerInAuction[_selectId].lastBidder.length;) 
    {  
        if(_dealerInAuction[_selectId].lastBidder[i] == msg.sender){
        bidderAddress = _dealerInAuction[_selectId].lastBidder[i];
        bid = _dealerInAuction[_selectId].currentBidPrice[i];
     } else { i++; }
        
    } 
    require(bidderAddress != address(0), "not such bidder");
    require(bid != 0, "not such bidder");
    
    IERC20(_erc20Contract).safeTransfer(
                msg.sender,
                bid
        );

    }
 
    // сделать ставку на предмет аукциона с определенным id.
    function makeBid(
        uint256 _selectId, 
        uint256 _bidprice
    )
        public
        override
        checkAucPeriod(_selectId)
        returns (bool)
    {
        address _erc20Contract;
        _erc20Contract  = _dealerInAuction[_selectId].erc20Conract;
                require(_dealerInAuction[_selectId].tokenId == _selectId, "wrong ID");
                require(_dealerInAuction[_selectId].actionStatus == true, "actionStatus not true");
                require(_dealerInAuction[_selectId].salesStatus == false, "salesStatus not false");

            if (_dealerInAuction[_selectId].lastBidder[1] == address(0)) {
                require(_bidprice > _dealerInAuction[_selectId].minPrice, "the price is below the set minimum bid price");
                    IERC20(_erc20Contract).safeTransfer(   
                    address(this),
                    _bidprice   
                );
                _dealerInAuction[_selectId].countBid += 1;
                 
                _dealerInAuction[_selectId].lastBidder.push(msg.sender);
                _dealerInAuction[_selectId].currentBidPrice.push(_bidprice); 
                
                return true;
                } else if (_dealerInAuction[_selectId].lastBidder[1] != address(0)) {
                IERC20(_erc20Contract).safeTransfer(
                    address(this),
                    _bidprice
                );
                _dealerInAuction[_selectId].countBid += 1;
                _dealerInAuction[_selectId].lastBidder.push(msg.sender);
                _dealerInAuction[_selectId].currentBidPrice.push(_bidprice);
                return true;
                } else {
        console.log("this contract does not have such IDs: ", _selectId);
        return false;
                }
    }

    // завершить аукцион и отправить НФТ победителю
    function finishAuction(
        uint256 _selectId
    )   
        public
        override
        AucTimeIsOut(_selectId)
        onlyDealer(msg.sender)
        returns (address _winner, uint256 maxBid)
        {
                address _erc20Contract;
                _erc20Contract  = _dealerInAuction[_selectId].erc20Conract;
                (, address _nftContract) = getDealerByTokenId(_selectId);
                require(_dealerInAuction[_selectId].tokenId == _selectId, "wrong ID");
                require(_dealerInAuction[_selectId].actionStatus == true, "actionStatus not false");
                require(_dealerInAuction[_selectId].salesStatus == false, "salesStatus not false");
            
            // поиск победителя 
            maxBid = 0;
            _winner;
            //require(dealerInAuction[_selectId].currentBidPrice != 0, "alas, there were no bidds, this shit is not interesting to anyone"); // проверка на то что ставки есть как таковые  
            require(_dealerInAuction[_selectId].countBid == _dealerInAuction[_selectId].currentBidPrice.length, "countBid does not match the number of bets"); 
            require(_dealerInAuction[_selectId].countBid == _dealerInAuction[_selectId].lastBidder.length, "countBid does not match the number of participant"); 
             
            if (_dealerInAuction[_selectId].currentBidPrice.length == 0) { // ставок не было currentBidPrice == 0
        
            ERC721(_nftContract).transferFrom( // возвращаем токен аукционеру 
                    address(this),
                    msg.sender,
                    _selectId
            );
            _dealerInAuction[_selectId].actionStatus == false; 
            _dealerInAuction[_selectId].salesStatus == true; 
            
            } else if (_dealerInAuction[_selectId].currentBidPrice.length != 0) { // если ставки есть находим победителя, ....

            for(uint256 i = 0; i < _dealerInAuction[_selectId].currentBidPrice.length;) {
            // простая логика поиска победителя 
            if (_dealerInAuction[_selectId].currentBidPrice[i] 
            > maxBid && _dealerInAuction[_selectId].currentBidPrice[i] 
            > _dealerInAuction[_selectId].minPrice) {
               maxBid = _dealerInAuction[_selectId].currentBidPrice[i];
               _winner = _dealerInAuction[_selectId].lastBidder[i];
               i++;               
            } else {i++;}
            // победителю аукциона переводим nft 
            require(_winner != address(0), "winner address empty");
            ERC721(_nftContract).transferFrom(
                    address(this),
                    _winner,
                    _selectId
            );
                // аукцонер получае свои за продажу Nft
            require(maxBid != 0, "winner address empty");
            IERC20(_erc20Contract).safeTransferFrom(
                    address(this),   
                    msg.sender,
                    maxBid    
                ); 
            _dealerInAuction[_selectId].actionStatus == false;
            _dealerInAuction[_selectId].salesStatus == true;  
            _dealerInDeal[_selectId].dealer == address(0);
            }
          }
        }
}
