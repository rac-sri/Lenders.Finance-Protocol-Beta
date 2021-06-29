pragma solidity >0.8.0;

import "./IunERC20.sol";

interface IDataProvider {
    function getThePrice(address) external returns (uint256);

    function getInterestPaidStatus(address, uint256)
        external
        view
        returns (bool);

    function setInterestPaidStatus(
        address addr,
        uint256 amount,
        bool status
    ) external;

    function getValuesForInterestCalculation(IUNERC20)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}
