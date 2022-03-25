## Description stake task: 

Техническое задание (маркетплэйс)
Написать контракт маркетплейса, который должен включать в себя функцию создания NFT, а также функционал аукциона.
-Написать контракт маркетплейса NFT
-Написать полноценные тесты к контракту
-Написать скрипт деплоя
-Задеплоить в тестовую сеть
-Написать таск на mint
-Верифицировать контракт
Требования  
-Функция createItem() - создание нового предмета, обращается к контракту NFT и вызывает функцию mint.
-Функция mint(), доступ к которой должен иметь только контракт маркетплейса
-Функция listItem() - выставка на продажу предмета.
-Функция buyItem() - покупка предмета.
-Функция cancel() - отмена продажи выставленного предмета
-Функция listItemOnAuction() - выставка предмета на продажу в аукционе.
-Функция makeBid() - сделать ставку на предмет аукциона с определенным id.
-Функция finishAuction() - завершить аукцион и отправить НФТ победителю
-Функция cancelAuction() - отменить аукцион

Аукцион длится 3 дня с момента старта аукциона. В течении этого срока аукцион не может быть отменен. В случае если по истечению срока набирается более двух ставок аукцион считается состоявшимся и создатель аукциона его завершает (НФТ переходит к последнему биддеру и токены создателю аукциона). В противном случае токены возвращаются последнему биддеру, а НФТ остается у создателя.

#### Token contract address (Rinkiby): 

- NftMarketplace contract = ''

### Description NftMarketplace contract:



#### All packages:
```
yarn init 
yarn add --dev hardhat 
yarn add --dev @nomiclabs/hardhat-ethers ethers 
yarn add --dev @nomiclabs/hardhat-waffle ethereum-waffle chai
yarn add --save-dev @nomiclabs/hardhat-etherscan
yarn add install dotenv 
yarn add --dev solidity-coverage 
yarn add --dev hardhat-gas-reporter 
yarn add --dev hardhat-gas-reporter
yarn add --dev hardhat-contract-sizer
```
#### Main command:
```
npx hardhat 
npx hardhat run scripts/file-name.js
npx hardhat test 
npx hardhat coverage
npx hardhat run --network localhost scripts/deploy.js
npx hardhat run scripts/deploy.js --network rinkiby
npx hardhat verify <contract_address> --network rinkiby
npx hardhat verify --constructor-args scripts/arguments.js <contract_address> --network rinkiby
npx hardhat verify --constructor-args scripts/arguments.js <conract_address> --network rinkiby
yarn run hardhat size-contracts 
yarn run hardhat size-contracts --no-compile
```
#### : 

```

```

#### Testing report   
