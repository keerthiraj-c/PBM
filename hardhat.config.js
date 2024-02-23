require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  
//   networks:{
//     bscscan:{
//       url: "https://bsc-testnet.publicnode.com",
//       accounts: ['dca56db197c78920b84527c194cb53b16d7c4343381738501852fef31cbca25c'],
//     },
//   },
// etherscan: {
//   apiKey: '8JGAJM8RSSSEYMQT54XKTAY6KN1DSKVWWJ'
// },



 networks: {
  testnet: {
      url: "https://eth-sepolia.g.alchemy.com/v2/K4CIVjVvhny_B8TbHO6L6B9qcK48OfhU",
       accounts: ['e84944aff5070affdddc572ef67e8c812f78822ddee925a22d52852f29589370'],
     },
  },
  etherscan:{
    apiKey:'26RXK8F8UYC78SYM9NQTC14XRZI1QBSX62',
  },


}