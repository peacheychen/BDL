// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;

contract MatchPennies {

    uint constant public stake = 1 ether;    // The  stake
    uint public initialstake;               // stake of first player

    enum Moves {None,Zero, One}             // Possible moves of pick 
    enum Outcomes {None, PlayerA, PlayerB, Draw}   // Possible outcomes

    // Players' addresses
    address payable playerA;
    address payable playerB;

    // Encrypted moves
    bytes32 private encryptedMovePlayerA;
    bytes32 private encryptedMovePlayerB;

    // Clear moves; they are set only after both players have committed their encrypted moves
    Moves private pickPlayerA;
    Moves private pickPlayerB;

        
    /* 
    JOIN PHASE
    */
    
    // Both players must have not already been registered
    modifier isNotJoined() {
        require(msg.sender != playerA && msg.sender != playerB);
        _;
    }

    // stake must be equal to the amount (1 eth)
    // AND greater than or equal to the stake of the first player
    modifier isValidstake() {
        require(msg.value == stake,"Your choice of stake  is not valid, it should be one ether .");
        require(msg.value >= initialstake);
        _;
    }

    // Register a player.
    // Return player's ID upon successful registration.
    function Join() public payable isNotJoined isValidstake returns (uint) {
        if (playerA == address(0x0)) {
            playerA    = msg.sender;
            initialstake = msg.value;
            return 1;
        } else if (playerB == address(0x0)) {
            playerB = msg.sender;
            return 2;
        }
        return 0;
    }
    
    /*
    fisrtCommit COMMIT PHASE
    */

    // Player committing must be already registered
    modifier isRegistered() {
        require (msg.sender == playerA || msg.sender == playerB);
        _;
    }

    // Save player's encrypted move (hash).
    // Return true if move was valid (there is no encrypted move saved yet), false otherwise.
    function fisrtCommitHash(bytes32 encryptedMove) public isRegistered returns (bool) {
        if (msg.sender == playerA && encryptedMovePlayerA == 0x0) {
            encryptedMovePlayerA = encryptedMove;
        } else if (msg.sender == playerB && encryptedMovePlayerB == 0x0) {
            encryptedMovePlayerB = encryptedMove;
        } else {
            return false;
        }
        return true;
    }
    

    /*
    sencondCommit PHASE
    */
    
    // Both players' encrypted moves are saved to the contract
    modifier commitPhaseEnded() {
        require(encryptedMovePlayerA != 0x0 && encryptedMovePlayerB != 0x0);
        _;
    }

    // Compare clear move given by the player with saved encrypted move.
    // Return the player's pick upon success, exit otherwise.
    function sencondCommitClear(string memory clearMove) public isRegistered commitPhaseEnded returns (Moves) {
        bytes32 encryptedMove = sha256(abi.encodePacked(clearMove)); // Hash of clear input ("pick-password")
        Moves pick            = Moves(getPick(clearMove)); // Actual number the player picked
        
        // If the two hashes match, picks are saved
        if (msg.sender == playerA && encryptedMove == encryptedMovePlayerA) {
            pickPlayerA = pick;
        } else if (msg.sender == playerB && encryptedMove == encryptedMovePlayerB) {
            pickPlayerB = pick;
        } else {
            return Moves.None;
        }

        return pick;
    }

    // Return player's pick using clear move given by the player
    function getPick(string memory str) private pure returns (uint) {
        byte firstByte = bytes(str)[0];
        if (firstByte == 0x30) {
            return 1;
        } else if (firstByte == 0x31) {
            return 2;
        } else {
            return 0;
        }
    }
    

       // User should use this to get the hash of their string and enter into the input field for the play() method
    function Hash(string memory moveToEncrypt) public pure returns (bytes32) {
        
        bytes32 encrypted = sha256(abi.encodePacked(moveToEncrypt));
        return encrypted;
    }


    /*
    RESULT PHASE
    */
    
    // Compute the outcome and pay the winner(s) and return the outcome.
    function reveal() public returns (Outcomes) { 
        if (pickPlayerA == Moves.None || pickPlayerB == Moves.None ) {
                return Outcomes.None;
                // Both players' pick and guess must be valid
        }
            
        Outcomes outcome;

        if (pickPlayerA ==  pickPlayerB ) {
            outcome = Outcomes.PlayerA;
        } 
        else if  (pickPlayerA ==  Moves.One &&  pickPlayerB == Moves.Zero ) {
            outcome = Outcomes.PlayerB;
        }
        else if  (pickPlayerA ==  Moves.Zero &&  pickPlayerB == Moves.One){  
            outcome = Outcomes.PlayerB;
        }
        else{   
            outcome = Outcomes.Draw;
        }

        address payable addressA = playerA;
        address payable addressB = playerB;
        uint stakePlayerA          = initialstake;
        reset();  // Reset game before paying in order to avoid reentrancy attacks
        pay(addressA, addressB, stakePlayerA, outcome);

        return outcome;
    }

    // Pay the winner(s).
    function pay(address payable addressA, address payable addressB, uint stakePlayerA, Outcomes outcome) private {
        if (outcome == Outcomes.PlayerA) {
            addressA.transfer(address(this).balance);
        } else if (outcome == Outcomes.PlayerB) {
            addressB.transfer(address(this).balance);
        } else {
            addressA.transfer(stakePlayerA);
            addressB.transfer(address(this).balance);
        }
    }

    // Reset the game.
    function reset() private {
        initialstake      = 0;
        playerA         = address(0x0);
        playerB         = address(0x0);
        encryptedMovePlayerA = 0x0;
        encryptedMovePlayerB = 0x0;
        pickPlayerA     = Moves.None;
        pickPlayerB     = Moves.None;

    }
    
     /*
     HELPER FUNCTIONS
     */

    // Return the balance of the contract
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Return player's ID
    function Iam() public view returns (uint) {
        if (msg.sender == playerA) {
            return 1;
        } else if (msg.sender == playerB) {
            return 2;
        } else {
            return 0;
        }
    }

    // Return true if both players have commited a move, false otherwise.
    function bothPlayed() public view returns (bool) {
        return (encryptedMovePlayerA != 0x0 && encryptedMovePlayerB != 0x0);
    }

    // Return true if both players have revealed their move, false otherwise.
    function Revealedstatus() public view returns (bool) {
        return (pickPlayerA != Moves.None && pickPlayerB != Moves.None );
    }
}
