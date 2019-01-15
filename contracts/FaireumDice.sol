pragma solidity >=0.4.0 <0.6.0

import "./SafeMath.sol";
// @title Faireum Dice Game Contract
contract FaireumDice{
    
    // State Variables
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 250000 ether;

    uint constant HOUSE_PERCENT = 15;
    uint constant HOUSE_MINIMUM_AMOUNT = 0.0002 ether;

    uint constant JACKPOT_MODULO = 1000;
    uint constant JACKPOT_FEE = 0.0015 ether;
    uint constant MIN_JACKPOT_BET = 0.15 ether;

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

    //Events
    event PaymentCompleted(address user, uint amount);
    event JackpotPaid(address user, uint amount);
    event BetPlaced(uint commit, address user, uint amount);


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
        croupier = address(0xFa1cb3601A518337DE08F67Ceda7f23B8A800F52);
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

        emit BetPlaced(commit, bet.user, amount);
    }

    // @dev returns the expected amount to win after subtracting house edge
    // @param amount - bet amount
    // @param modulo - modulo of the game
    // @param rollUnder - number to roll under
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

        uint houseEdge = amount * (HOUSE_PERCENT / 10) / 100;

        if (houseEdge < HOUSE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_MINIMUM_AMOUNT;
        }

        winAmount = (amount.sub(houseEdge).sub(jackpotFee))
        .mul(modulo / rollUnder);
    }

    // @dev settles the bet
    function settleBet(
        uint reveal, 
        bytes32 blockHash
    ) 
        external 
        onlyCroupier 
    {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint blockNumber = bet.blockNumber;

        require (blockhash(blockNumber) == blockHash);

        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address user = bet.user;

        require (amount != 0, "Bet must have value amount.");

        bytes32 random = keccak256(abi.encodePacked(reveal, blockHash));
        uint diceRoll = uint(random) % modulo;

        uint diceWinAmount;
        uint jackpotFee;
        (diceWinAmount, jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);

        uint diceWin = 0;
        uint jackpotWin = 0;

        if (diceRoll < rollUnder) {
            diceWin = diceWinAmount;
        }

        if (jackpotWin > 0) {
            emit JackpotPaid(user, jackpotWin);
        }

        bet.amount = 0;
        emit PaymentCompleted(user, diceWin + jackpotWin);
    }
   
}