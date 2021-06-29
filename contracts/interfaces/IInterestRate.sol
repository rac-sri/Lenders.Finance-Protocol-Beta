pragma solidity >0.8.0;

import "./IunERC20.sol";

interface IInterestRate {
    function calculatePaymentAmount(
        IUNERC20 tokenProxy,
        uint256 amount,
        uint256 numberOfDays
    ) external returns (uint256, uint256);
}
