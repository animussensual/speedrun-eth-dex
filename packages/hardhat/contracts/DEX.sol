pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {

    event Swap(address indexed sender, string from, string to, uint256 fromAmount, uint256 toAmount);
    event Withdraw(address indexed sender, uint256 ethAmount, uint256 tokensAmount);
    event Deposit(address indexed sender, uint256 ethAmount, uint256 tokensAmount);

    IERC20 token;

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    constructor(address token_addr) {
        token = IERC20(token_addr);
    }

    /**
     * Init function provides DEX with initial ETH and token liquidity.
     * For example calling init function with 300 tokens and sending along 1 ETH,
     * that gives us [k = 300 tokens * 1 ETH], basically making 1 ETH to cost 300 tokens

     * @dev Provides initial DEX liquidity
     * @param tokens Initial tokens amount.
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "Already has liquidity");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens));

        return totalLiquidity;
    }

    /*
     * @dev Calculates eth/token price ratio and returns number of eth or tokens based on the ratio.
     * Takes also small fee(997/1000)
     * Price is (how many to swap) * (updated price ratio), fee deducted.
     * @param input_amount Number of tokens to swap.
     * @param input_reserve Total liquidity of input token.
     * @param output_reserve Total liquidity of output token.
     * @returns Amount of input_amount converted to output tokens
     */
    function price(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
        uint256 input_amount_with_fee = input_amount * 997;
        uint256 numerator = input_amount_with_fee * output_reserve;
        uint256 denominator = input_reserve * 1000 + input_amount_with_fee;
        return numerator / denominator;
    }

    /*
     * @dev Swaps ETH to token using CFAMM function for price.
     * @returns Converted tokens amount.
     */
    function ethToToken() public payable returns (uint256) {
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_bought = price(msg.value, address(this).balance - msg.value, token_reserve);
        require(token.transfer(msg.sender, tokens_bought));

        emit Swap(msg.sender, "ETH", "Token", msg.value, tokens_bought);
        return tokens_bought;
    }

    /*
     * @dev Swaps tokens to ETH using CFAMM function for price.
     * @returns Converted ETH amount.
     */
    function tokenToEth(uint256 tokens) public returns (uint256) {
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_bought = price(tokens, token_reserve, address(this).balance);
        (bool sent,) = msg.sender.call{value : eth_bought}("");

        require(sent, "Failed to send user eth.");
        require(token.transferFrom(msg.sender, address(this), tokens));

        emit Swap(msg.sender, "BAL", "ETH", tokens, eth_bought);

        return eth_bought;
    }

    /*
     * @dev Allows user add liquidity to DEX. Liquidity is equally balanced between both tokens.
     * @returns Added liquidity.
     */
    function deposit() public payable returns (uint256) {
        //Amount of ETH before deposit
        uint256 eth_reserve = address(this).balance - msg.value;

        //Amount of tokens before deposit
        uint256 token_reserve = token.balanceOf(address(this));

        //Amount of tokens to deposit
        uint256 token_amount = ((msg.value * token_reserve) / eth_reserve) + 1;

        //Updated liquidity, keeping eth:token:liquidity ratio same
        uint256 liquidity_minted = (msg.value * totalLiquidity) / eth_reserve;

        //Remember liquidity of this user so they can withdraw it later
        liquidity[msg.sender] += liquidity_minted;

        totalLiquidity += liquidity_minted;
        require(token.transferFrom(msg.sender, address(this), token_amount));

        emit Deposit(msg.sender, msg.value, token_amount);
        return liquidity_minted;
    }

    /*
     * @dev Allows user withdraw liquidity from DEX. Both tokens are sent to user based on current liquidity ratio.
     * @returns Amount of both tokens withdrawn.
     */
    function withdraw(uint256 liq_amount) public returns (uint256, uint256) {
        //Total amount of tokens on DEX
        uint256 token_reserve = token.balanceOf(address(this));

        //Total amount of ETH on DEX
        uint256 eth_amount = (liq_amount * address(this).balance) / totalLiquidity;

        //Amount of tokens to withdraw
        uint256 token_amount = (liq_amount * token_reserve) / totalLiquidity;

        liquidity[msg.sender] -= liq_amount;
        totalLiquidity -= liq_amount;

        //Send ETH to user
        (bool sent,) = msg.sender.call{value : eth_amount}("");
        require(sent, "Failed to send user eth.");

        //Send tokens to user
        require(token.transfer(msg.sender, token_amount));

        emit Withdraw(msg.sender, eth_amount, token_amount);

        return (eth_amount, token_amount);
    }

}