global class ScheduleAutoFollow implements Schedulable{
   global void execute(SchedulableContext SC) {
       autoFollowRecord(); //calling function which autoFollows Account and Opportunity record.
   }
   
   public void autoFollowRecord()
   {
        
       // List<Id> atmIdList = new List<Id>(); //List for collection of Ids of AccountTeamMembers
        List<Id> otmIdList = new List<Id>(); //List for collection of Ids of OpportunityTeamMembers
        List<AccountTeamMember> atmList = new List<AccountTeamMember>(); 
        Map<Id,List<AccountTeamMember>> atmMap = new Map<Id,List<AccountTeamMember>>();
    
        List<EntitySubscription> esList = new List<EntitySubscription>(); //List of entity subscription
        Map<String, EntitySubscription> existingSubs = new Map<String, EntitySubscription>(); //Map for entity subscription
        
        //Get the List of Opportunity Team Members and Account Team members added today or yesterday in the database.
        List<AccountTeamMember> atmList1 = [Select a.UserId, a.TeamMemberRole, a.IsDeleted, a.Id, a.CreatedDate, a.CreatedById, 
                                            a.AccountId, a.AccountAccessLevel 
                                            From AccountTeamMember a 
                                            where (createdDate = TODAY OR createdDate = YESTERDAY)
                                            And (TeamMemberRole = 'Services - Primary'
                                            OR TeamMemberRole = 'Services - Secondary')];
                                            
        List<Case> caseList = [Select Id,AccountId,CaseNumber
                               From Case 
                               Where (createdDate = TODAY OR createdDate = YESTERDAY)
                               And Severity__c Like '1%'];
        
        List<Id> cases = new List<Id>();
        map<Id,List<Id>> accountUserMap = new map<Id,List<Id>>();
        
        if(caseList.size() != 0){
        	set<Id> aIds = new set<Id>();
        	set<Id> acIds = new set<Id>();
        	for(Case c : caseList){
        		aIds.add(c.AccountId);
        	}
        	for(Entitlement ent :[Select e.SlaProcess.Name, e.SlaProcessId, e.Status,
                                       e.AccountId 
                                From Entitlement e 
                                where AccountId IN :aIds
                                AND (SlaProcess.Name like '%Priority%' 
                                OR SlaProcess.Name like '%Premium%') 
                                AND Status = 'Active' ]){
	        	acIds.add(ent.AccountId);
	        }
        	for(AccountTeamMember atm : [Select a.UserId, a.TeamMemberRole, a.IsDeleted, a.Id, a.CreatedDate, a.CreatedById, 
                                       a.AccountId, a.AccountAccessLevel 
                                       From AccountTeamMember a 
                                       where (TeamMemberRole = 'Services - Primary'
                                       OR TeamMemberRole = 'Services - Secondary')
                                       AND AccountId IN :acIds]){
        		if(accountUserMap.containsKey(atm.AccountId)){
        			accountUserMap.get(atm.AccountId).add(atm.UserId);
        		}
        		else{
        			accountUserMap.put(atm.AccountId,new List<Id>{atm.userId});
        		}
        	}
        	for(Case c : caseList){
        		if(accountUserMap.containsKey(c.AccountId)){
        			cases.add(c.Id);
        		}
        	}
        }
                                            
        if(atmList1.size()!=0)
        {
            for(AccountTeamMember a: atmList1)
            {
               // atmIdList.add(a.AccountId); // collect ids of Accounts
              if(!atmMap.containsKey(a.AccountId)){
                atmMap.put(a.AccountId,new List<AccountTeamMember> {a});
              }
              else{
                atmMap.get(a.AccountId).add(a);
              }
            }
        }
      
      Set<Id> accIdSet = new Set<Id>();
      for(Entitlement ent :[Select e.SlaProcess.Name, e.SlaProcessId, e.Status,
                                   e.AccountId 
                            From Entitlement e 
                            where AccountId IN :atmMap.keySet() 
                            AND (SlaProcess.Name like '%Priority%' 
                            OR SlaProcess.Name like '%Premium%') 
                            AND Status = 'Active' ]){
        if(!accIdSet.contains(ent.AccountId) && atmMap.containsKey(ent.AccountId)){
            accIdSet.add(ent.AccountId);
          //atmIdList.add(ent.AccountId);
          atmList.addAll(atmMap.get(ent.AccountId));
        }
      }
      system.debug('---atmList---'+atmList);
      map<Id,List<Case>> caseMap = new map<Id,List<Case>>();
      set<Id> caseIds = new set<Id>();
      for(Case csObj :[select Id,AccountId
                       from Case
                       where AccountId IN :accIdSet
                       And Severity__c Like '1%']){
      	if(caseMap.containsKey(csObj.AccountId)){
      		caseMap.get(csObj.AccountId).add(csObj);
      	}
      	else{
      		caseMap.put(csObj.AccountId, new List<Case>{csObj});
      	}
      	caseIds.add(csObj.Id);
      }
      
      set<String> keyStringSet = new Set<String>();
      if(accIdSet.size()!=0 || caseIds.size() != 0 || cases.size() != 0) {
        //get existing entitysubscription for Accounts and Opportunities
        List<EntitySubscription> existingSubscriptionList = [select SubscriberId, ParentId 
                                                             from EntitySubscription 
                                                             where ParentId in :accIdSet
                                                             OR ParentId IN :caseIds
                                                             OR ParentId IN : cases];
            
          //prepare a Map with key as string subscriber+parentId to check if new records already exist in database.
          for (EntitySubscription es : existingSubscriptionList) {
            existingSubs.put((String)es.SubscriberId + es.ParentId, es);
          }
        }
       
        for(AccountTeamMember atm: atmList) {
	        //check if the record already exist in Map. If not, then create new EntitySubscription record and add in List
	        if(existingSubs.containsKey((string)atm.UserId+(string)atm.AccountId)==false
	         && keyStringSet.contains((string)atm.UserId+(string)atm.AccountId) == false )
	        {
            EntitySubscription newSub = new EntitySubscription(parentId = atm.AccountId, SubscriberId = atm.UserId);
            esList.add(newSub);
            keyStringSet.add((string)atm.UserId+(string)atm.AccountId);
	        }
	        if(caseMap.containsKey(atm.AccountId)){
	          for(Case cs : caseMap.get(atm.AccountId)){
		    	    if(existingSubs.containsKey((string)atm.UserId+(string)cs.Id)==false &&
		    	       keyStringSet.contains((string)atm.UserId+(string)cs.Id) == false){
		    	   	  EntitySubscription newSub = new EntitySubscription(parentId = cs.Id, SubscriberId = atm.UserId);
		            esList.add(newSub);
		            keyStringSet.add((string)atm.UserId+(string)cs.Id);
		    	    }
	          }
	        }
	     }
       //system.assert(false,accountUserMap +'----------------');
       if(cases.size() != 0){     
        for(Case c: caseList){
        	if(accountUserMap.containsKey(c.AccountId)){
        		for(Id uId : accountUserMap.get(c.AccountId)){
        			if(existingSubs.containsKey((string)uId+(string)c.Id)==false && 
        			   keyStringSet.contains((string)uId+(string)c.Id) == false){
                EntitySubscription newSub = new EntitySubscription(parentId = c.Id, SubscriberId = uId);
                esList.add(newSub);
                keyStringSet.add((string)uId+(string)c.Id);
                system.debug('--Case--'+c.CaseNumber+'==='+uId);
              }
        		}
        	}
       	  
        }
       }     
        //If new EntitySubscription records are present then Insert them.
        if(esList.size()!=0)
        {
            system.debug('esList.size()--->'+esList.size());
            try{
                upsert esList;
            }
            catch(DMLException e){
                system.debug('Exception----->'+e);
            }
        }
   }
}