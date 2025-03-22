// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleScholarDAO {
    // DAO Members
    mapping(address => bool) public members;
    address public admin;
    
    // Paper struct
    struct Paper {
        address author;
        string title;
        string contentHash;
        uint256 accessPrice;
        bool verified;
        uint8 approvalCount;
        uint8 rejectionCount;
        string teamMembers;     // New field for co-authors
        string researchField;   // New field for academic discipline
        mapping(address => bool) hasVoted;
    }
    
    // Paper storage
    mapping(uint256 => Paper) public papers;
    uint256 public paperCount;
    
    // Required votes to reach consensus
    uint8 public constant REQUIRED_VOTES = 3;
    
    // Events
    event MemberAdded(address member);
    event PaperSubmitted(uint256 paperId, address author, string researchField);
    event VerificationVote(uint256 paperId, address member, bool approved);
    event PaperVerified(uint256 paperId, bool approved);
    event AccessPurchased(uint256 paperId, address buyer);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }
    
    modifier onlyMember() {
        require(members[msg.sender], "Not a member");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        members[msg.sender] = true; // Admin is first member
    }
    
    // Add a new DAO member
    function addMember(address _member) external onlyAdmin {
        members[_member] = true;
        emit MemberAdded(_member);
    }
    
    // Submit a paper for verification with additional fields
    function submitPaper(
        string calldata _title, 
        string calldata _contentHash, 
        uint256 _price,
        string calldata _teamMembers,
        string calldata _researchField
    ) external {
        uint256 newPaperId = paperCount;
        
        Paper storage newPaper = papers[newPaperId];
        newPaper.author = msg.sender;
        newPaper.title = _title;
        newPaper.contentHash = _contentHash;
        newPaper.accessPrice = _price;
        newPaper.verified = false;
        newPaper.teamMembers = _teamMembers;
        newPaper.researchField = _researchField;
        
        emit PaperSubmitted(newPaperId, msg.sender, _researchField);
        paperCount++;
    }
    
    // Vote on paper verification
    function voteOnPaper(uint256 _paperId, bool _approve) external onlyMember {
        Paper storage paper = papers[_paperId];
        
        require(!paper.verified, "Paper already verified");
        require(!paper.hasVoted[msg.sender], "Already voted");
        require(paper.author != msg.sender, "Cannot vote on own paper");
        
        paper.hasVoted[msg.sender] = true;
        
        if (_approve) {
            paper.approvalCount++;
        } else {
            paper.rejectionCount++;
        }
        
        emit VerificationVote(_paperId, msg.sender, _approve);
        
        // Check if verification threshold reached
        if (paper.approvalCount >= REQUIRED_VOTES) {
            paper.verified = true;
            emit PaperVerified(_paperId, true);
        } else if (paper.rejectionCount >= REQUIRED_VOTES) {
            // Paper rejected, but we still mark it as "verified" to indicate decision made
            paper.verified = true;
            emit PaperVerified(_paperId, false);
        }
    }
    
    // Purchase access to a paper
    function purchaseAccess(uint256 _paperId) external payable {
        Paper storage paper = papers[_paperId];
        
        require(paper.verified, "Paper not verified");
        require(paper.approvalCount >= REQUIRED_VOTES, "Paper was rejected");
        require(msg.value >= paper.accessPrice, "Insufficient payment");
        
        // Send payment to paper author
        payable(paper.author).transfer(msg.value);
        
        emit AccessPurchased(_paperId, msg.sender);
    }
    
    // Get paper verification status
    function getPaperStatus(uint256 _paperId) external view returns (
        bool isVerified,
        uint8 approvals,
        uint8 rejections
    ) {
        Paper storage paper = papers[_paperId];
        return (paper.verified, paper.approvalCount, paper.rejectionCount);
    }
    
    // Get paper details including new fields
    function getPaperDetails(uint256 _paperId) external view returns (
        address author,
        string memory title,
        uint256 price,
        string memory teamMembers,
        string memory researchField,
        bool isVerified
    ) {
        Paper storage paper = papers[_paperId];
        return (
            paper.author,
            paper.title,
            paper.accessPrice,
            paper.teamMembers,
            paper.researchField,
            paper.verified
        );
    }
}