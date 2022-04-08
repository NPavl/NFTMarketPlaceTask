// SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.22 <0.9.0;

// Порядок взаимодейтвия с контрактом: 

// 1 в контруктор передать период аукцона (для быстрых тестов досточно 60) 
//   время аукцона можно изменить методом changeAucTime()
// 2 добавить в массив адрес(а) делира(ов) метод addDealer() 
// 3 добавить nft контракт(ы) для минта addNftContract() 
// 4 добавить erc20Contract(ы) для оплаты addERC20Contract()
// 5 создать токены методом createItem() данные будут записаны в мап dealersItems
//------------ 
// Пометки: 
// 1 контракт много весит при деплое в ремикс включи опимизацию (enable optimization)
// 2 вынеси все сервисные и прочие вспомогательные функции в библиотеку. 
// 3 сделай оптимизацию по переменным, ... .   
// 4 Изначально делал под 1 Erc20Contract и 1 NftContract, но в последствии захотел доабавлять 
//   разные конракты для маркетплейса. чтобы добавлять разные NftContract(ы) они должны реализовывать 
//   ERC721, ERC721URIStorage, возожность исп ERC1155 отсутствует, и также неуспел добавить кастомный Uri
//   для хранания масива uri пример метода здесь:  
//   https://github.com/NPavl/ERC721_1155_withOpensea/blob/52b8f3a33f9b2a6da5a7e262925fb49e856ce986/contracts/ERC1155GameItems.sol#L68
// 5 для тестов можно использовать эти старые контракты: ERC721 0x09750f9782D2B56fA800d3e539A1cA3Bd22FC74d
//   ERC721NFTBase2:   
//	 ERC20token (BLR): 0xcd61492203af21301DCc53b4F042998DF65d128E
//	                   https://rinkeby.etherscan.io/address/0xcd61492203af21301DCc53b4F042998DF65d128E#code
  
