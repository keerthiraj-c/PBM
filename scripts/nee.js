const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();



    

    // Get the contract factory
    const PBMCoin = await ethers.getContractFactory("PBMCoin");

    // Deploy the contract


     const pbmcoin = await PBMCoin.deploy('0xe3d9d8065C0428d46acdB987939277d6A3E2b267');

    console.log("PBMCoin deployed to:", pbmcoin.target);

    
  
  
    // Obtain the deployed contract's address
   

    // // Get the contract factory
    const TokenMultisender = await ethers.getContractFactory("TokenMultisender");

    // Deploy the contract
    const tokenMultisender = await TokenMultisender.deploy();
  
    // Obtain the deployed contract's address

    await tokenMultisender.waitForDeployment();
    console.log("TokenMultisender deployed to:", tokenMultisender.target);
    
    

    await pbmcoin.approve(tokenMultisender.target,"1000000000000000000000")

    //await pbmcoin.allowance('0x9B7A0bD3d17D75287423ddC14a1fA5A47B8eEA2c',tokenMultisender.target)
      
    const  hlo =   await pbmcoin.allowance('0xe3d9d8065C0428d46acdB987939277d6A3E2b267',tokenMultisender.target)
    console.log( "allowance balance", hlo);
    
    
}

// Execute the main function
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});


