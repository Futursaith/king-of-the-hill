// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "./Ownable.sol";

contract KingOfTheHill is Ownable {
    using Address for address payable;

    address private _potOwner;
    uint256 private _pot;
    uint256 private _blockNumber;
    uint256 private constant NB_BLOCK_PER_TURN = 10;

    event Outbided(address indexed account, uint256 pot);
    event IsNewTurn(bool indexed isNewTurn);

    constructor(address owner_) payable Ownable(owner_) {
        require(msg.value > 0, "KingOfTheHill (constructor) : Need a seed");
        _potOwner = owner_;
        _pot = msg.value;
        _blockNumber = block.number;
    }

    receive() external payable {
        revert(
            "You cannot send ether directly to this smart-contract, use outbid instead"
        );
    }

    fallback() external {}

    function outbid() public payable {
        if (block.number - _blockNumber >= NB_BLOCK_PER_TURN) {
            _newTurn();
            emit IsNewTurn(true);
        } else {
            emit IsNewTurn(false);
        }
        require(
            msg.value >= 2 * _pot,
            "KingOfTheHill (outbid) : You have to send 2 times the pot value"
        );
        require(
            msg.sender != _potOwner,
            "KingOfTheHill (outbid) : You cannot outbid on your own bid"
        );
        uint256 diff = msg.value - 2 * _pot;
        _pot += 2 * _pot;
        _potOwner = msg.sender;
        _blockNumber = block.number;
        emit Outbided(_potOwner, _pot);
        payable(msg.sender).sendValue(diff);
    }

    function _newTurn() private {
        uint256 potOwnerReward = (80 * _pot) / 100;
        uint256 ownerReward = (10 * _pot) / 100;
        _pot -= potOwnerReward;
        _pot -= ownerReward;
        payable(_potOwner).sendValue(potOwnerReward);
        payable(owner()).sendValue(ownerReward);
        _potOwner = address(0);
    }

    function potOwner() public view returns (address) {
        return _potOwner;
    }

    function pot() public view returns (uint256) {
        return _pot;
    }

    function blockNumber() public view returns (uint256) {
        return _blockNumber;
    }

    function currentBlock() public view returns (uint256) {
        return block.number;
    }
}
