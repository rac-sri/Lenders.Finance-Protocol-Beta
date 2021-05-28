pragma solidity ^0.8.0;

interface ILendersFactory {
    function addLiquidity(uint256 amount, address token) external;

    function withdrawLiquidity(uint256 amount, address token) external;

    function createLiquidityContract(address token) external;

    function payInterest() external;

    function issueLoan() external;

    function paybackLoan() external;
}
