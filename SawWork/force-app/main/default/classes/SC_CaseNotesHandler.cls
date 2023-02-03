public class SC_CaseNotesHandler {
    
    public static void handleCaseNotes(Set<Id> CaseIdSet){
        system.debug('----CaseIdSet---'+CaseIdSet);
        List<Case> caseFeedItemList = new List<Case>();
        List<Case> caseList = new List<Case>();
        if(CaseIdSet.size()>0){
            system.debug('----CaseIdSet Size---'+CaseIdSet.size());
            caseFeedItemList = [Select id,Last_Case_Update__c,RecordType.Name,isClosed from Case where Id IN :CaseIdSet and isClosed = false];
            Case newCase;
            for(Case eachCase :caseFeedItemList){
                if(eachCase.RecordType.Name =='Managed Security'){
                    newCase = new Case();
                    newCase.Id = eachCase.Id;
                    newCase.Last_Case_Update__c = System.now();
					caseList.add(newCase);
                    system.debug('----eachCase---'+eachCase);
                }
            }
            system.debug('----caseIdList---'+caseList);
            if(caseList.size() >0)
                update caseList; 
        }  
    }  
}