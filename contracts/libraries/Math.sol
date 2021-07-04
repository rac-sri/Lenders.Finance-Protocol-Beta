pragma solidity >0.8.0;

/*
#    Copyright (C) 2017  alianse777
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

contract Math {
    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 n = x / 2;
        uint256 lstX = 0;
        while (n != lstX) {
            lstX = n;
            n = (n + x / n) / 2;
        }
        return uint256(n);
    }

    function mexp(
        uint256 x,
        uint256 k,
        uint256 m
    ) internal pure returns (uint256 r) {
        r = 1;
        for (uint256 s = 1; s <= k; s *= 2) {
            if (k & s != 0) r = mulmod(r, x, m);
            x = mulmod(x, x, m);
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        if (x < 0) {
            return uint256(-x);
        }
        return uint256(x);
    }

    function u_pow(uint256 x, uint256 p) internal pure returns (uint256) {
        if (p == 0) return 1;
        if (p % 2 == 1) {
            return u_pow(x, p - 1) * x;
        } else {
            return u_pow(x, p / 2) * u_pow(x, p / 2);
        }
    }

    function pow(int256 x, uint256 p) internal pure returns (int256) {
        int256 r = int256(u_pow(abs(x), p));
        if (p % 2 == 1) {
            return -1 * r;
        }
        return r;
    }
}
