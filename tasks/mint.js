const { PRIVATE_KEY, URL_ALCHEMY, CONTRACT_ADDRESS } = process.env 


// async function main() {

//     const contractAddress = CONTRACT_ADDRESS
//     const provider = new ethers.providers.JsonRpcProvider(URL_ALCHEMY)
//     const admin = new ethers.Wallet(PRIVATE_KEY, provider)
//     const myContract = await ethers.getContractAt('ERC20token', contractAddress, admin)
//     const value = ethers.utils.parseEther('10')
//     try {
//         await myContract.connect(admin).mint(admin.address, value)
//         const BalanceEth = await ethers.utils.formatEther(value)
//         console.log(`The operation was successful
//         on the contract address: ${CONTRACT_ADDRESS} is minted: ${BalanceEth} BLR`)
        
//     } catch (error) {
//         console.log('Something went wrong: ', error)
//     }
// }

// main()
//     .then(() => process.exit(0))
//     .catch((error) => {
//         console.error(error)
//         process.exit(1)
//     })