pragma solidity >0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IDataProvider.sol";

contract DataProvider is IDataProvider {
    uint256 public Ymax;
    uint256 public Ymin;

    mapping(address => mapping(uint256 => bool)) interestPaid;

    function getThePrice(address aggregatorAddress)
        external
        view
        override
        returns (int256)
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
        return price;
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
}
