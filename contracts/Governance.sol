pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import { Moderated } from "./Moderated.sol";
import { IGovernance } from "./interfaces/IGovernance.sol";
/**
 * @title Governance
 * @dev Manage the creation of new art pieces, artifacts
 */
contract Governance is IGovernance, Moderated {

  event Propose(uint indexed proposalId, address indexed proposer, address indexed target, bytes data);
  event Approve(uint indexed proposalId);
  event Reject(uint indexed proposalId);
  event Execute(uint indexed proposalId);

  Proposal[] public proposals;

  // Maps the proposal id to the proposer of the artifact.
  mapping (uint => address) public proposalToProposer;

  // TODO(mm5917): should submitting cost ether?
  function propose(address target, bytes memory data) public returns (uint) {
    require(msg.sender != address(this), "Governance::propose: Invalid proposal");
    // require(token.transferFrom(msg.sender, address(this), proposalFee), "Governance::propose: Transfer failed");

    uint proposalId = proposals.length;

    // Create a new proposal
    Proposal memory proposal;
    proposal.target = target;
    proposal.data = data;
    proposal.proposer = msg.sender;
    proposal.status = Status.Pending;

    proposals.push(proposal);

    emit Propose(proposalId, msg.sender, target, data);

    return proposalId;
  }

  function getProposal(uint proposalId) public view returns (Proposal memory) {
    return proposals[proposalId];
  }

  function approve(uint proposalId) public onlyModerator {
    Proposal memory proposal = proposals[proposalId];
    require(
      proposal.status == Status.Pending,
      "Governance::approve: Proposal is already finalized"
    );

    proposals[proposalId].status = Status.Approved;

    emit Approve(proposalId);
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = proposal.target.call(proposal.data);
    require(success, "Governance::approve: Proposal target call was unsuccessful");
  }

  function reject(uint proposalId) public {
    require(
      msg.sender == proposals[proposalId].proposer || moderators[msg.sender],
      "Governance::reject: Only the proposer or moderator can reject a proposal"
    );
    require(
      proposals[proposalId].status == Status.Pending,
      "Governance::reject: Proposal is already finalized"
    );

    proposals[proposalId].status = Status.Rejected;

    emit Reject(proposalId);
  }

  function isGovernor(address account) public view returns (bool) {
    return moderators[account];
  }

  // As far as I can work out you can't have a memory array be dynamic
  // Have to iterate twice to work out size of array then populate
  function getProposals() public view returns (uint[] memory) {
    uint count = 0;

    for (uint i = 0; i < proposals.length; i++) {
      Proposal memory proposal = proposals[i];

      if (proposal.status == Status.Pending) {
        count++;
      }
    }

    uint[] memory pending = new uint[](count);

    count = 0;

    for (uint i = 0; i < proposals.length; i++) {
      Proposal memory proposal = proposals[i];

      if (proposal.status == Status.Pending) {
        pending[count] = i;
        count++;
      }
    }

    return pending;
  }
}