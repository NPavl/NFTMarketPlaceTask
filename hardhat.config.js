require('dotenv').config();
require("@nomiclabs/hardhat-waffle")
const {PRIVATE_KEY, ALCHEMY_API_KEY, ETHERSCAN_API_KEY, COINMARKETCAP_API_KEY} = process.env
require("@nomiclabs/hardhat-etherscan")
//require('solidity-coverage')
//require("hardhat-gas-reporter");
//require('hardhat-contract-sizer');

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
  console.log("Account balance:", (await deployer.getBalance()).toString())
})

 module.exports = {
  solidity: "0.8.4",
  networks: {
    rinkiby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${PRIVATE_KEY}`], // [`0x${PRIVATE_KEY}`]
      network_id: 4
    },  
    // ropsten: {
    //   url: `https://ropsten.infura.io/v3/${INFURA_API_KEY}`,
    //   accounts: [`0x${PRIVATE_KEY}`],
    //   network_id: 3
    // },   
    // hardhat: {
    //   forking: {  // https://hardhat.org/hardhat-network/
    //     url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
    //     blockNumber: 12883802
    //   } // https://hardhat.org/hardhat-network/guides/mainnet-forking.html
    // },
    // bcs_test: {
    //   url: `https://mainnet.infura.io/v3/${ALCHEMY_API_KEY}`,
    //   accounts: [`0x${PRIVATE_KEY}`],
    //   network_id: 97
    // }
  }, 
  // gasReporter: { 
  //   currency: "USD",
  //   coinmarketcap: COINMARKETCAP_API_KEY || null, // process.env.COINMARKETCAP_API_KEY
  // },
  // gasReporter: { 
  //   enabled: process.env.REPORT_GAS ? true : false, 
  //   currency: "ETH", 
  //   // gasPrice: 21, 
  //   coinmarketcap: COINMARKETCAP_API_KEY
  // },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  }
}