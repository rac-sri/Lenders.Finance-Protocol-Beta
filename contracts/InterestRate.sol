pragma solidity >0.8.0;

import "./libraries/Math.sol";
import "./libraries/WadRayMaths.sol";
import "./interfaces/IDataProvider.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IunERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract InterestRateStatergy is Math {
    using SafeMath for uint256;

    using WadRayMath for uint256;

    uint256 internal constant WAD = 1e18;

    IDataProvider dataProvider;
    uint256 securityPercentage;

    function initialize(IDataProvider addr, uint256 _securityPercentage)
        public
    {
        dataProvider = addr;
        securityPercentage = _securityPercentage;
    }

    function calculatePaymentAmount(
        IERC20 token,
        uint256 amount,
        uint256 numberOfDays
    ) external view returns (uint256, uint256) {
        IUNERC20 tokenProxy = IUNERC20(dataProvider.getContractAddress(token));
        uint256 interest = calculateInterest(amount, tokenProxy);
        uint256 security = calculateSecurity(amount, numberOfDays);
        return (interest, security);
    }

    // need to redesign to accomodate decimals
    function calculateInterest(uint256 amount, IUNERC20 tokenProxy)
        internal
        view
        returns (uint256)
    {
        // y = ymax - sqrt(ymax^2 - (x^2 * (ymax -ymin)^2 - ymin^2 + 2ymaxymin))
        (uint256 ymax, uint256 ymin, uint256 B, uint256 T) =
            dataProvider.getValuesForInterestCalculation(tokenProxy);

        // uint256 ymax = 10;
        // uint256 ymin = 5;
        // uint256 B = 0;
        // uint256 T = 4000;

        // ymax = ymax * WAD;
        // ymin = ymin * WAD;
        // B = B * WAD;
        // T = T * WAD;
        // amount = amount * WAD;

        // uint256 x = B.add(amount).wadDiv(T);
        // uint256 sqFactor =
        //     x.wadMul(x).wadMul((ymax - ymin).wadMul(ymax - ymin));

        // uint256 ymax2 = ymax.wadMul(ymax);
        // uint256 ymin2 = ymin.wadMul(ymin);
        // uint256 twoyminymax = ymin.wadMul(ymax).wadMul(2);

        // uint256 added = ymax2.add(ymin2).add(twoyminymax);
        // uint256 sqroot = sqrt(added.add(sqFactor));

        // uint256 y = ymax.sub(sqroot);
        // y = y / WAD;

        uint256 x = (B.add(amount)).div(T);
        uint256 m = (ymax.sub(ymin));

        uint256 y = (m.mul(x)).add(ymin);
        return y;
    }

    function calculateSecurity(uint256 amount, uint256 numberOfDays)
        internal
        view
        returns (uint256)
    {
        return amount.mul(securityPercentage).mul(numberOfDays).div(100);
    }
}
