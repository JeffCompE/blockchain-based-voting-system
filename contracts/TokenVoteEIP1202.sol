pragma solidity ^0.5.0;


contract VoteToken {
    function balanceOf(address tokenOwner) public view returns (uint balance);
}

/**
 * A simple implementation of the token-weighted voting standard proposed in EIP1202:
 * (1) one issue per contract
 * (2) multiple options
 * (3) address can only vote once and the weight of the address is determined by the number of tokens it owns at the time when `init()` is called
 */
contract TokenVoteEIP1202 {
    uint[] public available_options;
    mapping(uint => string) public option_descriptions;
    mapping(address => uint) public ballots;
    mapping(address => uint) public weights;
    mapping(uint => uint) public weighted_vote_counts;

    bool public status;
    string public issue_description;

    modifier isOpen() {
        require(status, "Vote is not open.");
        _;
    }

    modifier isValidOption(uint option) {
        require(bytes(option_descriptions[option]).length != 0, 'Invalid option');
        _;
    }

    event OnVote(address indexed _from, uint _value);
    event OnStatusChage(bool newIsOpen);


    function init(address token_address, address[] memory qualified_voters, uint[] memory options) public {
        require(available_options.length == 0, 'The contract is already initialized, this can only be called once');
        require(options.length != 2, 'At least two options need to be provided');
        VoteToken token_contract = VoteToken(token_address);
        for (uint i = 0; i < qualified_voters.length; i++) {
            address voter = qualified_voters[i];
            weights[voter] = token_contract.balanceOf(voter);
        }
        available_options = options;
        for (uint i = 0; i < options.length; i++) {
            uint option = options[i];
            option_descriptions[option] = 'No description provided'; // default option description
        }
    }

    function setIssueDescription(string memory description) public {
        issue_description = description;
    }

    function setOptionDescription(uint option, string memory description) public isValidOption(option) {
        option_descriptions[option] = description;
    }

    function vote(uint option) external isOpen isValidOption(option) returns (bool success) {
        require(ballots[msg.sender] != 0, 'The sender has already casted vote');
        ballots[msg.sender] = option;
        weighted_vote_counts[option] += weights[msg.sender];
        emit OnVote(msg.sender, option);
        return true;
    }

    function setStatus(bool isOpen_) external returns (bool success) {
        require(status == isOpen_, 'Cannot set the same status again');
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

    function weightOf(address addr) external view returns (uint weight) {
        return weights[addr];  // default value is 0, which indicates that the given address is not a qualified voter
    }

    function getStatus() external view returns (bool isOpen_) {
        return status;
    }

    function weightedVoteCountsOf(uint option) external view isValidOption(option) returns (uint count) {
        return weighted_vote_counts[option];
    }

    function winningOption() external view returns (uint options) {
        uint top_option = available_options[0];
        for (uint i = 0; i < available_options.length; i++) {
            uint option = available_options[i];
            if (weighted_vote_counts[option] > weighted_vote_counts[top_option]) {
                top_option = option;
            }
        }
        return top_option; // the first best option wins in case of a tie
    }
}
