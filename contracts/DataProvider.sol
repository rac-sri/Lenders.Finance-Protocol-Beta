pragma solidity >0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IDataProvider.sol";
import "./interfaces/IunERC20.sol";

contract DataProvider is IDataProvider {
    uint256 public Ymax;
    uint256 public Ymin;

    mapping(address => mapping(uint256 => bool)) interestPaid;

    function getThePrice(address aggregatorAddress)
        external
        view
        override
        returns (uint256)
    {
        AggregatorV3Interface priceFeed =
            AggregatorV3Interface(aggregatorAddress);
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return 0;
    }

    function getInterestPaidStatus(address addr, uint256 amount)
        external
        view
        override
        returns (bool)
    {
        return interestPaid[addr][amount];
    }

    function setInterestPaidStatus(
        address addr,
        uint256 amount,
        bool status
    ) external override {
        interestPaid[addr][amount] = status;
    }

    function getValuesForInterestCalculation(IUNERC20 tokenAddress)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 B = tokenAddress.getUsedLiquidity();
        uint256 T = tokenAddress.getTotalLiquidity();

        return (Ymax, Ymin, B, T);
    }
}
