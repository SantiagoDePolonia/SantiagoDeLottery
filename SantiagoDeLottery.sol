// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract LotteryDeSantiago {
    mapping(address => uint) private addressToAmount;
    address[] players;
    uint sessionStarted;
    uint private prize = 0;

    address payable private owner;

    constructor() {
        owner = payable(msg.sender);
        sessionStarted = block.timestamp;
    }

    function play() public payable {
        require(msg.value >= 0.00001 ether, "You need to send at least 0.00001 ETH to play!");
        require(msg.value <= 1000 ether, "You need to send no more than 1000 ETH to play!");

        // if a player with specified address played before in the session
        //     then don't add the address to player array
        if(addressToAmount[msg.sender] == 0) {
            players.push(msg.sender);
        }

        addressToAmount[msg.sender] += msg.value;
    }
    
    function result() public {
        require(sessionStarted + 7 days < block.timestamp);

        uint onePercent = prize / 100;
        uint ninetyNinePercent = prize - onePercent;
        
        // withdraw to the owner one percent tax-like share from prize
        owner.transfer(onePercent);

        payToWinner(selectWinner(), ninetyNinePercent);

        resetState();
    }

    function getPrice() view public returns(uint) {
        return prize;
    }

    function selectWinner() private view returns(address) {
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, block.coinbase, block.difficulty, owner)));
        uint winnerFactor = random % prize;
        uint pointer = 0;

        while (addressToAmount[players[pointer]] > winnerFactor) {
            winnerFactor -= addressToAmount[players[pointer]];
            pointer++;
        }

        return players[pointer];
    }

    function payToWinner(address winner, uint winnerPrize) private {
        payable(winner).transfer(winnerPrize);
    }

    function resetState() private {
        prize = 0;
        sessionStarted = block.timestamp;

        for (uint i = players.length - 1; i >= 0; i--) {
            delete addressToAmount[players[i]];
            delete players[i];
        }
    }
}

