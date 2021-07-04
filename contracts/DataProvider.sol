pragma solidity >0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IDataProvider.sol";
import "./interfaces/ILendersFactory.sol";
import "./interfaces/IunERC20.sol";

contract DataProvider is IDataProvider {
    uint256 public Ymax;
    uint256 public Ymin;

    mapping(address => mapping(uint256 => bool)) interestPaid;

    struct Contract {
        address addr;
        string name;
        string symbol;
    }

    struct ContractDetails {
        uint256 liquiidtyAmount;
        uint256 borrowedAmount;
    }

    Contract[] contractList;
    mapping(address => mapping(address => ContractDetails)) userMapping;

    ILendersFactory core;

    function initialize(
        uint256 ymax,
        uint256 ymin,
        ILendersFactory _core
    ) public {
        Ymax = ymax;
        Ymin = ymin;
        core = _core;
    }

    function getUserDetailForGivenContract(address user, address contractAddr)
        public
        view
        returns (ContractDetails memory)
    {
        return userMapping[user][contractAddr];
    }

    // restict access
    function updateStatusIssueLoan(
        address addrUser,
        address contractAddr,
        uint256 amount
    ) external override {
        ContractDetails storage user = userMapping[addrUser][contractAddr];
        user.borrowedAmount = amount;
    }

    function updateStatusLiquidityIncr(
        address addrUser,
        address contractAddr,
        uint256 amount
    ) external override {
        ContractDetails storage user = userMapping[addrUser][contractAddr];
        user.liquiidtyAmount += amount;
    }

    function updateStatusLiquidityDecr(
        address addrUser,
        address contractAddr,
        uint256 amount
    ) external override {
        ContractDetails storage user = userMapping[addrUser][contractAddr];
        user.liquiidtyAmount -= amount;
    }

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

    function getContractAddress(IERC20 token)
        external
        view
        override
        returns (address)
    {
        address proxy = core.returnProxyContract(token);
        return proxy;
    }

    function addContract(
        address token,
        string calldata name,
        string calldata symbol
    ) external override {
        contractList.push(Contract(token, name, symbol));
    }

    function getContracts() external view returns (Contract[] memory) {
        return contractList;
    }

    function returnProxy(IERC20 token) public view returns (address) {
        return core.returnProxyContract(token);
    }

    function getUsedLiquidity(IERC20 token) external view returns (uint256) {
        address proxyAdd = returnProxy(token);
        require(proxyAdd != address(0), "No token created");
        IUNERC20 proxy = IUNERC20(proxyAdd);
        return proxy.getUsedLiquidity();
    }

    function getTotalLiquidity(IERC20 token) external view returns (uint256) {
        address proxyAdd = returnProxy(token);
        require(proxyAdd != address(0), "No token created");
        IUNERC20 proxy = IUNERC20(proxyAdd);
        return proxy.getTotalLiquidity();
    }
}
