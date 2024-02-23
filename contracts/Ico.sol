// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ICO is ReentrancyGuard, AccessControl{
    event TokenBuyed(address indexed to, uint256 amount);
    event TokenPerUSDPriceUpdated(uint256 amount);
    event PaymentTokenDetails(tokenDetail);
    event TokenAddressUpdated(address indexed tokenAddress);
    event TokenHolderAddressUpdated(address indexed tokenHolder);
    event SignerAddressUpdated(
        address indexed previousSigner,
        address indexed newSigner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    mapping(uint256 => tokenDetail) public paymentDetails;
    mapping(uint256 => bool) usedNonce;

    IERC20 public tokenAddress;
    address public signer;
    address public owner;
    address public tokenHolder;
    uint256 public tokenAmountPerUSD = 10 * 10**18;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    struct tokenDetail {
        string paymentName;
        address priceFetchContract;
        address paymentTokenAddress;
        uint256 decimal;
        bool status;
    }

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    constructor(IERC20 _tokenAddress, address _tokenHolder) {
        owner = msg.sender;
        signer = msg.sender;
        tokenHolder = _tokenHolder;
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(SIGNER_ROLE, msg.sender);
        tokenAddress = _tokenAddress;

        paymentDetails[0] = tokenDetail(
            "ETH",
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e,
            0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6,
            18,
            true
        );
        paymentDetails[1] = tokenDetail(
            "WBTC",
            0xA39434A63A52E749F02807ae27335515BA4b07F7,
            0xC04B0d3107736C32e19F1c62b2aF67BE61d63a05,
            8,
            true
        );
        paymentDetails[2] = tokenDetail(
            "USDT",
            0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7,
            0x5AB6F31B29Fc2021436B3Be57dE83Ead3286fdc7,
            18,
            true
        );
        paymentDetails[3] = tokenDetail(
            "DAI",
            0x0d79df66BE487753B02D015Fb622DED7f0E9798d,
            0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844,
            8,
            true
        );paymentDetails[4] = tokenDetail(
            "LINK",
            0x48731cF7e84dc94C5f84577882c14Be11a5B7456,
            0x63bfb2118771bd0da7A6936667A7BB705A06c1bA,
            8,
            true
        );
    }

    function transferOwnership(address newOwner) external onlyRole(ADMIN_ROLE) {
        require(newOwner != address(0), "Invalid Address");
        _revokeRole(ADMIN_ROLE, owner);
        address oldOwner = owner;
        owner = newOwner;
        _setupRole(ADMIN_ROLE, owner);
        emit OwnershipTransferred(oldOwner, owner);
    }

    function setSignerAddress(address signerAddress)
        external
        onlyRole(SIGNER_ROLE)
    {
        require(signerAddress != address(0), "Invalid Address");
        _revokeRole(SIGNER_ROLE, signer);
        address oldSigner = signer;
        signer = signerAddress;
        _setupRole(SIGNER_ROLE, signer);
        emit SignerAddressUpdated(oldSigner, signer);
    }

    function getLatestPrice(uint256 paymentType) public view returns (int256) {
        (, int256 price, , , ) = AggregatorV3Interface(
            paymentDetails[paymentType].priceFetchContract
        ).latestRoundData();
        return price;
    }

    function buyToken(
        address recipient,
        uint256 paymentType,
        uint256 tokenAmount,
        Sign memory sign
    ) external payable nonReentrant {
        require(paymentDetails[paymentType].status, "Invalid Payment");
        require(!usedNonce[sign.nonce], "Invalid Nonce");
        usedNonce[sign.nonce] = true;
        require(msg.value > 0 || tokenAmount > 0, "Invalid amount");
        uint256 amount;
        if (paymentType == 0) {
            verifySign(paymentType, recipient, msg.sender, msg.value, sign);
            amount = getToken(paymentType, msg.value);
            payable(owner).transfer(msg.value);
        } else {
            verifySign(paymentType, recipient, msg.sender, tokenAmount, sign);
            amount = getToken(paymentType, tokenAmount);
            IERC20(paymentDetails[paymentType].paymentTokenAddress).transferFrom(
                msg.sender,
                owner,
                tokenAmount
            );
        }
        bool success = tokenAddress.transferFrom(tokenHolder, recipient, amount);
        require(success, "tx failed");
        emit TokenBuyed(msg.sender, amount);
    }

    function recoverETH() external payable onlyRole(ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function sendETH(uint256 amount, address walletAddress) external payable onlyRole(ADMIN_ROLE) {
        require(walletAddress != address(0), "Null address");
        require(amount <= address(this).balance, "Amount is greater than balance");
        payable(walletAddress).transfer(amount);
    }

    function getToken(uint256 paymentType, uint256 tokenAmount)
        public
        view
        returns (uint256 data)
    {
        uint256 price = uint256(getLatestPrice(paymentType));
        uint256 amount = price * tokenAmountPerUSD / 1e8;
        data = amount * tokenAmount / (10**paymentDetails[paymentType].decimal);
    }

    function recoverToken(address _tokenAddress, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(amount <= IERC20(_tokenAddress).balanceOf(address(this)), "Insufficient amount");
        bool success = IERC20(_tokenAddress).transferFrom(
            address(this),
            msg.sender,
            amount
        );
        require(success, "tx failed");
    }

    function sendToken(address _tokenAddress, uint256 amount, address walletAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(walletAddress != address(0), "Null address");
        require(amount <= IERC20(_tokenAddress).balanceOf(address(this)), "Insufficient amount");
        bool success = IERC20(_tokenAddress).transferFrom(
            address(this),
            walletAddress,
            amount
        );
        require(success, "tx failed");
    }

    function setPaymentTokenDetails(
        uint256 paymentType,
        tokenDetail memory _tokenDetails
    ) external onlyRole(ADMIN_ROLE) {
        paymentDetails[paymentType] = _tokenDetails;
        emit PaymentTokenDetails(_tokenDetails);
    }

    function setTokenAddress(address _tokenAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        tokenAddress = IERC20(_tokenAddress);
        emit TokenAddressUpdated(address(tokenAddress));
    }

    function setTokenPricePerUSD(uint256 tokenAmount)
        external
        onlyRole(ADMIN_ROLE)
    {
        tokenAmountPerUSD = tokenAmount;
        emit TokenPerUSDPriceUpdated(tokenAmountPerUSD);
    }

    function setTokenHolder(address _tokenHolder)
        external
        onlyRole(ADMIN_ROLE)
    {
        tokenHolder = _tokenHolder;
        emit TokenHolderAddressUpdated(tokenHolder);
    }

    function verifySign(
        uint256 assetType,
        address recipient,
        address caller,
        uint256 amount,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(assetType, recipient, caller, amount, sign.nonce)
        );
        require(
            signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            hash
                        )
                    ),
                    sign.v,
                    sign.r,
                    sign.s
                ),
            "Owner sign verification failed"
        );
    }
}