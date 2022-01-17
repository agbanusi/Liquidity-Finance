
// File: @uniswap/v2-periphery/contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-periphery/contracts/libraries/SafeMath.sol

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol

pragma solidity >=0.5.0;



library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/swaphelper.sol







pragma solidity <= 0.8.4;


interface IUniswapV2Factory1 {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface VaultHelper{
    function submitTransaction(address destination, uint value, bytes calldata data) external returns (uint transactionId);
    function executeTransaction(uint transactionId) external;
}


interface IUniswapV2Router1 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external payable returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external payable returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router is IUniswapV2Router1 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface Token {
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function balanceOf(address guy) external view returns (uint);
}

// 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
contract Uniswap{
    IUniswapV2Router uniswap;

    constructor() public{
        uniswap =  IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);     // polygon mainnet
        // uniswap =  IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);     // Matic mainnet
    }
}

contract UniswapFactory{
    IUniswapV2Factory1 uniswapFactory;

    constructor() public{
        uniswapFactory =  IUniswapV2Factory1(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);     // Polygon Mainnet
        // uniswap =  IUniswapV2Router(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);     // Matic mainnet
    }
}

contract LiquidityPortfolio is Uniswap, UniswapFactory{
    address owner;
    mapping (address=>uint) EthTreks;
    mapping (address=>uint) DaiTreks;
    address UniswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address dai;
    address weth;
    address matic;
    address usdc;
    address public factory;
    struct UserPair {
        address pairAddress;
        uint sharePercentage;
        uint totalAmount;
    }
    
    constructor(address _weth, address _matic, address _dai, address _usdc, address _factory) public{
        owner = msg.sender;
        weth = _weth;
        dai = _dai;
        matic = _matic;
        usdc = _usdc;
        factory = _factory;
    }

    receive() external payable{
        revert();
    }
    


   function getAvgPriceForTokens(uint amountIn, address[] memory path) public view returns(uint){
       uint[] memory amount = uniswap.getAmountsOut(amountIn, path);
       return amount[amount.length-1];
   }
    
    /**
    Create a pool using the addresses of two tokens
    @ params tokenA first token address, tokenB second token address address pair = UniswapV2Library.pairFor(factory, token, WETH);
     */
    function createPairToken(
        address tokenA,
        address tokenB
    )external {
        uniswapFactory.createPair(tokenA, tokenB);
    }
    

    function getPairs(uint num) view private returns (address pair){
        return uniswapFactory.allPairs(num);
    }
    

    /**
    Get the pool exchange address of Eth/Treks
    */
    function getPairTokens(address token1, address token2) view public returns (address pair){
        return uniswapFactory.getPair(token1, token2);
    }
    

    function removeLiquidityTokens(
        address token1,
        address token2,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )public {
        deadline = block.timestamp  + deadline;   
                
        uniswap.removeLiquidity(
            token1,
            token2,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }


    function addLiquidityTokens(
        address token1,
        address token2,
        uint amountToken1Desired,
        uint amountToken2Desired,
        uint amountToken1Min,
        uint amountToken2Min,
        uint deadline
        ) external{
        deadline = block.timestamp  + deadline;   
        Token tokens1 = Token(token1);
        Token tokens2 = Token(token2);
        //address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        require(tokens1.transferFrom(msg.sender, address(this), amountToken2Desired), 'transferFrom failed from contract.');
        require(tokens1.approve(UniswapRouter, amountToken2Desired), 'approve failed from contract.');
        require(tokens2.transferFrom(msg.sender, address(this), amountToken1Desired), 'transferFrom failed from contract.');
        require(tokens2.approve(UniswapRouter, amountToken1Desired), 'approve failed from contract.');
        
        uniswap.addLiquidity(
            token1,
            token2,
            amountToken1Desired,
            amountToken2Desired,
            amountToken1Min,
            amountToken2Min,
            msg.sender,
            deadline
        );
        
        // refund leftover Token to user
        tokens1.transfer(msg.sender, tokens1.balanceOf(address(this)) );

        // refund leftover Token to user
        tokens2.transfer(msg.sender, tokens2.balanceOf(address(this)) );
    }
    

    function findBestPair  (address token1, address token2) internal view returns (address[] memory){
        uint multiplier = 10**18;
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        
        // try direct pair
        uint result = getAvgPriceForTokens(1*multiplier, path);
        
        if(result > 0){
            return path;
        }
        path = new address[](3);
        
        //try Eth
        path[0] = token1;
        path[1] = weth;
        path[2] = token2;
        
        result = getAvgPriceForTokens(1*multiplier, path);
        if(result >0){
            return path;
        }
        
        // try usdc
        path[1] = usdc;
        result = getAvgPriceForTokens(1*multiplier, path);
        if(result >0){
            return path;
        }
        
        // try dai
        path[1] = dai;
        result = getAvgPriceForTokens(1*multiplier, path);
        if(result >0){
            return path;
        } 
        
        //try matic
        path[1] = dai;
        result = getAvgPriceForTokens(1*multiplier, path);
        if(result >0){
            return path;
        }
        
        return new address[](0);
    }
    
    function getLiquidity(address token1, address token2) internal view returns (uint, uint, address){
        address pair = UniswapV2Library.pairFor(factory, token1, token2);
        if (pair != 0x0000000000000000000000000000000000000000){
            uint balance = IUniswapV2Pair(pair).balanceOf(msg.sender);
            uint total = IUniswapV2Pair(pair).totalSupply();
            return (balance, total, pair);
        }
        return (0,0, pair);
    }
    
    function totalUserLiquidity () internal view returns(UserPair[] memory){
        UserPair[] memory allLiquidity;
        address[2][4] memory pairs = [[dai, weth], [weth, usdc], [weth, matic], [matic, dai] ];
        for (uint i=0; i<pairs.length; i++){
            address[2] memory pair = pairs[i];
            (uint balance, uint total, address pairAddress) = getLiquidity(pair[0], pair[1]);
            UserPair memory result = UserPair(pairAddress, balance, total);
            allLiquidity[i] = result;
        }
        
        return allLiquidity;
    }
    
    function addLiquidityWithOneToken(
        address token1,
        address token2,
        uint amountToken1Desired,
        uint amountToken1Min,
        uint deadline
        ) external{
        deadline = block.timestamp  + deadline;   
        Token tokens1 = Token(token1);
        Token tokens2 = Token(token2);
        require(tokens1.transferFrom(msg.sender, address(this), amountToken1Desired), 'transferFrom failed from contract.');
        require(tokens1.approve(UniswapRouter, amountToken1Desired), 'approve failed from contract.');
        
        address[] memory path = findBestPair(token1, token2);
        if(path.length > 0){
            
            uniswap.swapExactTokensForTokens(
                tokens1.balanceOf(address(this)) / 2,
                tokens1.balanceOf(address(this)) / 2,
                path,
                address(this),
                200
            );
            
            require(tokens2.approve(UniswapRouter, tokens2.balanceOf(address(this)) ), 'approve failed from contract.');
        
            uniswap.addLiquidity(
                token1,
                token2,
                amountToken1Desired,
                tokens2.balanceOf(address(this)),
                amountToken1Min,
                tokens2.balanceOf(address(this)),
                msg.sender,
                deadline
            );
        }
        
        // refund leftover/unused Token to user
        tokens1.transfer(msg.sender, tokens1.balanceOf(address(this)) );

        // refund leftover/unused Token to user
        tokens2.transfer(msg.sender, tokens2.balanceOf(address(this)) );
    }


    function fastSwapExactTokensForTokensWithAvailablePair(
        //uint amountOut,
        uint amountIn,
        address token1,
        address token2,
        uint deadline
    ) public returns(bool){
        deadline = block.timestamp  + deadline;
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;

        uint[] memory amountsOut = uniswap.getAmountsOut(amountIn, path);
        Token tokens = Token(token1);
        require(tokens.transferFrom(msg.sender, address(this), amountIn),  'transferFrom failed from contract.');
        require(tokens.approve(UniswapRouter, amountIn+10), 'approve failed from contract.');

        uniswap.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountsOut[1],
            path,
            msg.sender,
            deadline
        );

        // refund leftover Token to user
        tokens.transfer(msg.sender, tokens.balanceOf(address(this)) );
        return true;
    }

    function miniOut(uint out1, uint out2) private pure returns(uint out){
        if(out1 <= out2){
            return out1;
        }else{
            return out2;
        }
    }

    function fastSwapExactTokenForTokensWithBestPath(
        //uint amountOut,
        uint amountIn,
        address token1,
        address token2,
        uint deadline
    ) public{
        deadline = block.timestamp  + deadline;
        //path[0] = token2;
        
        Token tokens = Token(token1);
        Token tokens2 = Token(weth);
        require(tokens.transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed from contract.');
        require(tokens.approve(UniswapRouter, amountIn), 'approve failed from contract.');

        address[] memory path = findBestPair(token1, token2);
        if(path.length > 0){
            uint[] memory amountsOut = uniswap.getAmountsOut(amountIn, path);

            uniswap.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                miniOut(amountsOut[1], amountsOut[amountsOut.length-1]),
                path,
                msg.sender,
                deadline
            );
        }
        
        // refund leftover Token to user
        tokens.transfer(msg.sender, tokens.balanceOf(address(this)) );
        tokens2.transfer(msg.sender, tokens2.balanceOf(address(this)) );
    }

    function fastSwapExactTokenForTokensWithArbitraryPath(
        uint amountIn,
        address token1,
        address token2,
        address middleToken,
        uint deadline
    ) public{
        deadline = block.timestamp  + deadline;
        
        address[] memory path = new address[](3);

        Token tokens = Token(token1);
        Token tokens2 = Token(middleToken);
        require(tokens.transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed from contract.');
        require(tokens.approve(UniswapRouter, amountIn), 'approve failed from contract.');

        path[1] = middleToken;
        path[0] = token1;
        path[2] = token2;
        uint[] memory amountsOut = uniswap.getAmountsOut(amountIn, path);

        uniswap.swapExactTokensForTokens(
            amountIn,
            miniOut(amountsOut[1], amountsOut[amountsOut.length-1]),
            path,
            msg.sender,
            deadline
        );
        // refund leftover Token to user
        tokens.transfer(msg.sender, tokens.balanceOf(address(this)) );
        tokens2.transfer(msg.sender, tokens2.balanceOf(address(this)) );
    }

    function saveLiquidityInVault(address vaultAddress, address token1, address token2, uint percentage)public{
        require (token1 != token2, "Pair of similar tokens not allowed");
        address[2][4] memory pairs = [[dai, weth], [weth, usdc], [weth, matic], [matic, dai] ];
        address [2] memory pair = [token1, token2];
        bool checked = false;

        for(uint i=0; i<pairs.length; i++){
            address [2] memory pairer = pairs[i];
            if((pairer[0] == pair[0] || pairer[0] == pair[1]) && (pairer[1] == pair[0] || pairer[1] == pair[1])){
                checked = true;
                break;
            }
        }

        if(checked){
            (uint balance, uint total, address pairAddress) = getLiquidity(pair[0], pair[1]);
            Token pairAdd = Token(pairAddress);
            uint share = (percentage*balance)/10000;  //2 dp *100
            (bool success) = pairAdd.approve(address(this), share);
            require(pairAdd.transferFrom(msg.sender, address(this), share), "transferFrom failed from contract, check approval and allowance.");
            // VaultHelper vault = VaultHelper(vaultAddress);
            pairAdd.transfer(vaultAddress, pairAdd.balanceOf(address(this)) );
        }
    }

    function checkLiquidityValue(address[2] memory pair)public view returns (uint){
        (uint balance, uint total, address pairAddress) = getLiquidity(pair[0], pair[1]);
        Token pairAdd = Token(pair[0]);
        uint val = pairAdd.balanceOf(pairAddress);
        uint share = (balance/total) * val;
        address[] memory combine;
        combine[0]= pair[0];
        combine[1] = usdc;
        uint price = getAvgPriceForTokens(1, combine);
        return price;
    }
    
    function TransferLiquidity(address token1, address token2, address recipient, uint percentage) public{
        address [2] memory pair = [token1, token2];
        (uint balance, uint total, address pairAddress) = getLiquidity(pair[0], pair[1]);
        Token pairAdd = Token(pairAddress);
        uint share = (percentage*balance)/10000;
        require(pairAdd.transfer(recipient, share), "transfer to recipient failed");
    }

    // function ExchangeLiquidity(){

    // }
    // function borrowAssetsWithLiquidity(address ){
    //     // borrow asset with liquidity : two ways
    //     // borrow asset that is same token as at least one of the token in liquidity
    //     // borrow asset that is directly convertible with at least one token in your liquidity
        


    // }
}


