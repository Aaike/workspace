// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IStaking.sol";
import "./Owned.sol";
import "./Pausable.sol";

contract Staking is IStaking, Owned, Pausable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */
  struct LockedBalance {
    address _address;
    uint256 _balance;
    uint256 _time;
    uint256 _lockedAt;
  }

  IERC20 public immutable POP;
  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public rewardsDuration = 7 days;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  mapping(address => uint256) public voiceCredits;
  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 private _totalLocked;
  mapping(address => LockedBalance[]) private lockedBalances;

  uint256 constant SECONDS_IN_A_WEEK = 604800;
  uint256 constant MAX_LOCK_TIME = SECONDS_IN_A_WEEK * 52 * 4; // 4 years

  /* ========== EVENTS ========== */

  event StakingDeposited(address _address, uint256 amount);
  event StakingWithdrawn(address _address, uint256 amount);
  event RewardPaid(address _address, uint256 amount);

/* ========== CONSTRUCTOR ========== */

  constructor(IERC20 _pop) Owned(msg.sender) {
    POP = _pop;
  }

  /* ========== VIEWS ========== */

  function getVoiceCredits(address _address)
    public
    view
    override
    returns (uint256)
  {
    return voiceCredits[_address];
  }

  function getWithdrawableBalance() public view override returns (uint256) {
    uint256 _withdrawable = 0;
    uint256 _currentTime = block.timestamp;
    for (uint8 i = 0; i < lockedBalances[msg.sender].length; i++) {
      LockedBalance memory _locked = lockedBalances[msg.sender][i];
      if (_locked._lockedAt.add(_locked._time) <= _currentTime) {
        _withdrawable = _withdrawable.add(_locked._balance);
      }
    }

    return _withdrawable;
  }

  function totalLocked() external view returns (uint256) {
    return _totalLocked;
  }

  function balanceOf(address account) external view returns (uint256) {
    return lockedBalances[account];
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    if (_totalLocked == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(_totalLocked)
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      lockedBalances[account]
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function getRewardForDuration() external view returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */
  function stake(uint256 amount, uint256 lengthOfTime)
    external
    override
    nonReentrant
    updateReward(msg.sender)
  {
    require(amount > 0, "amount must be greater than 0");
    require(
      lengthOfTime >= SECONDS_IN_A_WEEK,
      "must lock tokens for at least 1 week"
    );
    require(
      lengthOfTime <= MAX_LOCK_TIME,
      "must lock tokens for less than/equal to  4 year"
    );
    require(POP.balanceOf(msg.sender) >= amount, "insufficient balance");

    POP.safeTransferFrom(msg.sender, address(this), amount);

    _totalLocked = _totalLocked.add(amount);
    lockedBalances[msg.sender].push(
      LockedBalance({
        _address: msg.sender,
        _balance: amount,
        _time: lengthOfTime,
        _lockedAt: block.timestamp
      })
    );
    _recalculateVoiceCredits();
    emit StakingDeposited(msg.sender, amount);
  }

  function withdraw(uint256 amount) public override nonReentrant {
    require(amount > 0, "amount must be greater than 0");
    require(amount <= getWithdrawableBalance());

    POP.approve(address(this), amount);
    POP.safeTransferFrom(address(this), msg.sender, amount);

    _totalSupply = _totalSupply.sub(amount);
    _getReward();
    _clearWithdrawnFromLocked(amount);
    _recalculateVoiceCredits();
    emit StakingWithdrawn(msg.sender, amount);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */
  function _clearWithdrawnFromLocked(uint256 _amount) internal {
    uint256 _currentTime = block.timestamp;
    for (uint8 i = 0; i < lockedBalances[msg.sender].length; i++) {
      LockedBalance memory _locked = lockedBalances[msg.sender][i];
      if (_locked._lockedAt.add(_locked._time) <= _currentTime) {
        if (_amount == _locked._balance) {
          delete lockedBalances[msg.sender][i];
          return;
        }
        if (_amount > _locked._balance) {
          _amount = _amount.sub(_locked._balance);
          delete lockedBalances[msg.sender][i];
          continue;
        }
        if (_amount < _locked._balance) {
          lockedBalances[msg.sender][i]._balance = _locked._balance.sub(
            _amount
          );
          return;
        }
      }
    }
  }

  function _getReward() internal nonReentrant updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardsToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  // todo: multiply voice credits by 10000 to deal with exponent math
  function _recalculateVoiceCredits() internal {
    uint256 _voiceCredits = 0;
    for (uint8 i = 0; i < lockedBalances[msg.sender].length; i++) {
      LockedBalance memory _locked = lockedBalances[msg.sender][i];
      _voiceCredits = _voiceCredits.add(
        _locked._balance.mul(_locked._time).div(MAX_LOCK_TIME)
      );
    }
    voiceCredits[msg.sender] = _voiceCredits;
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }
}
