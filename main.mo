import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Nat "mo:base/Nat";

actor VotingSystem {
  // Type alias for readability
  type VoterId = Principal;

  // Candidate structure
  type Candidate = {
    id: Nat;
    name: Text;
    voteCount: Nat;
  };

  // State variables
  var candidates : [Candidate] = [];
  let voters = HashMap.HashMap<VoterId, Bool>(10, Principal.equal, Principal.hash);
  let votedFor = HashMap.HashMap<VoterId, Nat>(10, Principal.equal, Principal.hash);

  // Register candidates
  public shared(msg) func registerCandidates(names : [Text]) : async Result.Result<(), Text> {
    if (candidates.size() > 0) {
      return #err("Candidates already registered");
    };

    candidates := Array.tabulate<Candidate>(names.size(), func(i) {
      { id = i; name = names[i]; voteCount = 0 }
    });

    #ok()
  };

  // Cast a vote
  public shared(msg) func vote(candidateId : Nat) : async Result.Result<(), Text> {
    let voterId = msg.caller;

    // Check if voter is anonymous
    if (Principal.isAnonymous(voterId)) {
      return #err("Anonymous voting not allowed");
    };

    // Check if voter is already registered
    switch (voters.get(voterId)) {
      case (null) { return #err("Voter not registered"); };
      case (?_) {};
    };

    // Check if voter has already voted
    switch (votedFor.get(voterId)) {
      case (?_) { return #err("You have already voted"); };
      case (null) {};
    };

    // Validate candidate
    if (candidateId >= candidates.size()) {
      return #err("Invalid candidate");
    };

    // Update vote count
    let updatedCandidates = Array.thaw(candidates);
    updatedCandidates[candidateId] := {
      id = candidates[candidateId].id;
      name = candidates[candidateId].name;
      voteCount = candidates[candidateId].voteCount + 1
    };
    candidates := Array.freeze(updatedCandidates);

    // Mark voter as voted
    votedFor.put(voterId, candidateId);

    #ok()
  };

  // Register a new voter
  public shared(msg) func registerVoter() : async Result.Result<(), Text> {
    let voterId = msg.caller;

    if (Principal.isAnonymous(voterId)) {
      return #err("Anonymous principals cannot register");
    };

    if (voters.get(voterId) != null) {
      return #err("Voter already registered");
    };

    voters.put(voterId, true);
    #ok()
  };

  // Get current vote results
  public query func getResults() : async [Candidate] {
    candidates
  };

  // Get list of candidates
  public query func getCandidates() : async [Text] {
    Array.map<Candidate, Text>(candidates, func(c) { c.name })
  };

  // Check if a voter has already voted
  public shared(msg) func hasVoted() : async Bool {
    switch (votedFor.get(msg.caller)) {
      case (null) { false };
      case (?_) { true };
    }
  };

  // Get total number of registered voters
  public query func getTotalVoters() : async Nat {
    voters.size()
  };
}
