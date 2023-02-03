//Author : Prateek Bhuwania, king of the Andals and the first men, Protector of this apex code
//Date: 17th of August, 2018
//WIZARDS-118 : laxmi - Moving soql & dml outside the loop
trigger WizardsVoteTrigger on Vote__c (after insert, after delete) {

    //get old votes to delete
    public List<Vote__c> getExistingVotes(String ideaId, String voter, String latestVoteRecordId, Map<Id, Map<Id, List<Vote__c>>> voteMap){
        if(voteMap.get(ideaId) != null) {
            if(voteMap.get(ideaId).get(voter) != null) {
                return voteMap.get(ideaId).get(voter);
            }
        }
        return null;
    }

    //after insert, delete old votes and insert new
    if(Trigger.isAfter && Trigger.isInsert){

        Decimal total;
        Map<String, Decimal> ideaToTotal = new Map<String, Decimal>();
        Set<Id> ideaIdList = new Set<Id>();
        Set<Id> voteIds = new Set<Id>();
        List<Vote__c> deleteVoteIds = new List<Vote__c>();
        Map<Id, Map<Id, List<Vote__c>>> voteIdMap = new Map<Id, Map<Id, List<Vote__c>>>();

        for(Vote__c vote: trigger.new){
            voteIds.add(vote.Id);
            ideaIdList.add(Vote.ParentId__c);
        }

        for(Vote__c vote: [select Id,ParentId__c,ActualCreator__c from Vote__c where ParentId__c IN: ideaIdList]) {
            if(! voteIds.contains(vote.Id)) {
                if(voteIdMap.get(vote.ParentId__c) != null){
                    Map<Id, List<Vote__c>> ownToVote = voteIdMap.get(vote.ParentId__c);
                    if(ownToVote.get(vote.ActualCreator__c) != null){
                        ownToVote.get(vote.ActualCreator__c).add(vote);
                    }
                    else {
                        ownToVote.put(vote.ActualCreator__c, new list<Vote__c> {vote});
                    }
                }
                else {
                    Map<Id, List<Vote__c>> ownToVote = new Map<Id, List<Vote__c>>();
                    ownToVote.put(vote.ActualCreator__c, new list<Vote__c> {vote});
                    voteIdMap.put(vote.ParentId__c, ownToVote);
                }
            }
        }

        for(Vote__c vote: trigger.new){

            //get exisitng votes and delete records. change total by type
            List<Vote__c> existingVotes = getExistingVotes(String.valueOf(Vote.ParentId__c), vote.ActualCreator__c, vote.Id, voteIdMap);
            if(existingVotes != null) {
                deleteVoteIds.addAll(existingVotes);
            }
        }
        delete deleteVoteIds;



        for(Vote__c vote: trigger.new){

            //store total in a map to update later.
            total = 0;
            if(ideaToTotal.containsKey(vote.ParentId__c)){
                total = ideaToTotal.get(vote.ParentId__c);
            }
            total = vote.Type__c == 'Up' ? total + 10 : total - 10;
            ideaToTotal.put(vote.ParentId__c, total);

        }

        //fetch vote total and update for all ideas.
        List<Idea> IdeasToUpdate = new List<Idea>();
        List<String> ideaIds = new List<String>(ideaToTotal.keySet());

        for(Idea ideaToUpdate : [select Id, VoteTotal__c from Idea where Id in :ideaIds]){
            total = ideaToUpdate.VoteTotal__c + ideaToTotal.get(ideaToUpdate.Id);
            Idea temp = new Idea();
            temp.Id = ideaToUpdate.Id;
            temp.VoteTotal__c = total;
            IdeasToUpdate.add(temp);
        }

        //If ideas that need to be updated has a non-zero count, we update
        if(IdeasToUpdate.size() > 0){
            update IdeasToUpdate;
        }
    }

    //DELETE TRIGGER TO REVERT VOTE TOTAL SCORE ON IDEA
    if(Trigger.isAfter && Trigger.isDelete){

        Decimal total;
        Map<String, Decimal> ideaToTotal = new Map<String, Decimal>();

        for(Vote__c deletedVote: trigger.old){
            total = 0;
            if(ideaToTotal.containsKey(deletedVote.ParentId__c)){
                total = ideaToTotal.get(deletedVote.ParentId__c);
            }
            total = deletedVote.Type__c == 'Up' ? total - 10 : total + 10;
            ideaToTotal.put(deletedVote.ParentId__c, total);
        }

        List<String> ideaIds = new List<String>(ideaToTotal.keySet());
        List<Idea> IdeasToUpdate = new List<Idea>();

        for(Idea ideaToUpdate : [select Id, VoteTotal__c from Idea where Id in :ideaIds]){
            total = ideaToUpdate.VoteTotal__c + ideaToTotal.get(ideaToUpdate.Id);
            Idea temp = new Idea();
            temp.Id = ideaToUpdate.Id;
            temp.VoteTotal__c = total;
            IdeasToUpdate.add(temp);
        }

        //If ideas that need to be updated has a non-zero count, we update them
        if(IdeasToUpdate.size() > 0){
            update IdeasToUpdate;
        }

    }
}