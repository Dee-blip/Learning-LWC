trigger SC_LiveChatTranscript on LiveChatTranscript (before insert, after insert, before update, after update) {
    // Jarvis Akachat Logic - Create Cases for Jarvis Chats
    // ACC Duplicate Chat Cases fix
    if(Trigger.isUpdate && Trigger.isBefore){
        scJarvisLiveChatHandler.createCasesForTranscripts(Trigger.new);
    }
    
    if(Trigger.isInsert && Trigger.isAfter){
        List<Id> lAllCaseIds = new List<Id>();
        for(LiveChatTranscript eachrec : Trigger.New){
            if(eachrec.CaseId != null)
            	lAllCaseIds.add(eachrec.CaseId);
        }
        
        List<Id> lCaseIdForMilestone = new List<Id>();
        for(Case eachrec : [Select id, RecordType.Name from Case where Id in :lAllCaseIds]){
            if(eachrec.RecordType.Name == 'Technical' || eachrec.RecordType.Name == 'AMG')
                lCaseIdForMilestone.add(eachrec.Id);
        }        
		        
        List<CaseMilestone> lCaseMilestones = new List<caseMilestone>();
        for(CaseMilestone eachrec : [Select id, MilestoneType.Name, CaseId, StartDate, CompletionDate, IsCompleted from CaseMilestone
                                    			where CaseId in:lCaseIdForMilestone and
                                                IsCompleted = false and
                                                MilestoneType.Name IN ('Initial Response') and
                                     case.IsClosed = false]){
        	eachrec.CompletionDate = eachrec.StartDate;  
            lCaseMilestones.add(eachrec);
		}
        
        if(lCaseMilestones.size() > 0)
            update lCaseMilestones;
    }
}