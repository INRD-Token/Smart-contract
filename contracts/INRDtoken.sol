// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
    @Title : INRD stable coin
    @Author : Brahm GAN
    @Description : INRD stable coin is a ERC20 Token where the coin value is always equal 
    to 1 Indian Rupee(INR).
    @Network : ETH (Mainnet)

    Collateral : USDT/USDC
    Pegged to INR
    Governed coin
*/

contract INRDToken is ERC20{
    address public owner;
    
    constructor(address _owner)ERC20("INRDTest","testing the INRD token"){
        owner = _owner;
    }

    function mint(address _user,uint _amount)public{
        require(msg.sender==owner);
        _mint(_user,_amount);
    }

    function burn(address _user,uint _amount)public{
        require(msg.sender==owner);
        _burn(_user,_amount);
    }

    function balance(address _user)public view returns(uint,uint){
     require(msg.sender==owner);
     return (balanceOf(_user),balanceOf(owner));   
    }
}