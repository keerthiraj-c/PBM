// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PBMCoin is ERC20, Ownable {

    uint256 public maxSupply = 21000000 * 10 ** decimals();

    constructor(address account) ERC20("PBM Coin", "PBMC") {
        _mint(account, 2000000 * 10 ** decimals());
    }

    function mint (address account, uint amount) public onlyOwner{
        require((totalSupply() + amount) <= maxSupply, "ERC20: exceeds max supply");
        _mint(account, amount);
    }
      
    function decimals() public view virtual override returns (uint8) {
        return 14;
    }

}