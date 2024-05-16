pragma solidity ^0.7.6;

import "./interfaces/IPancakeV3Pool.sol";
import "./interfaces/IPancakeV3FlashCallback.sol";
import "./interfaces/IERC20Minimal.sol";
import "./libraries/FullMath.sol";
import "./libraries/Ownable.sol";

contract Volumizer is IPancakeV3FlashCallback, Ownable {
    IPancakeV3Pool Pool;
    IERC20Minimal Token;

    address pool;
    address currentUser;
    bool isToken0;
    uint loanAmount;
    uint public thisFee = 1000000000000000;

    receive() external payable { }

    constructor(address uniPool) {
        pool = uniPool;
        Pool = IPancakeV3Pool(uniPool);
    }

    function withdraw() external onlyOwner() {
        address payable _to = msg.sender;
        (bool success, ) = _to.call{value: address(this).balance}("");
    }

    function changePool(address uniPool) public {
        pool = uniPool;
        Pool = IPancakeV3Pool(uniPool);
    }

    function start(address token, uint256 amount) public payable {
        require(msg.value == thisFee, "Fee of 0.001 ETH");
        require(token == Pool.token0() || token == Pool.token1(), "Token not in pool");

        Token = IERC20Minimal(token);
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

    function pancakeV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external override {
        Token.transferFrom(currentUser, pool, fee0 + fee1 + loanAmount);
    }
}