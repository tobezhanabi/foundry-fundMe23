//Get funds from users
// withdraw fund if the owner of contract
// put a minium deposit in usd

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./priceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error fundMe__notOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUMUSD = 5e18;
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUMUSD,
            "Not enough ETH"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] =
            s_addressToAmountFunded[msg.sender] +
            msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSucess, "call failed");
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "not owner");
        // if(msg.sender != i_owner){
        //     revert NotOwner();
        // }
        _;
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    /**
     * Getter Functions
     */

    /**
     * @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() external view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
