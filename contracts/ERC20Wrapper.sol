pragma solidity >0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20Wrapper is ERC20Upgradeable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant MULTISIGADMIN = keccak256("MULTISIG");

    struct BorrowerDetails {
        uint256 time;
        uint256 amount;
    }

    // to store the address of token
    IERC20 public Coin;
    address factoryContract;
    uint256 totalLiquidity;
    uint256 usedLiquidity;
    address[] balanceSupplyCallPending;
    mapping(address => uint256) liquidityMapping;
    mapping(address => BorrowerDetails) borrowersMapping;

    function initialize(
        IERC20 _tokenAddress,
        string calldata name,
        string calldata symbol,
        address admin
    ) public initializer {
        __ERC20_init(name, symbol);
        Coin = _tokenAddress;
        factoryContract = msg.sender;
        _setupRole(MULTISIGADMIN, admin);
    }

    /* the LenderLoan contract takes permission to spend a particular ERC20 on behalf of the liquidity provider. 
    It sends those token to this smart contract. 
    After sending this contract. The total liquidity is increased.  
    */

    function increaseSupply(uint256 amount) public {
        liquidityMapping[msg.sender] += amount;
    }

    function decreaseSupply(uint256 amount, address sender) public {
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
    ) public {
        require(amount <= getAvailaibleSupply(), "not enough liquidity");
        usedLiquidity.add(amount);
        addBorrower(borrower, block.timestamp + numberOfDays * 1 days, amount);
        _mint(borrower, amount);
    }

    function paybackLoan(uint256 amount) public {
        require(
            amount <= borrowersMapping[msg.sender].amount,
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

        for (uint256 x = 0; x < balanceSupplyCallPending.length; x++) {
            iterator = balanceSupplyCallPending[x];
            BorrowerDetails storage borrower = borrowersMapping[iterator];
            if (borrower.time > block.timestamp) {
                callerProfit += borrower.amount;
                _burn(iterator, borrower.amount);
                balanceSupplyCallPending[x] = balanceSupplyCallPending[
                    balanceSupplyCallPending.length - 1
                ];
                delete balanceSupplyCallPending[
                    balanceSupplyCallPending.length - 1
                ];
                x--;
            }
        }

        uint256 reward = callerProfit.div(100);
        Coin.safeTransfer(msg.sender, reward);
    }

    function addBorrower(
        address recipient,
        uint256 time,
        uint256 amount
    ) internal {
        borrowersMapping[recipient] = BorrowerDetails(time, amount);
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
        super.transferFrom(sender, recipient, amount);
        addBorrower(recipient, borrowersMapping[msg.sender].time, amount);
        return true;
    }
}
