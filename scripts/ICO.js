const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();



    

    // Get the contract factory
    const ICO = await ethers.getContractFactory("ICO");

    // Deploy the contract


    const ico = await ICO.deploy('0xb8211a1895AA5be92b6C113273793A3944641Bc4','0x177aE3E7534F05608F1921eC9EfD1f022E2773D5');

    console.log("ICO deployed to:", ico.target);

}

// Execute the main function
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});
