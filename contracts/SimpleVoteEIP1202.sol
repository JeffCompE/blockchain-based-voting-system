pragma solidity ^0.5.0;

/**
 * A simple implementation of the voting standard proposed in EIP1202:
 * (1) one issue per contract
 * (2) only two options are available (Yes and No)
 * (3) address can only vote once and every address has an equal weight of 1
 */
contract SimpleVoteEIP1202 {
    uint[] public available_options = [1, 2];
    mapping(uint => string) public option_descriptions;
    mapping(address => uint) public ballots;
    mapping(uint => uint) public vote_counts;
    bool public status;
    string public issue_description;

    modifier isOpen() {
        require(status, "Vote is not open.");
        _;
    }

    modifier isValidOption(uint option) {
        require(option == 1 || option == 2, 'Invalid option');
        _;
    }

    event OnVote(address indexed _from, uint _value);
    event OnStatusChage(bool newIsOpen);

    constructor(string memory issue_description_) public {
        issue_description = issue_description_;
        option_descriptions[1] = 'Yes';
        option_descriptions[2] = 'No';
        option_descriptions[3] = 'Only serves as an indicator of a tie, not a valid option to be voted';
        option_descriptions[0] = 'Only serves as an indicator that someone has not casted vote, not a valid option to be voted';
    }

    function vote(uint option) external isOpen isValidOption(option) returns (bool success) {
        require(ballots[msg.sender] != 0, 'The sender has already casted vote');
        ballots[msg.sender] = option;
        vote_counts[option] += 1;
        emit OnVote(msg.sender, option);
        return true;
    }

    function setStatus(bool isOpen_) external returns (bool success) {
        require(status != isOpen_, 'Cannot set the same status again');
        status = isOpen_;
        emit OnStatusChage(isOpen_);
        return true;
    }

    function issueDescription() external view returns (string memory desc) {
        return issue_description;
    }

    function availableOptions() external view returns (uint[] memory options) {
        return available_options;
    }

    function optionDescription(uint option) external view isValidOption(option) returns (string memory desc) {
        return option_descriptions[option];
    }

    function ballotOf(address addr) external view returns (uint option) {
        return ballots[addr];
    }

    function getStatus() external view returns (bool isOpen_) {
        return status;
    }

    function VoteCountsof(uint option) external view isValidOption(option) returns (uint count) {
        return vote_counts[option];
    }

    function winningOption() external view returns (uint option) {
        if (vote_counts[1] > vote_counts[2]) {
            return 1;
        }
        else if (vote_counts[1] < vote_counts[2]) {
            return 2;
        }
        else {
            return 0; // use 0 to indicate a tie
        }
    }
}
