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
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getContractAddress(IERC20 token) external view returns (address);

    function addContract(
        address token,
        string calldata name,
        string calldata symbol
    ) external;

    function updateStatusIssueLoan(
        address addrUser,
        address contractAddr,
        uint256 amount
    ) external;

    function updateStatusLiquidityIncr(
        address addrUser,
        address contractAddr,
        uint256 amount
    ) external;

    function updateStatusLiquidityDecr(
        address addrUser,
        address contractAddr,
        uint256 amount
    ) external;
}
