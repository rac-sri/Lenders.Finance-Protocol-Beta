pragma solidity >0.8.0;

import "./libraries/Math.sol";
import "./interfaces/IDataProvider.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract InterestRateStatergy is Math {
    using SafeMath for uint256;
    IDataProvider dataProvider;
    uint256 securityPercentage;

    function initialize(IDataProvider addr, uint256 _securityPercentage)
        public
    {
        dataProvider = addr;
        securityPercentage = _securityPercentage;
    }

    function calculatePaymentAmount(uint256 amount, uint256 numberOfDays)
        external
        returns (uint256, uint256)
    {
        uint256 interest = calculateInterest(amount);
        uint256 security = calculateSecurity(amount, numberOfDays);

        return (interest, security);
    }

    // need to redesign to accomodate decimals
    function calculateInterest(uint256 amount) internal returns (uint256) {
        // y = ymax - sqrt(ymax^2 - (x^2 * (ymax -ymin)^2 - ymin^2 + 2ymaxymin))
        (uint256 ymax, uint256 ymin, uint256 B, uint256 T) =
            dataProvider.getValuesForInterestCalculation();

        uint256 x = B.add(amount).div(B.add(amount).add(T));
        uint256 sqFactor = x.mul(x).mul((ymax - ymin).mul(ymax - ymin));

        uint256 y =
            ymax.sub(
                Math.sqrt(
                    ymax.mul(ymax).sub(sqFactor).sub(ymin.mul(ymin)).add(
                        (ymax).mul(ymin).mul(2)
                    )
                )
            );

        return y;
    }

    function calculateSecurity(uint256 amount, uint256 numberOfDays)
        internal
        returns (uint256)
    {
        return amount.mul(securityPercentage).mul(numberOfDays);
    }
}
