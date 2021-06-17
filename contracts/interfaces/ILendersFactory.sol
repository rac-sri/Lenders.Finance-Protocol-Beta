pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILendersFactory {
    function addLiquidity(uint256 amount, IERC20 token) external;

    function withdrawLiquidity(uint256 amount, IERC20 token) external;

    function createLiquidityContract(
        address token,
        string calldata name,
        string calldata symbol
    ) external;

    function paybackLoan(IERC20 token, uint256 amount) external;

    function issueLoan(
        IERC20 token,
        uint256 numberOfDays,
        uint256 amount
    ) external;
}
