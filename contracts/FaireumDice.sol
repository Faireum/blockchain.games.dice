pragma solidity >=0.4.0 <0.6.0;

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

    uint public profitLimit;
    uint public jackpotAmount;

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
    event PaymentFailed(address user, uint amount);
    event JackpotPaid(address user, uint amount);
    event BetPlaced(uint betID, address user, uint amount);


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

    function setProfitLimit(uint limit) public onlyOwner {
        require (limit < MAX_AMOUNT, "Profit limit must be less than max amount");
        profitLimit = limit;
    }

    function kill() external onlyOwner {
        require (lockedInBets == 0, "Contract can't be destroyed if there are on going bets");
        selfdestruct(owner);
    }

    // @dev Logic for placing a bet, recieves value of bet
    // @param modulo - Modulo for the game
    // @param betID - Unique bet identifier (Keccak256 hash)
    function placeBet (
        uint modulo, 
        uint betID
    ) 
        external payable 
    {
        Bet storage bet = bets[betID];
        require (bet.user == address(0), "Should be a new bet.");

        //Validate amounts
        uint amount = msg.value;
        require (modulo > 1 && modulo <= 100, "Modulo is out of range.");
        require (amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount is out of range.");
        
        uint rollUnder;

        uint winAmount;
        uint jackpotFee;

        (winAmount, jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);

        require (winAmount <= amount + profitLimit, "Win amount exceeds max profit.");

        lockedInBets += uint128(winAmount);
        jackpotAmount += uint128(jackpotFee);

        require( jackpotAmount + lockedInBets <= address(this).balance, "Contract doesn't have enough funds to place this bet.");

        //Store bet
        bet.amount = amount;
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.blockNumber = uint40(block.number);
        bet.user = msg.sender;

        emit BetPlaced(betID, bet.user, amount);
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

        require(houseEdge + jackpotFee <= amount, "Amount is too small.");

        winAmount = (amount.sub(houseEdge).sub(jackpotFee))
        .mul(modulo / rollUnder);
    }

    function refund(uint BetID) {
        Bet storage bet = bets[BetID];
        uint amount = bet.amount;

        require (amount != 0, "Bet is not active");

        bet.amount = 0;

        uint winAmount;
        uint jackpotFee;
        (winAmount, jackpotFee) = getDiceWinAmount(amount, bet.modulo, bet.rollUnder);

        processPayment(bet.user, amount);

    }


    // @dev settles the bet
    function settleBet(
        uint reveal, 
        bytes32 blockHash
    ) 
        external 
        onlyCroupier 
    {
        uint betID = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[betID];
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

        uint paymentAmount = diceWin + jackpotWin;
        processPayment(user, paymentAmount);
    }

    function processPayment(address user, uint amount) private {
        if (user.send(amount)) {
            emit PaymentCompleted(user, amount);
        } else {
            emit PaymentFailed(user, amount);
        }
    }
   
}