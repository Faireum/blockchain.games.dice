pragma solidity >=0.4.0 <0.6.0;

// * Faireum Dice Game Contract
contract FaireumDice{
    
    // A single bet struct
    struct Bet {
        uint amount;
        uint8 modulo;
        uint8 rollUnder;
        uint40 blockNumber;
        address user;
    }

    mapping (uint => Bet) bets;

    address constant TEST_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint128 public lockedInBets;
    address public owner;
    address public croupier;

    // Constructor. 
    constructor () public {
        owner = msg.sender;
        croupier = TEST_ADDRESS;
    }

    modifier onlyOwner {
        require (msg.sender == owner, "Must be contract owner to invoke this method.");
        _;
    }

    modifier onlyCroupier {
        require (msg.sender == croupier, "Must be croupier to invoke this method.");
        _;
    }

    // Fallback function
    function () public payable {
    }


    function setCroupier(address newCroupier) external onlyOwner {
        croupier = newCroupier;
    }

    function kill() external onlyOwner {
        require (lockedInBets == 0, "Contract can't be destroyed if there are on going bets");
        selfdestruct(owner);
    }

    function placeBet() external payable {
        //TODO
    }

    function settleBet() external onlyCroupier {
        //TODO
    }
   
}