// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./INRDtoken.sol";

contract INRDhelper{
    address internal owner; // stores the address of owner(Who deploys the contract)
    uint public totalSupplyOnchain = 0;
    uint public totalSupplyOffchain = 0;
    INRDToken internal INRDTokenContract; //address of INRDToken
    AggregatorV3Interface internal inrUsdPriceFeed;// Price feed of INR to USD from chainlink oracle
    mapping(address user => mapping(string token=>uint balance)) userCollateralBalance;//Stores USDT/USDC balance of user
    mapping(address user => uint balance) userMintedTokens;//stores number of tokens owned by a user
    mapping(string => address) whitelistedTokens;//stores collateral tokens and its address for accepting.

    constructor(){
        //stores the address of deployer
        owner = msg.sender;
        // Deploying the token contract.
        INRDTokenContract = new INRDToken(address(this));
        // INR - USD conversion oracle in ETH network
        inrUsdPriceFeed = AggregatorV3Interface(
            0xDA0F8Df6F5dB15b346f4B8D1156722027E194E60
        );
    }

    /*
        @Function : getInrToUsdPrice
        @Returns : uint
        Returns the value of 1 INR in USD in realtime by using chainlink oracle. 
    */
    function getInrToUsdPrice() public view returns (uint256) {
        (, int256 price, , , ) = inrUsdPriceFeed.latestRoundData();
        require(price > 0, "Invalid ETH price.");
        return uint256(price);
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
    function whitelistToken(string memory symbol, address tokenAddress) external {
        require(msg.sender == owner, "This function is not public");
        whitelistedTokens[symbol] = tokenAddress;
    }


    function AddCollateral(string memory token,uint _amount) external payable{
    // Transfers the amount of USDT/USDC from user to smart contract.
    ERC20(whitelistedTokens[token]).transferFrom(msg.sender, address(this), _amount);
    //Adding collateral amount to user's colateral account balance.
    userCollateralBalance[msg.sender][token] += calculateAmountOfINRDfromUSD(_amount);
    }

    function mintINRDFromCollateral(string memory token,uint amount)external{
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
         if(owner==msg.sender){
            totalSupplyOffchain += amount;
        }else{
            totalSupplyOnchain += amount;
        }
    }

    function mintINRDToken(string memory token,uint _collateralAmount)external payable{
        ERC20(whitelistedTokens[token]).approve(address(this),_collateralAmount);
        // Transfers the amount of USDT/USDC from user to smart contract.
        ERC20(whitelistedTokens[token]).transferFrom(msg.sender, address(this), _collateralAmount);
        // Calculates the amount of tokens to be minted from collateral amount.
        uint tokenAmount = calculateAmountOfINRDfromUSD(_collateralAmount);
        // Minting the tokens to user's account
        INRDTokenContract.mint(msg.sender,tokenAmount);
        // Adding minted tokens to user's balance
        userMintedTokens[msg.sender] += tokenAmount;
        if(owner==msg.sender){
            totalSupplyOffchain += tokenAmount;
        }else{
            totalSupplyOnchain += tokenAmount;
        }
    }

    function burnINRD(string memory token,uint amount)external{
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
        if(owner==msg.sender){
            totalSupplyOffchain -= amount;
        }else{
            totalSupplyOnchain -= amount;
        }
    }

    function withdrawerColateral(string memory token,uint amountCollateral)external payable{
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

    function tokenBalance(string memory token)public view returns(uint){
        // returns the balance of USDT/USDC token of the user
        return userCollateralBalance[msg.sender][token];
    }
    
}