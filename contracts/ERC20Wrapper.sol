pragma solidity >0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Wrapper is ERC20, ERC20Detailed, ERC20Mintable, ERC20Burnable, ERC20Pausable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct BorrowerDetails {
        uint256 time;
        uint256 amount;
    }
    // to store the address of 
    IERC20 public immutable coin;
    address immutable factoryContract; 
    uint256 totalLiquidity;
    uint256 usedLiquidity;
    mapping(address=>uint256) liquidityMapping;
    mapping(address => BorrowerDetails) borrowersMapping;

    contructor(address token, bytes[]32 name, bytes[]32 symbol, uint256 precision) ERC20Detailed(name,symbol,precision) public {
      coin = _tokenAddress;
      factoryContract = msg.sender;
      addMinter(msg.sender);
    }

    /* the LenderLoan contract takes permission to spend a particular ERC20 on behalf of the liquidity provider. 
    It sends those token to this smart contract. 
    After sending this contract. The total liquidity is increased.  
    */

    function increaseSupply(uint256 amount) public onlyMinter {
        liquidity += amount;
    }

    function decreaseSupply(uint256 amount , address sender) public onlyMinter {
        uint256 availaibleSupply = getAvailaibleSupply();
        
        require(availaibleSupply >= amount,"not enough tokens to available. Please wait for some more time");
        require(amount <= liquidityMapping[sender] , "not enough liquidity provided by the user");

        totalLiquidity.sub(amount);
        coin.safeTransfer(sender,amount);
    }

    function getLoan(address borrower, uint256 numberOfDays, uint256 amount) public onlyMinter {
        require(amount <= getAvailaibleAmount() , "not enough liquidity");    
        usedLiquidity.add(amount);
        borrowersMapping[borrower] += BorrowerDetails( now + numberOfDays * 1 days,amount);
        _mint(borrower,amount);
    }

    // function paybackLoan(uint256 amount , ) public {
    //     require(amount <= borrowsersMapping[borrower], "you weren't given this much liquidity. Please repay your own loan only");
    //     borrowersMapping[msg.sender]
    // }
    
 
    function getAvailaibleSupply() public returns (uint256) {
        return totalLiquidity.sub(usedLiquidity);
    }
}