pragma solidity >0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract DataProvider {
    constructor() {}

    function getThePrice(address aggregatorAddress)
        public
        view
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

    function calculatePaymentAmount() external {
        // function calculate interest
        // calculate security
    }

    function calculateInterest() internal {}

    function calculateSecurity() internal {}
}
