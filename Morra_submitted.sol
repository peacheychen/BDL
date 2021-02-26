pragma solidity ^0.5.0;

contract Morra {
    address payable private player1;
    address payable private player2;
    address payable private winner;
    uint private choiceOfPlayer1; //number of fingers guessed player 1
    uint private choiceOfPlayer2; // number of fingers guessed player 2
    uint private draw; // integer flag indicating presence of a draw
    bool private discloseRun;
    bool private hasPlayer1MadeChoice;
    bool private hasPlayer2MadeChoice;

    // When a player joins the game, they have to pay a playing fee equal to their number of fingers
    uint private stakeOfPlayer1;
    uint private stakeOfPlayer2;
    
    mapping(address => uint256) balance;

    // The constructor initialise the environment
    constructor() public {
        assert(1 ether == 1e18);  //specify units for the whole contract 
    }
    
    // Modifiers
    modifier isPlayer() {
        require(msg.sender == player1 || msg.sender == player2, "You are not playing this game.");
        _;
    }
    
    modifier isJoinable() {   //compare to list of 1-5
        require(player1 == address(0) || player2 == address(0), "Game is full.");
        require(msg.sender != player2 && msg.sender != player1, "You are already in the game");
        require(msg.value == (1 ether) ||
                msg.value == (2 ether) ||
                msg.value == (3 ether) ||
                msg.value == (4 ether) ||
                msg.value == (5 ether), 
                "Your choice of stake (fingers) is not valid, it should be one of 1-5.");
        _;
    }

    modifier isValidChoice(uint _playerChoice) {
        require(
                _playerChoice == 1 ||
                _playerChoice == 2 ||
                _playerChoice == 3 ||
                _playerChoice == 4 ||
                _playerChoice == 5 , 
                "Your choice is not valid, it should be one of 1-5.");
        _;
    }
    
    // Checking if our players have made a choice before we can call disclose... 
    modifier playersMadeChoice() {
        require(hasPlayer1MadeChoice && hasPlayer2MadeChoice, "The player(s) have not made their choice yet.");
        _;
    }
    
    modifier isDraw(){
        require(draw == 1 && winner == address(0), "There is a draw - refunds available");
        _;
    }
    
    modifier isWinner() {
        require(msg.sender == winner, "You arent the winner");
        _;
    }
    
    modifier restrictBalance(){ //modifier added to attempt to eliminate infinite gas costs of withdraw functions
        require(address(this).balance >=10 ether);
        _;
    }
    
    
    modifier isdiscloseRun(){
        require(discloseRun == true, "Not authorised: Play has not finished");
        _;
    }

    // Functions
     
    function join() external payable 
        isJoinable() // To join the game, there must be a free space
    {
        if (player1 == address(0)){
            player1 = msg.sender;
            stakeOfPlayer1 = msg.value; //*1000000000000000000

    } else {
            player2 = msg.sender;
            stakeOfPlayer2 = msg.value; //*1000000000000000000
            }
    }
    
    function get_stake() public view returns(uint) {
        if (msg.sender == player1){
            return stakeOfPlayer1;
        } else {
            return stakeOfPlayer2;
        }
    }
    
    //
    function getBalance() public view returns(uint256)
        {
            require(msg.sender == player1 || msg.sender == player2, "Not authorised.");
            require(hasPlayer1MadeChoice && hasPlayer2MadeChoice, "Players Havent made choices yet");
            require(discloseRun ==  true, "Balance cannot be viewed before play");
            
            return (address(this).balance);
        }
    
    //
    function makeChoice(uint _playerChoice) external 
        isPlayer()                      // Only the players can make the choice
        isValidChoice(_playerChoice)    // The choices should be valid 
    {
        
        if (msg.sender == player1) {
            require(hasPlayer1MadeChoice == false, "You have already made a choice"); 
        } else if (msg.sender == player2) {
            require(hasPlayer2MadeChoice == false, "You have already made a choice");
        }
        
        if (msg.sender == player1 && !hasPlayer1MadeChoice) {
            choiceOfPlayer1 = _playerChoice * 1000000000000000000;
            hasPlayer1MadeChoice = true;
        } else if (msg.sender == player2 && !hasPlayer2MadeChoice) {
            choiceOfPlayer2 = _playerChoice * 1000000000000000000;
            hasPlayer2MadeChoice = true;
        }
    }
    

    function withdraw_winner() external
        isWinner()  // only winner
        isdiscloseRun() // only when play has occurred
    {
        require(draw == 0, "Invalid Request");
        balance[winner] = 0;
        winner.transfer(address(this).balance);
        // After winner has withdrawn, reset game parameters
        stakeOfPlayer1 = 0;
        stakeOfPlayer2 = 0;
        player1 = address(0);
        player2 = address(0);
    } 
    
    function withdraw_draw() external 
        isPlayer()  // only players can access
        isDraw() // there must be a draw
        isdiscloseRun() // only when play has happened
    {
        // Reset parameters of the game as players withdraw their entitlements

        if (msg.sender == player1){
            balance[player1] = 0;
            player1.transfer(stakeOfPlayer1);
            player1 = address(0);
            stakeOfPlayer1 = 0;
        } else if (msg.sender == player2) {
            balance[player1] = 0;
            player2.transfer(stakeOfPlayer2);
            player2 = address(0);
            stakeOfPlayer2 = 0;
        }
    }
    

    function disclose() external 
        isPlayer()          // Only players can disclose the game result
        playersMadeChoice() // Can only call disclose (results) AFTER choices are made
        
    {
        // Disclose the game result
        require(discloseRun == false);
        discloseRun = true;
        if ((choiceOfPlayer2 == stakeOfPlayer1 && choiceOfPlayer1 == stakeOfPlayer2) ||
              (choiceOfPlayer2 != stakeOfPlayer1 && choiceOfPlayer1 != stakeOfPlayer2)) {
            draw = 1; // flag to indicate draw
            winner = address(0); // no winner

        } else if (choiceOfPlayer2 != stakeOfPlayer1 && choiceOfPlayer1 == stakeOfPlayer2) {
            winner = player1;

        } else if (choiceOfPlayer2 == stakeOfPlayer1 && choiceOfPlayer1 != stakeOfPlayer2) {
            winner = player2;
        }
        
        // Reset the guesses - other parts reset as players withdraw
        choiceOfPlayer1 = 0;
        choiceOfPlayer2 = 0;
        hasPlayer1MadeChoice = false;
        hasPlayer2MadeChoice = false;
    }
}