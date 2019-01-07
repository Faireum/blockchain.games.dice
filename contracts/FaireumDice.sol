pragma solidity >=0.4.0 <0.6.0;

// @title Faireum Dice Game Contract
contract FaireumDice{
    
    // State Variables
    address constant TEST_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;

    uint constant HOUSE_PERCENT = 1;
    uint constant HOUSE_MINIMUM_AMOUNT = 0.0003 ether;

    uint constant JACKPOT_MODULO = 1000;
    uint constant JACKPOT_FEE = 0.001 ether;
    uint constant MIN_JACKPOT_BET = 0.1 ether;

    uint128 public lockedInBets;
    address public owner;
    address public croupier;

    mapping (uint => Bet) bets;

    // A single bet struct
    struct Bet {
        uint amount;
        uint8 modulo;
        uint8 rollUnder;
        uint40 blockNumber;
        address user;
    }

    //Modifiers
    modifier onlyOwner {
        require (msg.sender == owner, "Must be contract owner to invoke this method.");
        _;
    }

    modifier onlyCroupier {
        require (msg.sender == croupier, "Must be croupier to invoke this method.");
        _;
    }

    // Constructor. 
    constructor () public {
        owner = msg.sender;
        croupier = TEST_ADDRESS;
    }

    // Fallback function. Deliberately left empty.
    function () public payable {
    }


    function setCroupier(address newCroupier) external onlyOwner {
        croupier = newCroupier;
    }

    function kill() external onlyOwner {
        require (lockedInBets == 0, "Contract can't be destroyed if there are on going bets");
        selfdestruct(owner);
    }

    // @dev Logic for placing a bet, recieves value of bet
    // @param modulo - Modulo for the game
    // @param commit - Unique bet identifier (Keccak256 hash)
    function placeBet (
        uint modulo, 
        uint commit
    ) 
        external payable 
    {
        Bet storage bet = bets[commit];
        require (bet.user == address(0), "Should be a new bet.");

        //Validate amounts
        uint amount = msg.value;
        require (modulo > 1 && modulo <= 100, "Modulo is out of range.");
        require (amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount is out of range.");
        
        uint rollUnder;

        //TODO

        //Store bet
        bet.amount = amount;
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.blockNumber = uint40(block.number);
        bet.user = msg.sender;
    }

    // @dev returns the expected amount to win after subtracting house edge
    // @param amount
    // @param modulo
    // @param rollUnder
    function getDiceWinAmount(
        uint amount, 
        uint modulo, 
        uint rollUnder
    ) 
        private 
        pure 
        returns (uint winAmount, uint jackpotFee) 
    {
       
        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        uint houseEdge = amount * HOUSE_PERCENT / 100;

        if (houseEdge < HOUSE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_MINIMUM_AMOUNT;
        }

        winAmount = (amount - houseEdge - jackpotFee) * modulo / rollUnder;
    }

    function settleBet() external onlyCroupier {
        //TODO
    }
   
}