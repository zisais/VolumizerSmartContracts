pragma solidity =0.7.6;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Volumizer is IUniswapV3FlashCallback {
    IUniswapV3Pool Pool;
    IERC20 Token;

    address pool;
    address currentUser;
    bool isToken0;
    uint loanAmount;

    constructor(address uniPool) {
        pool = uniPool;
        Pool = IUniswapV3Pool(uniPool);
    }

    function changePool(address uniPool) public {
        pool = uniPool;
        Pool = IUniswapV3Pool(uniPool);
    }

    function start(address token, uint256 amount) public {
        require(token == Pool.token0() || token == Pool.token1(), "Token not in pool");

        Token = IERC20(token);
        uint fee = FullMath.mulDivRoundingUp(amount, Pool.fee(), 1e6);
        uint expectedTotal = amount + fee;
        require(Token.allowance(msg.sender, address(this)) >= expectedTotal, "Contract needs higher allowance for calling address");

        isToken0 = token == Pool.token0() ? true : false;
        loanAmount = amount;

        currentUser = msg.sender;
        uint amount0 = isToken0 ? amount : 0;
        uint amount1 = isToken0 ? 0 : amount;
        
        
        Pool.flash(currentUser, amount0, amount1, abi.encode('0'));
    }

    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external override {
        Token.transferFrom(currentUser, pool, fee0 + fee1 + loanAmount);
    }

}