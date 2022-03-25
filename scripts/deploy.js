
async function main() {
  const ltokenAddress = '' //
  const rewardsAddress = '' // 

  const [deployer] = await ethers.getSigners()
  
  const Staking = await ethers.getContractFactory("NftMarketplace");
  const staking = await Staking.deploy();

  console.log("Deploying contracts with the account:", deployer.address)
  console.log("Account balance:", (await deployer.getBalance()).toString())

  console.log("NFTMarketplace  contract address:", staking.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
      console.error(error);
      process.exit(1);
  });

