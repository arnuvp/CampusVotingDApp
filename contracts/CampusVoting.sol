
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CampusVoting {
    // The wallet that deploys the contract becomes the administrator.
    address public immutable admin;

    // Basic election information.
    string public electionName;
    bool public votingOpen;
    bool public electionEnded;

    // Information about each candidate.
    struct Candidate {
        string name;
        string manifesto;
        uint256 voteCount;
    }

    // Candidate IDs start from 0.
    Candidate[] private candidates;

    // Tracks whether a wallet has already voted.
    mapping(address => bool) public hasVoted;

    // Events make important actions visible in transaction logs.
    event CandidateAdded(uint256 indexed candidateId, string name);
    event VotingStarted();
    event VoteCast(address indexed voter, uint256 indexed candidateId);
    event VotingEnded();

    // Restricts selected functions to the administrator.
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    // Runs once when the contract is deployed.
    constructor(string memory _electionName) {
        require(bytes(_electionName).length > 0, "Election name required");

        admin = msg.sender;
        electionName = _electionName;
    }

    // Adds candidates before voting starts.
    function addCandidate(
        string calldata _name,
        string calldata _manifesto
    ) external onlyAdmin {
        require(!votingOpen, "Voting is already open");
        require(!electionEnded, "Election has ended");
        require(bytes(_name).length > 0, "Candidate name required");
        require(bytes(_name).length <= 80, "Candidate name too long");
        require(bytes(_manifesto).length <= 500, "Manifesto too long");

        candidates.push(
            Candidate({
                name: _name,
                manifesto: _manifesto,
                voteCount: 0
            })
        );

        emit CandidateAdded(candidates.length - 1, _name);
    }

    // Starts the election. At least two candidates are required.
    function startVoting() external onlyAdmin {
        require(!votingOpen, "Voting is already open");
        require(!electionEnded, "Election has ended");
        require(candidates.length >= 2, "Add at least two candidates");

        votingOpen = true;
        emit VotingStarted();
    }

    // Allows a connected wallet to cast one vote.
    function vote(uint256 candidateId) external {
        require(votingOpen, "Voting is not open");
        require(candidateId < candidates.length, "Invalid candidate");
        require(!hasVoted[msg.sender], "Wallet has already voted");

        // Mark the wallet before updating the tally.
        hasVoted[msg.sender] = true;

        // Increment the selected candidate's vote count.
        candidates[candidateId].voteCount++;

        emit VoteCast(msg.sender, candidateId);
    }

    // Stops voting permanently for this election.
    function endVoting() external onlyAdmin {
        require(votingOpen, "Voting is not open");

        votingOpen = false;
        electionEnded = true;

        emit VotingEnded();
    }

    // Returns the number of registered candidates.
    function candidateCount() external view returns (uint256) {
        return candidates.length;
    }

    // Retrieves one candidate and their current vote count.
    function getCandidate(
        uint256 candidateId
    )
        external
        view
        returns (
            string memory name,
            string memory manifesto,
            uint256 voteCount
        )
    {
        require(candidateId < candidates.length, "Invalid candidate");

        Candidate storage c = candidates[candidateId];

        return (c.name, c.manifesto, c.voteCount);
    }
}
