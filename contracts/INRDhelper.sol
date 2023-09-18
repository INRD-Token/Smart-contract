/*
    - Integration to frontend
    - Deploying Contract in Mainnet
    - Getting clarity in functions.  
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./INRDtoken.sol";
contract INRDhelper{

    address internal owner; // stores the address of owner(Who deploys the contract)
    INRDToken internal INRDTokenContract; //address of INRDToken
    AggregatorV3Interface internal inrUsdPriceFeed;// Price feed of INR to USD from chainlink oracle
    mapping(address => mapping(bytes32=>uint)) userCollateralBalance;//Stores USDT/USDC balance of user
    mapping(address => uint) userMintedTokens;//stores number of tokens owned by a user
    mapping(bytes32 => address) whitelistedTokens;//stores collateral tokens and its address for accepting.

    constructor(){
        //stores the address of deployer
        owner = msg.sender;
        // Deploying the token contract.
        INRDTokenContract = new INRDToken(address(this));
        // INR - USD conversion oracle in ETH network
        // inrUsdPriceFeed = AggregatorV3Interface(
        //     0x605D5c2fBCeDb217D7987FC0951B5753069bC360
        // );
    }
	receive() external payable {}
    /*
        @Function : getInrToUsdPrice
        @Returns : uint
        Returns the value of 1 INR in USD in realtime by using chainlink oracle. 
    */
    function getInrToUsdPrice() public view returns (uint256) {
        // (, int256 price, , , ) = inrUsdPriceFeed.latestRoundData();
        // require(price > 0, "Invalid ETH price.");
        // return uint256(price);
        return 1203505;
    }

    function calculateAmountOfUSDfromINRD(uint amount)internal view returns(uint){
        return (amount*getInrToUsdPrice())/10**18;
    }

    function calculateAmountOfINRDfromUSD(uint amount)internal view returns(uint){
        return amount*(10**8)/getInrToUsdPrice();
    }

	

    /*
        @Function : whitelistToken
        Collateral tokens can be added for accepting to mint tokens.
    */
    function whitelistToken(bytes32 symbol, address tokenAddress) external {
        require(msg.sender == owner, "This function is not public");
        whitelistedTokens[symbol] = tokenAddress;
    }

    function AddCollateral(bytes32 token,uint _amount) external payable{
        ERC20(whitelistedTokens[token]).approve(address(this),_amount);
        // Transfers the amount of USDT/USDC from user to smart contract.
        ERC20(whitelistedTokens[token]).transferFrom(msg.sender, address(this), _amount);
        //Adding collateral amount to user's colateral account balance.
        userCollateralBalance[msg.sender][token] += calculateAmountOfINRDfromUSD(_amount);
    }

    function mintINRDFromCollateral(bytes32 token,uint amount)external{
        // Checks the amount of collateral in user's balance is sufficient to mint the token or not.
        if(userCollateralBalance[msg.sender][token] < amount*2){
            revert();
        }
        // Minting the tokens to user's account
        INRDTokenContract.mint(msg.sender,amount);
        // Adding minted tokens to user's balance
        userMintedTokens[msg.sender] += amount;
        // Subtracting the user's collateral balance.
        userCollateralBalance[msg.sender][token] -= amount;
    }

    function mintINRDToken(bytes32 token,uint _collateralAmount)external payable{
        //ERC20(whitelistedTokens[token]).approve(address(this),_collateralAmount);
        // Transfers the amount of USDT/USDC from user to smart contract.
        ERC20(whitelistedTokens[token]).transferFrom(msg.sender, address(this), _collateralAmount);
        // Calculates the amount of tokens to be minted from collateral amount.
        uint tokenAmount = calculateAmountOfINRDfromUSD(_collateralAmount);
        // Minting the tokens to user's account
        INRDTokenContract.mint(msg.sender,tokenAmount);
        // Adding minted tokens to user's balance
        userMintedTokens[msg.sender] += tokenAmount;
    }

    function burnINRD(bytes32 token,uint amount)external{
        // checks the amount of tokens in balance to burn.
        if(userMintedTokens[msg.sender]<amount){
            revert();
        }
        // Burns the amount of token from user's account.
        INRDTokenContract.burn(msg.sender,amount);
        // Subtracting minted tokens to user's balance
        userMintedTokens[msg.sender] -= amount;
        // calculates the amount of USDT/USDC to trasfer.
        uint _collateralAmount = calculateAmountOfUSDfromINRD(amount);
        // Transfers the amount of USDT/USDC from smart contract to user.
        // userCollateralBalance[msg.sender][token] += amount;
        ERC20(whitelistedTokens[token]).transfer(msg.sender,_collateralAmount);
    }

    function withdrawerColateral(bytes32 token,uint amountCollateral)external payable{
        // checks user's collateral balance is greater than or equal to amount of colleralteral to withdraw 
        if(userCollateralBalance[msg.sender][token] <= amountCollateral){
            revert();
        }
        ERC20(whitelistedTokens[token]).approve(address(this),amountCollateral);
        // Transfers the amount of USDT/USDC from smart contract to user.
        ERC20(whitelistedTokens[token]).transfer(msg.sender,amountCollateral);
         // Subtracting the user's collateral balance.
        userCollateralBalance[msg.sender][token] -= amountCollateral;
    }

    function INRDBalance()public view returns(uint,uint){
        // returns the balance of INRD token of the user
        return INRDTokenContract.balance(msg.sender);
    }

    function tokenBalance(bytes32 token)public view returns(uint){
        // returns the balance of USDT/USDC token of the user
        return userCollateralBalance[msg.sender][token];
    }
    
}