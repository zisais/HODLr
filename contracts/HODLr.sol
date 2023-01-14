// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Interfaces/IERC20.sol";
import "./Utils/Context.sol";

contract HODLr is Context {
    
    struct TokenDeposit {
        address[] tokens;
        uint[] values;
        uint unlockTime;
        uint claimed;
    }

    struct EthDeposit {
        uint value;
        uint unlockTime;
        uint claimed;
    }

    mapping(bytes32 => TokenDeposit) public _tokenDeposits;
    mapping(bytes32 => EthDeposit) public _ethDeposits;
    mapping(bytes32 => bool) public _usedHashes;

    function getHash(string memory claimPassword) external pure returns(bytes32) {
        bytes32 theHash = keccak256(abi.encodePacked(claimPassword));
        return(theHash);
    }
    
    function _tokenDeposit(TokenDeposit memory deposit, bytes32 claimHash) external {        
        require(!_usedHashes[claimHash], "Previously used password");

        for (uint i=0;i<deposit.tokens.length;i++) {
            if (IERC20(deposit.tokens[i]).allowance(_msgSender(), address(this)) < deposit.values[i]) {
                revert("This contract needs allowance to one or more of the entered tokens");
            }
        }
        
        TokenDeposit storage depo = _tokenDeposits[claimHash];
        depo.tokens = deposit.tokens;
        depo.values = deposit.values;
        depo.unlockTime = deposit.unlockTime;
        depo.claimed = 0;

        for (uint i=0;i<depo.tokens.length;i++) {
            IERC20(depo.tokens[i]).transferFrom(_msgSender(), address(this), depo.values[i]);
        }

        _usedHashes[claimHash] = true;
    }

    function _ethDeposit(uint _unlockTime, bytes32 claimHash) external payable {
        require(!_usedHashes[claimHash], "Password used before");
        EthDeposit storage depo = _ethDeposits[claimHash];
        depo.value = msg.value;
        depo.unlockTime = _unlockTime;
        depo.claimed = 0;

        _usedHashes[claimHash] = true;
    }

    function withdrawTokens(string memory claimPassword) external {
        bytes32 claimHash = keccak256(abi.encodePacked(claimPassword));
        require(_tokenDeposits[claimHash].tokens.length > 0, "Deposit doesn't exist");
        require(_tokenDeposits[claimHash].unlockTime < block.timestamp, "Deposit still locked");
        require(_tokenDeposits[claimHash].claimed == 0, "Deposit already claimed");
        _tokenDeposits[claimHash].claimed = 1;
        TokenDeposit memory depo = _tokenDeposits[claimHash];

        for (uint i=0;i<depo.tokens.length;i++) {
            IERC20(depo.tokens[i]).transfer(_msgSender(), depo.values[i]);
        }
    }

    function withdrawEth(string memory claimPassword) external {
        bytes32 claimHash = keccak256(abi.encodePacked(claimPassword));
        require(_ethDeposits[claimHash].value > 0, "Deposit doesn't exist");
        require(_ethDeposits[claimHash].unlockTime < block.timestamp, "Deposit still locked");
        require(_ethDeposits[claimHash].claimed == 0, "Deposit already claimed");
        _ethDeposits[claimHash].claimed = 1;

        (bool success, ) =_msgSender().call{value:_ethDeposits[claimHash].value}("");
        require(success);
    }
}