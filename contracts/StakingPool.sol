// SPDX-License-Identifier: MIT
pragma solidity ^0.6.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

/// @notice This is the Ethereum 2.0 deposit contract inter face.
interface IDepositContract {
    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}


contract StakingPool {
    using SafeMath for uint256;
    address payable public owner;
    bool public finalized;
    uint256 public end;
    uint256 constant stake = 32 ether;
    uint256 public totalInvested;
    uint256 public totalChange; // replace Change by Extra
    mapping (address => uint256) public balances;
    mapping (address => bool) public changeClaimed;
    mapping (bytes => bool) public pubkeysUsed; // pubkeys for Validators
    IDepositContract public depositContract = IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);
    

    
    event NewInvestor (address investor);
    
    constructor() public {
        owner = msg.sender;
        end = block.timestamp.add(7 days); // TODO: instead, make function to start period
    }
    
    function invest() external payable {
        require(block.timestamp < end, 'too late');
        if (balances[msg.sender] == 0) {
            emit NewInvestor(msg.sender);
        }
        //uint256 fee = msg.value * 1 / 100;
        uint256 fee = msg.value.mul(15).div(1000);
        uint256 amountInvested = msg.value.sub(fee);
        owner.transfer(fee);
        balances[msg.sender] += amountInvested; // TODO: safemath
    }
    
    // Once the period is over, this function will calculate the extra amount 
    // (after completing all 32 allocations) to be returned to investors
    function finalize() external {
        require(block.timestamp >= end, 'too early');
        require(finalized == false, 'already finalized');
        finalized = true;
        totalInvested = address(this).balance;
        //totalChange = address(this).balance % stake;
        totalChange = address(this).balance.mod(stake);
    }
    
    //@dev: allow each investor to claim his/her change
    //We don't distribute the change to all investor to avoid spending too much gas
    function getChange() external {
        require(finalized == true, 'not finalized');
        require(balances[msg.sender] > 0, 'not an investor');
        require(changeClaimed[msg.sender] == false, 'change already claimed');
        changeClaimed[msg.sender] = true;
        // Amount of change to be distributed to investors
        uint256 amount = totalChange.mul(balances[msg.sender].div(totalInvested));
        msg.sender.transfer(amount);
    }
    
    // to be called for each 32 ethers (which is linked to a different pubkey). To improve: array of pubkeys
    /*
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external {
        require(finalized == true, 'too early');
        require(msg.sender == owner, 'only owner');
        require(address(this).balance >= 32 ether);
        require(pubkeysUsed[pubkey] == false, 'this pubkey was already used');
        depositContract.deposit{value: 32 ether} ();
    }
    */
    
}