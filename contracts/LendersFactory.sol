pragma solidity ^0.8.0;

import "./unERC20.sol";
import "./UnERC20Proxy.sol";
import "./interfaces/ILendersFactory.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendersFactory is ILendersFactory {
    address implementation;
    address admin;

    mapping(IERC20 => address) proxyMapping;

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    function createLiquidityContract(
        address tokenImplementation,
        IERC20 token,
        string calldata name,
        string calldata symbol
    ) external override {
        address proxyContractToken = Clones.clone(implementation);
        UnERC20Proxy initializing = UnERC20Proxy(proxyContractToken);
        address unERC20Address = Clones.clone(tokenImplementation);
        initializing.upgradeTo(unERC20Address);
        UNERC20 unERC20 = UNERC20(unERC20Address);
        unERC20.initialize(token, name, symbol, admin);
        proxyMapping[token] = proxyContractToken;
    }

    function addLiquidity(uint256 amount, IERC20 token) external override {
        // code
    }

    function withdrawLiquidity(uint256 amount, IERC20 token) external override {
        // code
    }

    function issueLoan() external override {
        // code
    }

    function paybackLoan() external override {
        // code
    }

    function payInterest() internal {
        // code
    }
}
