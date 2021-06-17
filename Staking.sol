// SPDX-License-Identifier: none
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Stake {

  struct Tariff {
    uint time;
    uint percent;
  }

  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
    bool isWithdrawal;
  }

  struct Investor {
    bool registered;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint investedAt;
    uint firstDepositAt;
    uint totalEarningSoFar;
    uint withdrawn;
    uint totalWithdrawn;
    uint withdrawnRoi;
  }

  address public owner = msg.sender;
  // Insert any ERC20 Token address
  address tokenAddr = ;
  address contractAddr = address(this);

  Tariff[] public tariffs;

  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;

  mapping (address => Investor) public investors;
  mapping (address => Tariff) public tariff;
  mapping(address => uint[]) user_deposit_time;
  mapping(address => uint[]) user_deposit_amount;
  
  event DepositAt(address user, uint amount);
  event Withdraw(address user, uint amount);
  event TransferOwnership(address user);
  event Received(address, uint);

  function register() internal {

    if (!investors[msg.sender].registered) {

      investors[msg.sender].registered = true;
      investors[msg.sender].investedAt = block.timestamp;
      investors[msg.sender].firstDepositAt = block.timestamp;
     
      totalInvestors++;
    }
  }
  
  // Set the total time and total interest to be given to the user who stakes tokens.
  constructor()  {
    tariffs.push(Tariff(x days, y));
  }

    function deposit(uint tokenAmount) external {
        
        IERC20 token = IERC20(tokenAddr);
        tokenAmount = tokenAmount;
        require(tokenAmount > 0);
        require(token.balanceOf(msg.sender) > 0);
        token.approve(contractAddr, tokenAmount);
        token.transferFrom(msg.sender, contractAddr, tokenAmount);
      
        register();
           
        investors[msg.sender].invested += tokenAmount;
            
        totalInvested += tokenAmount;
    
        investors[msg.sender].deposits.push(Deposit(0, tokenAmount, block.timestamp,false));
        
        emit DepositAt(msg.sender, tokenAmount);
    }
  
function withdrawable(address user) public view returns (uint amount) {
    
        Investor storage investor = investors[user];

        for (uint i = 0; i < investor.deposits.length; i++) {
    
          Deposit storage dep = investor.deposits[i];
    
          Tariff storage tariffNew = tariffs[dep.tariff];
    
          
          uint finish = dep.at + tariffNew.time;
          uint since = dep.at ;
          uint till = block.timestamp > finish ? finish : block.timestamp;
          
          amount += dep.amount * (till - since) * tariffNew.percent / tariffNew.time / 100;
          
        }
        amount = amount - investor.withdrawnRoi;
        return amount;
  }
  
  function principalWithdrawable(address user) internal returns (uint amount) {

        Investor storage investor = investors[user];

        for (uint i = 0; i < investor.deposits.length; i++) {
    
          Deposit storage dep = investor.deposits[i];
    
          Tariff storage tariffNew = tariffs[dep.tariff];
    
          
          uint finish = dep.at + tariffNew.time;
          uint since = dep.at ;
          uint till = block.timestamp > finish ? finish : block.timestamp;
          uint timeDiff = till - since;
          
          // Set Time difference as you want. Principal amount can be withdrawn after that time only.          
          require(timeDiff >= , "Principal withdrawal time limit not reached!");
            amount += dep.amount * (till - since) * tariffNew.percent / tariffNew.time / 100;
            amount += dep.amount;
            investor.deposits[i].isWithdrawal = true;
          }
          amount = amount - investor.withdrawn;
        return amount;

  }
  
  function principalWithdrawableView(address user) external view returns (uint amount) {

        Investor storage investor = investors[user];

        for (uint i = 0; i < investor.deposits.length; i++) {
    
          Deposit storage dep = investor.deposits[i];
    
          Tariff storage tariffNew = tariffs[dep.tariff];
    
          
          uint finish = dep.at + tariffNew.time;
          uint since = dep.at ;
          uint till = block.timestamp > finish ? finish : block.timestamp;
          uint timeDiff = till - since;
          
          // Set Time difference as you want. Principal amount can be withdrawn after that time only.
          if(timeDiff >= ){
            amount+= dep.amount * (till - since) * tariffNew.percent / tariffNew.time / 100;
            amount += dep.amount;
          }
        }
        amount = amount - investor.withdrawn;
        return amount;

  }
  
  
  function withdraw(address payable to) external { 
      
    
        uint amount = withdrawable(msg.sender);
        IERC20 token = IERC20(tokenAddr);
        
        token.transfer(to, amount);
        
        investors[msg.sender].paidAt = block.timestamp;
        investors[msg.sender].totalEarningSoFar += amount;
        investors[msg.sender].withdrawn += amount;
        investors[msg.sender].totalWithdrawn += amount;
        totalWithdrawal += amount;
        investors[msg.sender].withdrawnRoi += amount;

        emit Withdraw(to, amount);
    }
  
  
  function principalWithdraw(address payable to) external {
      uint amount = principalWithdrawable(msg.sender);
      IERC20 token = IERC20(tokenAddr);
      token.transfer(to, amount);
      investors[msg.sender].totalWithdrawn += amount;
      investors[msg.sender].withdrawn += amount;
      investors[msg.sender].totalEarningSoFar += amount;
      investors[msg.sender].withdrawnRoi += withdrawable(msg.sender);
      totalWithdrawal += amount;
       
      emit Withdraw(to, amount);
  }
  
  function myData(address userAddr) public view returns (uint,uint,uint,uint,uint) {

    Investor storage investor = investors[userAddr];
     
     uint invested = investor.invested;
     uint totalIncome = withdrawable(userAddr);
     uint withdrawn = investor.withdrawn;
	 return (invested,totalIncome,withdrawn,totalInvestors,totalInvested);
  }

  function withdrawToken(address tokenAddress, address to, uint amount) external {
      require(msg.sender == owner);
      IERC20 token = IERC20(tokenAddress);
      token.transfer(to, amount);
  }  

  function withdrawBNB(address payable to, uint amount) external {
        require(msg.sender == owner);
        to.transfer(amount);
  }
  
   function transferOwnership(address to) external {
        require(msg.sender == owner);
        owner = to;
        emit TransferOwnership(owner);
  }

  receive() external payable {
        emit Received(msg.sender, msg.value);
    }  
    
}
