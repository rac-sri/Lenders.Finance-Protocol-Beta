pragma solidity >0.8.0;

// create interfaces for both these contract.
import "./unERC20.sol";
import "./UnERC20Proxy.sol";

import "./interfaces/ILendersFactory.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LendersFactory is ILendersFactory {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address implementation;
    address admin;

    mapping(IERC20 => address) proxyMapping;
    mapping(address => mapping(uint256 => bool)) interestPaid;

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    event LiquidityAdded(address sender, IERC20 token, uint256 amount);

    function createLiquidityContract(
        address tokenImplementation,
        IERC20 token,
        string calldata name,
        string calldata symbol
    ) external override {
        address payable proxyContractToken =
            payable(Clones.clone(implementation));
        UnERC20Proxy initializing = UnERC20Proxy(proxyContractToken);
        address unERC20Address = Clones.clone(tokenImplementation);
        initializing.upgradeTo(unERC20Address);

        UNERC20 unERC20 = UNERC20(unERC20Address);
        unERC20.initialize(token, name, symbol, admin);
        proxyMapping[token] = proxyContractToken;
    }

    function addLiquidity(uint256 amount, IERC20 token) external override {
        require(
            proxyMapping[token] != address(0),
            "Token Contract Doesn't exist"
        );
        // The token needs to have approval first
        token.transferFrom(msg.sender, proxyMapping[token], amount);
        emit LiquidityAdded(msg.sender, token, amount);
    }

    function withdrawLiquidity(uint256 amount, IERC20 token) external override {
        require(
            proxyMapping[token] != address(0),
            "Token Contract Doesn't exist"
        );

        UNERC20 liquidityContract = getContractAddress(token);

        liquidityContract.decreaseSupply(amount, msg.sender);
    }

    function getContractAddress(IERC20 token) public view returns (UNERC20) {
        address payable tokenAddress = payable(proxyMapping[token]);
        UnERC20Proxy proxyContract = UnERC20Proxy(tokenAddress);
        UNERC20 liquidityContract = UNERC20(proxyContract.getImplementation());
        return liquidityContract;
    }

    function issueLoan(
        IERC20 token,
        uint256 numberOfDays,
        uint256 amount
    ) external override {
        UNERC20 liquidityContract = getContractAddress(token);
        require(interestPaid[msg.sender][amount] == true, "Interest Not Paid");
        liquidityContract.getLoan(msg.sender, numberOfDays, amount);
        interestPaid[msg.sender][amount] = false;
    }

    function paybackLoan(IERC20 token, uint256 amount) external override {
        UNERC20 liquidityContract = getContractAddress(token);
        liquidityContract.paybackLoan(amount, msg.sender);
    }

    function payInterest(uint256 amount) public payable {
        uint256 interest = calculateInterestAmount(amount);
        require(
            msg.value == interest,
            "Not the entire interest amount deposited"
        );
        interestPaid[msg.sender][amount] = true;
    }

    function calculateInterestAmount(uint256 amount)
        public
        view
        returns (uint256)
    {
        return payInterest().mul(amount).div(100);
    }

    function payInterest() public view returns (uint256) {
        // think of an algo based on liquidity available vs loan taken
        return 10;
    }
}
