pragma solidity >0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Wrapper is
    ERC20,
    ERC20Detailed,
    ERC20Mintable,
    ERC20Burnable,
    ERC20Pausable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct BorrowerDetails {
        uint256 time;
        uint256 amount;
    }
    // to store the address of
    IERC20 public immutable Coin;
    address immutable factoryContract;
    uint256 totalLiquidity;
    uint256 usedLiquidity;
    address[] balanceSupplyCallPending;
    mapping(address => uint256) liquidityMapping;
    mapping(address => BorrowerDetails) borrowersMapping;

    constructor(
        address _tokenAddress,
        bytes32[] name,
        bytes32[] symbol,
        uint256 precision,
        address admin
    ) public ERC20Detailed(name, symbol, precision) {
        Coin = _tokenAddress;
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

    function decreaseSupply(uint256 amount, address sender) public onlyMinter {
        uint256 availaibleSupply = getAvailaibleSupply();

        require(
            availaibleSupply >= amount,
            "not enough tokens to available. Please wait for some more time"
        );
        require(
            amount <= liquidityMapping[sender],
            "not enough liquidity provided by the user"
        );

        totalLiquidity.sub(amount);
        Coin.safeTransfer(sender, amount);
    }

    function getLoan(
        address borrower,
        uint256 numberOfDays,
        uint256 amount
    ) public onlyMinter {
        require(amount <= getAvailaibleAmount(), "not enough liquidity");
        usedLiquidity.add(amount);
        addBorrower(borrower, now + numberOfDays * 1 days, amount);
        _mint(borrower, amount);
    }

    function paybackLoan(uint256 amount) public {
        require(
            amount <= borrowsersMapping[borrower],
            "you weren't given this much liquidity. Please repay your own loan only"
        );

        borrowersMapping[msg.sender].amount;
    }

    function getAvailaibleSupply() public returns (uint256) {
        return totalLiquidity.sub(usedLiquidity);
    }

    function balanceSupply() public {
        uint256 callerProfit = 0;
        address iterator;

        for (int256 x = 0; x < balanceSupplyCallPending.length; x++) {
            iterator = balanceSupplyCallPending[x];
            BorrowerDetails storage borrower = borrowersMapping[iterator];
            if (borrower.time > now) {
                callerProfit += borrower.amount;
                burnFrom(iterator, borrower.amount);
                balanceSupplyCallPending[x] = balanceSupplyCallPending[
                    balanceSupplyCallPending.length - 1
                ];
                balanceSupplyCallPending.length--;
                x--;
            }
        }

        uint256 reward = callerProfit.div(100);
        Coin.safeTransfer(msg.sender, reward);
    }

    function addBorrower(
        uint256 recipient,
        uint256 time,
        uint256 amount
    ) internal {
        borrowersMapping[recipient] += BorrowerDetails(time, amount);
        balanceSupplyCallPending.push(recipient);
    }

    // Overridden functions
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        addBorrower(recipient, borrowersMapping[msg.sender].time, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);
        addBorrower(recipient, borrowersMapping[msg.sender].time, amount);

        return true;
    }
}
