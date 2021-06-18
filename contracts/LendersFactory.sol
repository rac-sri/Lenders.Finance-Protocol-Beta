pragma solidity >0.8.0;

// create interfaces for both these contract.
import "./interfaces/IunERC20.sol";
import "./UnERC20Proxy.sol";

import "./interfaces/ILendersFactory.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LendersFactory is ILendersFactory {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address proxyImplementation;
    address tokenImplementation;
    address admin;

    mapping(IERC20 => address) proxyMapping;
    mapping(address => mapping(uint256 => bool)) interestPaid;

    constructor(address _implementation, address _tokenImplementation) {
        proxyImplementation = _implementation;
        tokenImplementation = _tokenImplementation;
        admin = msg.sender;
    }

    event LiquidityAdded(address sender, IERC20 token, uint256 amount);

    function createLiquidityContract(
        address token,
        string calldata name,
        string calldata symbol
    ) external override {
        address payable proxyContractToken =
            payable(Clones.clone(proxyImplementation));
        UnERC20Proxy initializing = UnERC20Proxy(proxyContractToken);
        address unERC20Address = Clones.clone(tokenImplementation);
        IUNERC20 unERC20 = IUNERC20(unERC20Address);
        unERC20.initialize(token, name, symbol, admin);

        initializing.upgradeTo(unERC20Address);

        proxyMapping[IERC20(token)] = proxyContractToken;
    }

    function addLiquidity(uint256 amount, IERC20 token) external override {
        require(
            proxyMapping[token] != address(0),
            "Token Contract Doesn't exist"
        );
        // The token needs to have approval first
        address implementation = getContractAddress(token);
        token.transferFrom(msg.sender, implementation, amount);
        IUNERC20 implementationContract = IUNERC20(implementation);
        implementationContract.increaseSupply(amount, msg.sender);

        //    // gas inefficient
        //     implementation.call(
        //         abi.encodeWithSignature(
        //             "increaseSupply(uint256,address)",
        //             amount,
        //             msg.sender
        //         )
        //     );

        emit LiquidityAdded(msg.sender, token, amount);
    }

    function withdrawLiquidity(uint256 amount, IERC20 token) external override {
        require(
            proxyMapping[token] != address(0),
            "Token Contract Doesn't exist"
        );

        IUNERC20 liquidityContract = IUNERC20(getContractAddress(token));

        liquidityContract.decreaseSupply(amount, msg.sender);
    }

    function getContractAddress(IERC20 token) public view returns (address) {
        address payable tokenAddress = payable(proxyMapping[token]);
        UnERC20Proxy proxyContract = UnERC20Proxy(tokenAddress);
        address liquidityContract = (proxyContract.getImplementation());
        return liquidityContract;
    }

    function issueLoan(
        IERC20 token,
        uint256 numberOfDays,
        uint256 amount
    ) external override {
        IUNERC20 liquidityContract = IUNERC20(getContractAddress(token));
        require(interestPaid[msg.sender][amount] == true, "Interest Not Paid");
        liquidityContract.getLoan(msg.sender, numberOfDays, amount);
        interestPaid[msg.sender][amount] = false;
    }

    function paybackLoan(IERC20 token, uint256 amount) external override {
        IUNERC20 liquidityContract = IUNERC20(getContractAddress(token));
        liquidityContract.paybackLoan(amount, msg.sender);
    }

    function balanceSupply(IERC20 token) external returns (uint256) {
        IUNERC20 liquidityContract = IUNERC20(getContractAddress(token));

        uint256 reward = liquidityContract.balanceSupply();
        // replace with payment to the caller later on
        return reward;
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
        pure
        returns (uint256)
    {
        return interestPercentage().mul(amount).div(100);
    }

    function interestPercentage() public pure returns (uint256) {
        // think of an algo based on liquidity available vs loan taken
        return 1;
    }

    function returnProxyContract(IERC20 tokenAddress)
        public
        view
        returns (address)
    {
        return proxyMapping[tokenAddress];
    }
}
