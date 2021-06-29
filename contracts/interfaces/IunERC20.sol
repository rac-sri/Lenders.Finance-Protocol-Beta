pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUNERC20 {
    function initialize(
        address _tokenAddress,
        string calldata name,
        string calldata symbol,
        address admin
    ) external;

    function increaseSupply(uint256 amount, address supplier) external;

    function decreaseSupply(uint256 amount, address sender) external;

    function getLoan(
        address borrower,
        uint256 numberOfDays,
        uint256 amount
    ) external;

    function paybackLoan(uint256 amount, address account) external;

    function balanceSupply() external returns (uint256);

    function getUsedLiquidity() external view returns (uint256);

    function getTotalLiquidity() external view returns (uint256);
}
