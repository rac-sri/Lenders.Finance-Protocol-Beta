pragma solidity >0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// refer https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786

contract UNERC20 is
    ERC20Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MULTISIGADMIN = keccak256("MULTISIG");

    // to store the address of token
    IERC20Upgradeable public Coin;
    address public tokenAddress;
    address private factoryContract;
    uint256 private totalLiquidity;
    uint256 private usedLiquidity;
    address[] private balanceSupplyCallPending;
    mapping(address => uint256) liquidityMapping;
    mapping(address => uint256) borrowersMapping; // time period track
    mapping(address => mapping(address => uint256)) contractInteractions;

    event LiquidityChange(address sender, uint256 amount);

    function initialize(
        address _tokenAddress,
        string calldata name,
        string calldata symbol,
        address admin
    ) external initializer {
        __ERC20_init(name, symbol);
        tokenAddress = _tokenAddress;
        Coin = IERC20Upgradeable(_tokenAddress);
        factoryContract = msg.sender;
        _setupRole(MULTISIGADMIN, admin);
        _setupRole(MULTISIGADMIN, msg.sender);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /* the LenderLoan contract takes permission to spend a particular ERC20 on behalf of the liquidity provider. 
    It sends those token to this smart contract. 
    After sending this contract. The total liquidity is increased.  
    */

    function increaseSupply(uint256 amount, address supplier)
        external
        onlyRole(MULTISIGADMIN)
    {
        liquidityMapping[supplier] += amount;
        totalLiquidity += amount;
    }

    function decreaseSupply(uint256 amount, address sender)
        external
        onlyRole(MULTISIGADMIN)
    {
        uint256 availaibleSupply = getAvailaibleSupply();

        require(
            availaibleSupply >= amount,
            "not enough tokens to available. Please wait for some more time"
        );
        require(
            amount <= liquidityMapping[sender],
            "not enough liquidity provided by the user"
        );

        totalLiquidity = totalLiquidity.sub(amount);
        Coin.safeTransfer(sender, amount);
    }

    function getLoan(
        address borrower,
        uint256 numberOfDays,
        uint256 amount
    ) external onlyRole(MULTISIGADMIN) {
        require(amount <= getAvailaibleSupply(), "not enough liquidity");
        require(
            balanceOf(borrower) == 0,
            "Loan issued once already. Please repay that, then try again"
        );
        usedLiquidity = usedLiquidity.add(amount);
        addBorrower(borrower, block.timestamp + numberOfDays * 1 days);
        _mint(borrower, amount);
    }

    function paybackLoan(uint256 amount, address account)
        external
        onlyRole(MULTISIGADMIN)
    {
        require(
            amount <= balanceOf(account),
            "You weren't given this much liquidity. Please repay your own loan only"
        );

        emit LiquidityChange(account, amount);
        usedLiquidity = usedLiquidity.sub(amount, "amount issue");
        _burn(account, amount);
    }

    function getAvailaibleSupply() public view returns (uint256) {
        return totalLiquidity.sub(usedLiquidity);
    }

    function getUsedLiquidity() public view returns (uint256) {
        return usedLiquidity;
    }

    function balanceSupply()
        external
        onlyRole(MULTISIGADMIN)
        returns (uint256)
    {
        uint256 callerProfit = 0;
        address iterator;

        for (uint256 x = 0; x < balanceSupplyCallPending.length; ) {
            iterator = balanceSupplyCallPending[x];
            uint256 borrowerTime = borrowersMapping[iterator];
            uint256 balance = balanceOf(iterator);
            if (iterator != address(0) && borrowerTime < block.timestamp) {
                callerProfit += balance;
                _burn(iterator, balance);
                balanceSupplyCallPending[x] = balanceSupplyCallPending[
                    balanceSupplyCallPending.length - 1
                ];
                delete balanceSupplyCallPending[
                    balanceSupplyCallPending.length - 1
                ];
                borrowersMapping[iterator] = 0;
            } else {
                x++;
            }
        }

        uint256 reward = callerProfit.div(10);

        return reward;
    }

    function addBorrower(address recipient, uint256 time) internal {
        borrowersMapping[recipient] = time;
        balanceSupplyCallPending.push(recipient);
    }

    // Overridden functions
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (AddressUpgradeable.isContract(recipient)) {
            _transfer(_msgSender(), recipient, amount);
            contractInteractions[msg.sender][recipient] += amount;
            return true;
        } else return false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (AddressUpgradeable.isContract(recipient)) {
            super.transferFrom(sender, recipient, amount);
            contractInteractions[msg.sender][recipient] += amount;
            return true;
        } else return false;
    }

    function getLiquidityByAddress(address lp) public view returns (uint256) {
        return liquidityMapping[lp];
    }

    function getTotalLiquidity() public view returns (uint256) {
        return totalLiquidity;
    }

    function getBorrowerDetails(address borrower)
        public
        view
        returns (uint256, uint256)
    {
        return (borrowersMapping[borrower], balanceOf(borrower));
    }

    function getBalanceSupplyCallPending()
        public
        view
        returns (address[] memory)
    {
        return balanceSupplyCallPending;
    }

    function getTokenAddress() public view returns (IERC20Upgradeable) {
        return Coin;
    }
}
