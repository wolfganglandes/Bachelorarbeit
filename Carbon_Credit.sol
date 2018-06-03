pragma solidity ^0.4.20;

//import "browser/ERC20.sol";

interface ERC20 {
    function totalSupply() constant external returns (uint _totalSupply);
    function balanceOf(address _owner) constant external returns (uint balance);
    function transfer(address _to, uint _value) external returns  (bool success);
    function transferFrom(address _from, address _to, uint _value)external returns (bool success);
    function approve(address _spender, uint _value)external returns (bool success);
    function allowance(address _owner, address _spender)external constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract SafeMath {
  function safeMul(uint a, uint b)pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b)pure internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b)pure internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion)pure internal {
    if (!assertion) revert();
  }
}

contract Carbon_Credit is ERC20, SafeMath {
    string public constant symbol = "CC";
    string public  constant name = "Carbon Credit";
   
    uint8 public constant decimals = 0;
    uint private  __totalSupply = 0; 
    mapping (address => mapping (address => uint)) private __allowances;
    
    struct Participant {
        string name;   // Unique
        bool exists;
        bool renewableEnergy; //Is participant renewableEnergy -> true; or a company->false
        uint stillAllowed;  //How much tokenPrice are you still Allowed to buy.
        uint tokenBalance;
        uint greenInvestment;
        uint burned;
    }
    
    //LISTS on Smart Contract as reference for Transaction.
    mapping (address => Participant) public participants;
    mapping (address => mapping (bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
    mapping (address => mapping (bytes32 => uint)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)

    address public owner;

    //ATTRIBUTES Smart Contract updated after each transaction
    uint public expensiveTokenPrice = 3 ether;
    uint public tokenPrice = 1 ether;
    

      function totalSupply()public constant returns (uint _totalSupply) {
        _totalSupply = __totalSupply;
    }
    
    uint public withdrawPrice = 0; // Dynamic to this.balance / __totalSupply;


    function balanceOf(address _addr)public constant returns (uint) {
        return participants[_addr].tokenBalance;
    }
    //Events for Frontend
    event OrderCreated(uint amountGet,uint amountGive,uint expires,uint nonce, address _creator);
    event OrderFilled(uint amountGet, uint amountGive, uint expires, uint nonce, address _creator, address buyer, uint amount);
     //Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);

    //MODIFIER
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier onlyCompany(){
        require(participants[msg.sender].exists);
        require(participants[msg.sender].renewableEnergy == false);
        _;
    }
    modifier onlyRenewable(){
        require(participants[msg.sender].exists);
        require(participants[msg.sender].renewableEnergy == true);
        _;
    }
   
    //REGISTER Functions: Require owner == msg.sender
    function registerParticipant(address a, string _name, bool _renewableEnergy, uint _allowed) public onlyOwner {
        participants[a] = Participant(_name, true, _renewableEnergy, _allowed, 0, 0, 0);
    }
    
     //CREATE SMART CONTRACT
     constructor()public {
        owner = msg.sender;
     
    }
    
    //Money stored on Smart Contract
    function getMyBalance()view public returns (uint) { return address(this).balance; }
    
    //Burning Credits increases withdrawPrice
    function burnToken(uint amount)public onlyCompany{
        require(participants[msg.sender].tokenBalance>=amount);
        
        participants[msg.sender].tokenBalance -= amount;
        participants[msg.sender].burned += amount;
        __totalSupply -= amount;
        withdrawPrice = address(this).balance / __totalSupply;
    }
    
    
  
  //Transer Credits with this function  
     function transfer(address _to, uint _value)public returns (bool success) {
        if (_value > 0 && _value <= balanceOf(msg.sender)) {
            participants[msg.sender].tokenBalance -= _value;
            participants[_to].tokenBalance += _value;
            emit Transfer(  msg.sender,   _to,  _value);
            return true;
        }
        return false;
    }
    
    
    function transferFrom(address _from, address _to, uint _value)public returns (bool success) {
        if (__allowances[_from][msg.sender] > 0 && _value > 0 &&
            __allowances[_from][msg.sender] >= _value && 
            participants[_from].tokenBalance >= _value) {
            participants[_from].tokenBalance -= _value;
            participants[_to].tokenBalance += _value;
            __allowances[_from][msg.sender] -= _value;
            return true;
        }
        return false;
    }
    
     function approve(address _spender, uint _value)public returns (bool success) {
        __allowances[msg.sender][_spender] = _value;
        emit Approval( msg.sender,   _spender,  _value);
        return true;
    }
    
    function allowance(address _owner, address _spender)public constant returns (uint remaining) {
        return __allowances[_owner][_spender];
    }
    
    // Companies are allowed to buy renewable Products with 
    // Token
    function buyGreenEnergy(address renew, uint amount) public onlyCompany{
        require((participants[renew].renewableEnergy) == true);
        
        if(participants[msg.sender].tokenBalance >= amount){
            //participants buy Renewable
            participants[msg.sender].tokenBalance -= amount;
            participants[msg.sender].greenInvestment += amount;
            participants[renew].tokenBalance += amount;
            }
    }
    
    /*Only GreenEnergy 
    is allowed to return Credits and get Paid for it
    withdrawPrice == Money on Smart Contract / __totalSupply
    The more Credits get burned the higher the withdrawPrice
    The more participants have to pay expensiveTokenPrice for Credits 
    the higher the withdrawPrice*/
    
    function burnTokenAndWithdraw(uint _value)public onlyRenewable{
        require(participants[msg.sender].tokenBalance>=_value);
        
        participants[msg.sender].tokenBalance -=_value;
        msg.sender.transfer(_value*withdrawPrice);
        __totalSupply -= _value;
     }
    
   
    // ONLY COMPANY or PrivatePerson
    // Buy Credits for tokenPrice as much as you are allowed
    // After that buy Credits for expensiveTokenPrice depending on msg.value
    function buyToken() payable public onlyCompany {
             if(msg.value <= participants[msg.sender].stillAllowed * tokenPrice){
            //Only Cheap price
                uint creditsBoughtCheap = msg.value / tokenPrice;
                participants[msg.sender].stillAllowed -= creditsBoughtCheap;
                participants[msg.sender].tokenBalance += creditsBoughtCheap;
                __totalSupply += creditsBoughtCheap;
                withdrawPrice = address(this).balance / __totalSupply;
        
                return;
            }else{
                // Credits for Cheap + Credits for Expensive 
                uint input = msg.value;
                input -= participants[msg.sender].stillAllowed * tokenPrice;
                uint maxCheap = participants[msg.sender].stillAllowed;
                participants[msg.sender].stillAllowed -= maxCheap;
                participants[msg.sender].tokenBalance += maxCheap;
                __totalSupply += maxCheap;
            
                uint creditsBoughtExp = input / expensiveTokenPrice;
                participants[msg.sender].tokenBalance += creditsBoughtExp;
                __totalSupply += creditsBoughtExp;
                withdrawPrice = address(this).balance / __totalSupply;
            }
    }
    
    //Fallback function
    function()private{revert();}
    
    function orderIwantEther( uint amountEtherGet, uint amountTokenGive, uint expires, uint nonce)public {
    bytes32 hash = sha256(this, amountEtherGet, amountTokenGive, expires, nonce);
    orders[msg.sender][hash] = true;
    emit OrderCreated( amountEtherGet, amountTokenGive, expires, nonce,  msg.sender);
    
  } 
        
  function trade( uint amountEtherGet, uint amountTokenGive, uint expires, uint nonce, address user)public payable{
    uint amountSend =  msg.value;
    //amount is in amountGet terms
    bytes32 hash = sha256(this, amountEtherGet, amountTokenGive, expires, nonce);
   if (!(
      orders[user][hash] &&
   //   block.number <= expires &&
      safeAdd(orderFills[user][hash], msg.value) <= amountEtherGet
    )) revert();
    tradeBalances( amountEtherGet,  amountTokenGive, user, msg.value);
    orderFills[user][hash] = safeAdd(orderFills[user][hash], msg.value);
    emit OrderFilled( amountEtherGet, amountTokenGive, expires, nonce,  msg.sender, msg.sender, amountSend );
    }

  function tradeBalances( uint amountEtherGet,  uint amountTokenGive, address user, uint amount) private {
     //Trade Ether
    user.transfer(amount);
    //Trade tokens
    participants[user].tokenBalance = safeSub(participants[user].tokenBalance, safeMul(amountTokenGive, amount) / amountEtherGet);
    participants[msg.sender].tokenBalance = safeAdd(participants[msg.sender].tokenBalance, safeMul(amountTokenGive, amount) / amountEtherGet);
    }

  function testTrade(uint amountGet,  uint amountGive, uint expires, uint nonce, address user, uint amount)public constant returns(bool) {
    if (!(availableVolume( amountGet, amountGive, expires, nonce, user) >= amount
    )) return false;
    return true;
  }

  function availableVolume( uint amountGet, uint amountGive, uint expires, uint nonce, address user)public constant returns(uint) {
    bytes32 hash = sha256(this, amountGet, amountGive, expires, nonce);
    if (!(
      orders[user][hash] 
      //block.number <= expires
      )) return 0;
    uint available1 = safeSub(amountGet, orderFills[user][hash]);
    uint available2 = safeMul(participants[user].tokenBalance, amountGet) / amountGive;
    if (available1<available2) return available1;
    return available2;
  }

  function amountFilled( uint amountGet, uint amountGive, uint expires, uint nonce, address user)public constant returns(uint) {
    bytes32 hash = sha256(this,  amountGet, amountGive, expires, nonce);
    return orderFills[user][hash];
  }

  function cancelOrder( uint amountGet,  uint amountGive, uint expires, uint nonce)public {
    bytes32 hash = sha256(this, amountGet,  amountGive, expires, nonce);
    if (!(orders[msg.sender][hash]) ) revert();
    orderFills[msg.sender][hash] = amountGet;
   // Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }  
}
    