import "./INftMarketplace.sol";
// import "./NFTMarketplaceLib.sol";
// import "./ERC721NFTBase.sol"; //  
// import "./ERC20token.sol"; //
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract NftMarketplace is INftMarketplace, Ownable {

    using SafeMath for uint256;
    using SafeMath for uint32; 
    using SafeERC20 for IERC20;
    
    // using Counters for Counters.Counter;
    // Counters.Counter private _tokenIdCounter;

    address[] private nftContract = new address[](0);
    address[] private erc20Contract = new address[](0);
    address[] private dealers = new address[](0); // барыги
    address[] private bidders = new address[](0); // массив размерность 0 что бы потом методом push растягивать его новыми данными 
	                                      // минус только при использовании метода pop в deleteDealers,.. так как pop удалит
										  // последний элимент массива продумай этот момент измени реализацию deleteDealers, 
										  // и др методы которые исп. функц pop, напиши в Lib отдельный метод с удалением по инд  
    uint[] private bidPrice = new uint[](0); 
    uint[] private arr = new uint[](0); 
    address[] private arrDealer = new address[](0);

    string _uri; // создай маппинг для uri и возьми реализацию setTokenUri из старого проекта ERC1155
    uint private auctionPeriod; // можно 3 days, (259200 in sec)
    mapping(address => mapping(address => uint[])) private dealersItems; // dealer=> его nftContract => arrayTokenId  
    mapping(address => mapping(address => uint[])) private contractBalance; // marketplace => _nftContract => массивid 
    mapping(uint => Deal) private _dealerInDeal; // idтокена => nftContract => структура сделки на продажу
    mapping(address => mapping(address => mapping(uint => bool))) internal _dealerInDealStatus;// адрессдилера=> аддреnftскотракта => айди токена => статус в продаже 
    // mapping (address => mapping(address => mapping(uint => uint))) internal allowances;
    mapping(uint => Auction) private _dealerInAuction; // idтокена => структура сделки на аукцион
    mapping(address => mapping(uint => uint)) private _bidPrice; // адрес того кто сделал ставку => tokenid => сумма ставки 
    constructor(
        uint _auctionPeriod // address _nftContract, // address _erc20Contract,
    )
        {
        auctionPeriod = _auctionPeriod;
        // nftContract = ERC721NFTBase(_nftContract); // под 1 nft конракт
        // erc20Contract = ERC20token(_erc20Contract); // под 1 erc20 контракт 
    }

    struct Deal {
        address dealer;
        uint id;
        uint price;
        bool salesStatus;
        address erc20Conract;
        address nftContract;
    }

    struct Auction {
        uint startTime;
        uint minPrice;
        uint[] currentBidPrice;
        uint countBid;
        address[] lastBidder;
        address auctioner;
        bool actionStatus;
        bool salesStatus;
        uint tokenId;
        address erc20Conract;
        address nftContract;
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
     modifier checkAucPeriod(uint _selectId) {
        uint256 startTime = _dealerInAuction[_selectId].startTime;
        require(_dealerInAuction[_selectId].actionStatus == true, "actionStatus not true");
        require(_dealerInAuction[_selectId].salesStatus == false, "salesStatus not false");
        require(
            block.timestamp < startTime + auctionPeriod,
            "auction time out"
        );
        _;
    }
    modifier AucTimeIsOut(uint _selectId) {
        uint256 startTime = _dealerInAuction[_selectId].startTime;
        require(_dealerInAuction[_selectId].actionStatus == true, "actionStatus not false");
        require(_dealerInAuction[_selectId].salesStatus == false, "salesStatus not false");
        require(block.timestamp > startTime + auctionPeriod, "auction time has not yet expired");
        _;
    }
	
   // SERVICE FUNC'S START---------------------------------------------------------------
    function addDealer(address _dealer) external override onlyOwner {
      require(_dealer != address(0), "wrong address"); 
      dealers.push(_dealer);
      emit addDealerEvent(_dealer);
    }

function deleteDealerArrayByIndex(address _dealer, uint index) external chekDealer(_dealer) onlyOwner {
    require(dealers.length > 0, "can't remove from empty array");
        arrDealer = dealers;
        arrDealer[index] = arrDealer[arrDealer.length - 1];
        arrDealer.pop();
        dealers = arrDealer;
}

function removeDealerItem(address _dealer, address _nftContract, uint _selectId) 
    external override chekDealer(_dealer) checkNftContract(_nftContract) onlyOwner {
        require(dealersItems[_dealer][_nftContract].length > 0, "empty array");   
          for (
            uint i = 0;
            i < dealersItems[_dealer][_nftContract].length;) 
            {
            if (_selectId == dealersItems[_dealer][_nftContract][i]) {
                delete dealersItems[_dealer][_nftContract][i];
            } i++;
        }
        emit removeDealerItemEvent(_dealer, _nftContract, _selectId);
        // здесь обнули позиции по продажам и аукциону, и отправь назад все токены которые есть у дилера ему 
        // обратно на кошель, или сделай вспомогат функцию 
    }

function deleteDealerTradePosition(address _dealer, uint _selectId, address _nftContract) external override onlyOwner {
        require(_dealerInDealStatus[_dealer][_nftContract][_selectId] == true, "this ID is not for sale or auction");
        _dealerInDealStatus[_dealer][_nftContract][_selectId] == false;
        delete _dealerInDeal[_selectId]; // удаление всех торговых позиций     
        emit deleteDealerTradePositionEvent(_dealer, _selectId, _nftContract);

} 
function deleteDealerAuctionPosition(uint _selectId) external override onlyOwner {
        require(_dealerInAuction[_selectId].actionStatus == true, "actionStatus not true");
        require(_dealerInAuction[_selectId].salesStatus == true, "salesStatus not true, probably the item is already sold");
        delete _dealerInAuction[_selectId]; // удаление всех аукционных позиций     
        emit deleteDealerAuctionPositionEvent(_selectId);
} 
    
    function addNftContract(
        address _nftContract
    ) external override onlyOwner {
        bool _isNftContract = isNftContract(_nftContract);
        if (!_isNftContract) nftContract.push(_nftContract);
        emit addNftContractEvent(_nftContract);
    }

    function addERC20Contract(
        address _erc20Contract
    ) external override onlyOwner {
        bool _isErc20Contract = isERC20Contract(_erc20Contract);
        if (!_isErc20Contract) erc20Contract.push(_erc20Contract);
        emit addERC20ContractEvent(_erc20Contract);
    }

    function deleteNftContract(
        address _nftContract
    ) external override onlyOwner {
        bool _isNftContract = isNftContract(_nftContract);
        require(_isNftContract, "not exist");
        for (uint i = 0; i < nftContract.length; i++) {
        if (_nftContract == nftContract[i])
            delete nftContract[i]; 
        }
        emit deleteNftContractEvent(_nftContract);
    }

    function deleteERC20Contract(address _erc20Contract) external override onlyOwner {
        bool _isErc20Contract = isERC20Contract(_erc20Contract);
         require(_isErc20Contract, "not exist");
        for (uint i = 0; i < nftContract.length; i++) {
        if (_erc20Contract == erc20Contract[i])
            delete erc20Contract[i]; 
       }
       emit deleteERC20ContractEvent(_erc20Contract);
    }

    function isDealer(address _address) public view override returns (bool) {
        for (uint s = 0; s < dealers.length; s++) {
            if (_address == dealers[s]) return (true);
        }
        return (false);
    }

    function isNftContract(address _nftContract) public view override returns (bool) {
        for (uint s = 0; s < nftContract.length; s++) {
            if (_nftContract == nftContract[s]) return (true);
        }
        return (false);
    }

    function isERC20Contract(address _address) public view override returns (bool) {
        for (uint s = 0; s < erc20Contract.length; s++) {
            if (_address == erc20Contract[s]) return (true);
        }
        return (false);
    }

    function changeAucTime(uint32 _newTime) external override onlyOwner {
        require(_newTime < 864000, "auction time more than 10 days");
        auctionPeriod = _newTime; // барыга или owner может выставлять время аукциона но не более 10 дней
        emit changeAucTimeEvent(_newTime);  
    } 

    function getDealersItemsLength(
        address _dealer,
        address _nftContract
    )
        public
        view
        override
        chekDealer(_dealer)
        checkNftContract(_nftContract)
        returns (uint)
    {
        return dealersItems[_dealer][_nftContract].length; // вернет длинну массива
    }

    function getDealersItemsValueByIndex(
        // tokenId по индексу
        address _dealer,
        address _nftContract,
        uint index
    )
        public
        view
        override
        chekDealer(_dealer)
        checkNftContract(_nftContract)
        returns (uint)
    {
        return dealersItems[_dealer][_nftContract][index];
    }

    function getDealerIdTokenExist(address _dealer, address _nftContract, uint _selectId) public view override returns(bool) 
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
        address _dealer,
        address _nftContract // весь список id(ов) дилера 
    )
        public
        view
        override
        chekDealer(_dealer)
        checkNftContract(_nftContract)
        returns (uint256[] memory)
    {
        return dealersItems[_dealer][_nftContract]; // возвращает кол-во Id токенов по индексам 
    }

    function getTokenURI(  
        // вернут uri по _tokenId (_tokenId привязан к _tokenIdCounter)
        address _nftContract,
        uint _selectId
    )   
        external
        view
        override 
        checkNftContract(_nftContract)
        returns (string memory uri)
    {
        (uri) = ERC721URIStorage(_nftContract).tokenURI(_selectId);
        return uri;
    }

    // SERVICE FUNC'S END----------------------------------------------------------------

// для создания токена подойдет любой базовый контракт наследуемый ERC721URIStorage 
// (содержит методы ERC721 так как наследует его) в ERС721 метод _safeMint необходимо изменить на external 
    function createItem(
        address _nftContract, // должен реализовывать safeMint как ERC721NFTBase (иначе false)
        uint _selectId, // перед созданием необходимо посмотреть сколько всего токенов в передаваемом контракте и передать в create след по порядку 
        string memory uri
    )   
        public
        override
        onlyDealer(msg.sender)
        checkNftContract(_nftContract)
        returns (uint)
    {
        _uri = uri;
        // uint tokenId = _tokenIdCounter.current(); //  отключил нет смыста исп если не с 0 исп nftконтракт 
        // _tokenIdCounter.increment();
        ERC721(_nftContract)._safeMint(msg.sender, _selectId); // 
        // ERC721NFTBase(_nftContract).safeMint(msg.sender, tokenId, _uri); // вызов только через 1 конкретный контракт 
        ERC721URIStorage(_nftContract)._setTokenURI(_selectId, _uri); // 
        dealersItems[msg.sender][_nftContract].push(_selectId);
        _dealerInDealStatus[msg.sender][_nftContract][_selectId] = false; 
        // dealerTokenId[_selectId] = Dealers(
        // { dealerAddress: msg.sender, nftContract: _nftContract
        // });
        emit createItemEvent(msg.sender, _nftContract, _selectId, _uri);
        return _selectId;
        }

    // РАЗМЕЩЕНИЕ КОЛЛЕКЦИИ НА ПРОДАЖУ:
    function listItemOnSale(
        uint _selectId, // id токена 
        address _nftContract,
        uint _price,  // в wei 
        address _erc20Contract // не вызывается, кладем в структуру 
    )   
        external
        override
        chekDealer(msg.sender)
        checkNftContract(_nftContract)
        returns (bool _ok)
    {
         require(_dealerInDealStatus[msg.sender][_nftContract][_selectId] == false, "this ID is already sale or auction");
        // выставка на продажу предмета
		// проверка стои ли на уакционе если стоит тогда выставить на продажу нельзя
          for (uint i = 0; i < dealersItems[msg.sender][_nftContract].length;) {
            if (_selectId == dealersItems[msg.sender][_nftContract][i]){
            erc20Contract.push(_erc20Contract);   
            ERC721(_nftContract).transferFrom(
                    msg.sender, 
                    address(this),
                    _selectId   
                );
                _dealerInDeal[_selectId] = Deal({
                    dealer: msg.sender,
                    id: _selectId,
                    price: _price,
                    salesStatus: true,
                    erc20Conract: _erc20Contract,
                    nftContract: _nftContract
                });
                _dealerInDealStatus[msg.sender][_nftContract][_selectId] == true;
                contractBalance[address(this)][_nftContract].push(_selectId);
                return true;
            } i++;
        }
        emit listItemOnSaleEvent(msg.sender, _selectId, _nftContract, _price, _erc20Contract); 
        // console.log("this contract does not have such IDs: ", _selectId);
        // return false;
    }

    // КУПИТЬ ПО ID ()
    function buyItem(
        uint _selectId
    )
        public
        override
        returns (bool _ok)
    {
        address _dealer = _dealerInDeal[_selectId].dealer;
        address _nftContract = _dealerInDeal[_selectId].nftContract;
        address _erc20Contract = _dealerInDeal[_selectId].erc20Conract;
        require(_dealerInDealStatus[_dealer][_nftContract][_selectId] == true, "this ID is not for sale or auction");
        uint _price = _dealerInDeal[_selectId].price;
        for (
            uint i = 0;
            i < dealersItems[_dealer][_nftContract].length;

        ) {
            if (_selectId == dealersItems[_dealer][_nftContract][i]) {
                require(
                    _dealerInDeal[_selectId].salesStatus == true,
                    "saleStatus - the item exist but it's sold"
                );
                IERC20(_erc20Contract).safeTransferFrom(
                    msg.sender,
                    _dealerInDeal[_selectId].dealer,
                    _price);                
                // необходима проверка - дилер получил оплату
                ERC721(_nftContract).transferFrom(
                    address(this), 
                    msg.sender, 
                    _selectId  
                );            
                for(uint j = 0; j < contractBalance[address(this)][_nftContract].length;)
                {
                    if(_selectId == contractBalance[address(this)][_nftContract][j])
                    {
                        delete contractBalance[address(this)][_nftContract][j];
                    }
                i++;
                } 
                _dealerInDealStatus[_dealer][_nftContract][_selectId] == false;
                return true;
            }  i++; 
        //     else { console.log("this contract does not have such IDs: ", _selectId);
        // return false; } 
       }
       emit buyItemEvent(_dealer, _nftContract, _erc20Contract, _selectId);
    }

    // отмена продажи выставленного предмета
    function cancel(uint _selectId, address _nftContract)
        public
        override
        onlyDealer(msg.sender) 
        checkNftContract(_nftContract)
        returns (bool _ok)
    {   
        for (
            uint i = 0;
            i < dealersItems[msg.sender][_nftContract].length;) {
            if (_selectId == dealersItems[msg.sender][_nftContract][i]) {
                require(_dealerInDealStatus[msg.sender][_nftContract][_selectId] == true, "the item exist but it's sold");
               ERC721(_nftContract).transferFrom(
                    address(this),
                    msg.sender,
                    _selectId
                );            
                _dealerInDeal[_selectId].salesStatus = false;
              _dealerInDealStatus[msg.sender][_nftContract][_selectId] == false;
                return true;
            } i++;
       }
       emit cancelEvent(msg.sender, _selectId, _nftContract);
    }

    // выставка предмета на продажу в аукционе.
    function listItemOnAuction(
        uint _selectId,
        address _nftContract,
        uint _minPrice,
        address _erc20Contract
    )
        public
        override
        onlyDealer(msg.sender)
        checkNftContract(_nftContract)
        checkERC20Contract(_erc20Contract)
        returns (bool _ok)
    {
        require(_dealerInDealStatus[msg.sender][_nftContract][_selectId] == false, "this token is already up for sale");         
        bidders[0] = address(0); // первый 0 адрес для иницализации 
        bidPrice.push(0); // первая cтавка также равно 0
        for ( uint i = 0; i < dealersItems[msg.sender][_nftContract].length;) {
            if (_selectId == dealersItems[msg.sender][_nftContract][i]) {
                require(!_dealerInAuction[_selectId].actionStatus, "actionStatus not true");
                require(!_dealerInAuction[_selectId].salesStatus, "salesStatus not false");
               ERC721(_nftContract).transferFrom(
                    msg.sender,
                    address(this),
                    _selectId
                );            
                _dealerInAuction[_selectId] = Auction({
                    startTime: block.timestamp,
                    minPrice: _minPrice,
                    currentBidPrice: bidPrice, // массив ставок (альтернатива не исп массив а сразу сравнивать с 
					                    // предыдущей ставкой и ложить в пременную ставку выше предыдущей, так проще, смотри свой draft.sol)
                    countBid: 0,
                    lastBidder: bidders, // нулевой адрес если не передаем какие то значения 
                    auctioner: msg.sender,
                    actionStatus: true,
                    salesStatus: false, 
                    tokenId: _selectId,
                    erc20Conract: _erc20Contract, 
                    nftContract: _nftContract
                });
                _dealerInDealStatus[msg.sender][_nftContract][_selectId] == true;
                return true;
            } i++;
       }
       emit listItemOnAuctionEvent(msg.sender, _selectId, _nftContract, _minPrice, _erc20Contract);
    }

    // отменить аукцион
    function cancelAuction(uint _selectId) 
        public
        override
        onlyDealer(msg.sender)
        returns (bool _ok)
    {
        address _nftContract = _dealerInAuction[_selectId].nftContract;
        require(_dealerInDealStatus[msg.sender][_nftContract][_selectId] == true, "this token is not up for sale"); 
        require(_dealerInAuction[_selectId].tokenId == _selectId, "wrong ID");
        for (
            uint i = 0;
            i < dealersItems[msg.sender][_nftContract].length;

        ) {
            if (_selectId == dealersItems[msg.sender][_nftContract][i]) {
               ERC721(_nftContract).transferFrom(
                    address(this),
                    msg.sender,
                    _selectId
                );  
                _dealerInAuction[_selectId].actionStatus = false;
                _dealerInDealStatus[msg.sender][_nftContract][_selectId] == false; //  
                return true;
            } i++;  
         }
         emit cancelAuctionEvent(msg.sender, _selectId, _nftContract);
       }
    
	// пользователь может отменить свою ставку только после окончания аукциона 
    function cancelBid(uint _selectId) AucTimeIsOut(_selectId) public override {
    uint _bid;
    address _erc20Contract  = _dealerInAuction[_selectId].erc20Conract;
    require(_dealerInAuction[_selectId].actionStatus == false, "actionStatus not true"); 
    
    for(uint i = 0; i < _dealerInAuction[_selectId].lastBidder.length;) 
    {  
        if(_dealerInAuction[_selectId].lastBidder[i] == msg.sender){
        address bidderAddress = _dealerInAuction[_selectId].lastBidder[i];
		require(bidderAddress == msg.sender, "not such bidder"); // проверяем что бидер равен сендеру
        _bid = _dealerInAuction[_selectId].currentBidPrice[i];
		_dealerInAuction[_selectId].currentBidPrice[i] = 0; // обнуляем ставку бидера в маппинге       
          require(_bid != 0, "not such bid");
          IERC20(_erc20Contract).safeTransferFrom(
          address(this),
          msg.sender,
          _bid );
         } i++;
        }
        emit cancelBidEvent(msg.sender, _selectId, _bid, _erc20Contract);
      } 
    // сделать ставку на предмет аукциона с определенным id.
    function makeBid(
        uint _selectId,
        uint _bidprice
    )
        public
        override
        checkAucPeriod(_selectId)
        returns (bool _ok)
    {
        address _erc20Contract = _dealerInAuction[_selectId].erc20Conract;
                require(_dealerInAuction[_selectId].tokenId == _selectId, "wrong ID");
                require(_dealerInAuction[_selectId].actionStatus == true, "actionStatus not true");
                require(_dealerInAuction[_selectId].salesStatus == false, "salesStatus not false");
                require(_bidprice > _dealerInAuction[_selectId].minPrice, "the price is below the set minimum bid price");
                     IERC20(_erc20Contract).safeTransfer(   
                     address(this),
                    _bidprice   
                ); 
                _dealerInAuction[_selectId].countBid += 1;
                _dealerInAuction[_selectId].lastBidder.push(msg.sender);
                _dealerInAuction[_selectId].currentBidPrice.push(_bidprice);     
                emit makeBidEvent(msg.sender, _bidprice, _selectId);    
                return true;
     }    
    // завершить аукцион и отправить НФТ победителю
    function finishAuction(
        uint _selectId
    )   
        public
        override
        AucTimeIsOut(_selectId)
        onlyDealer(msg.sender)
        returns (address _winner, uint maxBid)
        {
                require(_dealerInAuction[_selectId].tokenId == _selectId, "wrong ID");
                require(_dealerInAuction[_selectId].actionStatus == true, "actionStatus not false");
                address _erc20Contract = _dealerInAuction[_selectId].erc20Conract;
                address _nftContract  = _dealerInAuction[_selectId].nftContract;
                require(_dealerInAuction[_selectId].salesStatus == false, "salesStatus not false");
            // поиск победителя 
            maxBid = 0;
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

            for(uint i = 0; i < _dealerInAuction[_selectId].currentBidPrice.length;) {
            // простая логика поиска победителя максимальной единоразовой ставки (переделай на сумирование если есть более 1 ставки по 1 адресу)
            if(_dealerInAuction[_selectId].currentBidPrice[i] > maxBid && 
            _dealerInAuction[_selectId].currentBidPrice[i] > _dealerInAuction[_selectId].minPrice){
            maxBid = _dealerInAuction[_selectId].currentBidPrice[i];
            _winner = _dealerInAuction[_selectId].lastBidder[i];
             } else {console.log("no winner", _selectId);} 
            } 
            // победителю аукциона переводим nft 
            require(maxBid > _dealerInAuction[_selectId].minPrice, 
            "the minimum price is greater than the maximum bid price"); 
            require(_winner != address(0), "winner address empty");
                     ERC721(_nftContract).transferFrom(
                    address(this),
                    _winner,
                    _selectId
                      );
                // аукцонер получае свои за продажу Nft
            IERC20(_erc20Contract).safeTransferFrom(
                    address(this),   
                    msg.sender,
                    maxBid    
                );  
            _dealerInAuction[_selectId].actionStatus == false;
            _dealerInAuction[_selectId].salesStatus == true;   
          }        
          emit finishAuctionEvent(msg.sender, _nftContract, _selectId);
       }
    
        // function getDealerAndNFTContrByTokenId(uint _selectId) 
    // public 
    // view
    // override
    // returns(
    //     address _dealer,  
    //     address _nftContract
    //     ) {
    // _dealer = dealerTokenId[_selectId].dealerAddress;
    // _nftContract = dealerTokenId[_selectId].nftContract;
    // require(_dealer != address(0), "dealer address under this id does not exist");
    // require(_nftContract != address(0), "nftContract address under this id does not exist");
    // return (_dealer, _nftContract); 
    // }
    }
