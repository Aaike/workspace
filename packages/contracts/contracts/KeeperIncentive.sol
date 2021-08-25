pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IStaking.sol";
import "./Governed.sol";

contract KeeperIncentive is Governed {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct Incentive {
    uint256 reward; //pop reward for calling the function
    bool enabled;
    bool openToEveryone; //can everyone call the function to get the reward or only approved?
  }

  /* ========== STATE VARIABLES ========== */

  IERC20 public immutable POP;
  Incentive[] public incentives;
  IStaking public staking;
  uint256 public incentiveBudget;
  mapping(address => bool) public approved;

  /* ========== EVENTS ========== */

  event ApprovalToggled(uint256 incentiveId, bool openToEveryone);
  event Approved(address account);
  event IncentiveChanged(uint256 incentiveId);
  event IncentiveCreated(uint256 incentiveId);
  event IncentiveFunded(uint256 amount);
  event IncentiveToggled(uint256 incentiveId, bool enabled);
  event RemovedApproval(address account);
  event StakingChanged(IStaking from, IStaking to);

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _governance,
    IERC20 _pop,
    IStaking _staking
  ) public Governed(_governance) {
    POP = _pop;
    createIncentive(10e18, true, false);
    staking = _staking;
  }

  /* ========== SETTER ========== */

  /**
   * @notice Create Incentives for keeper to call a function
   * @param _reward The amount in POP the Keeper receives for calling the function
   * @param _enabled Is this Incentive currently enabled?
   * @param _openToEveryone Can anyone call the function for rewards or only keeper?
   * @dev This function is only for creating unique incentives for future contracts
   * @dev Multiple functions can use the same incentive which can than be updated with one governance vote
   * @dev Per default there will be always one incentive on index 0
   */
  function createIncentive(
    uint256 _reward,
    bool _enabled,
    bool _openToEveryone
  ) public onlyGovernance returns (uint256) {
    incentives.push(
      Incentive({
        reward: _reward,
        enabled: _enabled,
        openToEveryone: _openToEveryone
      })
    );
    emit IncentiveCreated(incentives.length);
    return incentives.length;
  }

  /**
   * @notice Overrides existing Staking contract
   * @param staking_ Address of new Staking contract
   * @dev Must implement IStaking and cannot be same as existing
   */
  function setStaking(IStaking staking_) public {
    require(staking != staking_, "Same Staking");
    IStaking _previousStaking = staking;
    staking = staking_;
    emit StakingChanged(_previousStaking, staking);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function updateIncentive(
    uint256 _incentiveId,
    uint256 _reward,
    bool _enabled,
    bool _openToEveryone
  ) external onlyGovernance {
    incentives[_incentiveId] = Incentive({
      reward: _reward,
      enabled: _enabled,
      openToEveryone: _openToEveryone
    });
    emit IncentiveChanged(_incentiveId);
  }

  function approveAccount(address _account) external onlyGovernance {
    approved[_account] = true;
    emit Approved(_account);
  }

  function removeApproval(address _account) external onlyGovernance {
    approved[_account] = false;
    emit RemovedApproval(_account);
  }

  function toggleApproval(uint256 _incentiveId) external onlyGovernance {
    incentives[_incentiveId].openToEveryone = !incentives[_incentiveId]
      .openToEveryone;
    emit ApprovalToggled(_incentiveId, incentives[_incentiveId].openToEveryone);
  }

  function toggleIncentive(uint256 _incentiveId) external onlyGovernance {
    incentives[_incentiveId].enabled = !incentives[_incentiveId].enabled;
    emit IncentiveToggled(_incentiveId, incentives[_incentiveId].enabled);
  }

  function fundIncentive(uint256 _amount) external {
    POP.safeTransferFrom(msg.sender, address(this), _amount);
    incentiveBudget = incentiveBudget.add(_amount);
    emit IncentiveFunded(_amount);
  }

  /* ========== MODIFIER ========== */

  modifier keeperIncentive(uint256 _incentiveId) {
    uint256 _stakedVoiceCredits = staking.getVoiceCredits(msg.sender);
    if (_incentiveId < incentives.length) {
      Incentive storage incentive = incentives[_incentiveId];

      if (!incentive.openToEveryone) {
        require(
          approved[msg.sender] || msg.sender == governance,
          "you are not approved as a keeper"
        );
      }
      require(_stakedVoiceCredits >= 350000, "Insufficient voice credits");
      if (incentive.reward <= incentiveBudget) {
        incentiveBudget = incentiveBudget.sub(incentive.reward);
        POP.approve(address(this), incentive.reward);
        POP.safeTransferFrom(address(this), msg.sender, incentive.reward);
      }
    }
    _;
  }
}
