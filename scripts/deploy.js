
async function main() {
  // const ltokenAddress = '' //
  // const rewardsAddress = '' // 

  const [deployer] = await ethers.getSigners()
  
  const ERC721Simple = await ethers.getContractFactory("ERC721Simple");
  const eERC721Simple = await ERC721Simple.deploy();

  console.log("Deploying contracts with the account:", deployer.address)
  console.log("Account balance:", (await deployer.getBalance()).toString())

  console.log("ERC721Simple  contract address:", eERC721Simple.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
      console.error(error);
      process.exit(1);
  });

