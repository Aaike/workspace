// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IStaking.sol";
import "./IBeneficiaryRegistry.sol";

/// @notice This contract is for submitting beneficiary nomination proposals and beneficiary takedown proposals

contract BeneficiaryNomination {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public immutable POP;
  IStaking staking;
  IBeneficiaryRegistry beneficiaryRegistry;

  address public governance;
  /**
   * BNP for Beneficiary Nomination Proposal
   * BTP for Beneficiary Takedown Proposal
   */
  enum ProposalType {BNP, BTP}

  struct Proposal {
    //Result result;
    address beneficiary;
    bytes content;
    address proposer;
    address bondRecipient;
    uint256 bond;
    uint256 startTime;
    uint256 yesCount;
    uint256 noCount;
    ProposalType _proposalType;
  }
  Proposal[] public proposals;
  struct ConfigurationOptions {
    uint256 votingPeriod;
    uint256 vetoPeriod;
    uint256 minProposalBond;
  }
  ConfigurationOptions public DefaultConfigurations;
  //modifiers
  modifier onlyGovernance {
    require(msg.sender == governance, "!governance");
    _;
  }
  modifier validAddress(address _address) {
    require(_address == address(_address), "invalid address");
    _;
  }
  modifier enoughBond(uint256 bond) {
    require(bond >= DefaultConfigurations.minProposalBond, "!enough bond");
    _;
  }
  //events
  event GovernanceUpdated(
    address indexed _oldAddress,
    address indexed _newAddress
  );
  event Propose(
    uint256 indexed proposalId,
    address indexed proposer,
    address indexed beneficiary,
    bytes content
  );

  //constructor
  constructor(
    IStaking _staking,
    IBeneficiaryRegistry _beneficiaryRegistry,
    IERC20 _pop,
    address _governance
  ) {
    staking = _staking;
    beneficiaryRegistry = _beneficiaryRegistry;
    POP = _pop;
    governance = _governance;
    _setDefaults();
  }

  /**
   * @notice sets governance to address provided
   */
  function setGovernance(address _address)
    external
    onlyGovernance
    validAddress(_address)
  {
    address _previousGovernance = governance;
    governance = _address;
    emit GovernanceUpdated(_previousGovernance, _address);
  }

  function _setDefaults() internal {
    DefaultConfigurations.votingPeriod = 2 days;
    DefaultConfigurations.vetoPeriod = 2 days;
    DefaultConfigurations.minProposalBond = 2000e18;
  }

  function setConfiguration(
    uint256 _votingPeriod,
    uint256 _vetoPeriod,
    uint256 _proposalBond
  ) public onlyGovernance {
    DefaultConfigurations.votingPeriod = _votingPeriod;
    DefaultConfigurations.vetoPeriod = _vetoPeriod;
    DefaultConfigurations.minProposalBond = _proposalBond;
  }

  ///@notice proposes a beneficiary nomination proposal
  ///@param  _beneficiary address of the beneficiary
  ///@param  _content IPFS content hash
  ///@return proposal id
  function propose(
    address _beneficiary,
    bytes memory _content,
    ProposalType _type
  )
    external
    payable
    validAddress(_beneficiary)
    enoughBond(msg.value)
    returns (uint256)
  {
    POP.safeTransferFrom(msg.sender, address(this), msg.value);

    uint256 proposalId = proposals.length;

    // Create a new proposal
    Proposal memory proposal;
    proposal.beneficiary = _beneficiary;
    proposal.content = _content;
    proposal.proposer = msg.sender;
    proposal.bondRecipient = msg.sender;
    proposal.bond = msg.value;
    proposal.startTime = block.timestamp;
    proposal._proposalType = _type;

    proposals.push(proposal);

    emit Propose(proposalId, msg.sender, _beneficiary, _content);

    return proposalId;
  }
}
