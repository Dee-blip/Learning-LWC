/* History:
* =========================
* @author  Himanshu Verma,  14th May 2020 
MARIT-488
*/
public without sharing class MARIT_TaskTriggerClass {
    public static void innerUpdateActivityCount(Task[] tasks, String eventType)
    { 
        Map<String, Lead> leadMap = new Map<String, Lead>();
        String akamLeadIDs = null;
        // Custom metdadata check
        String marketoProfileIDs = null;
        List<GSM_Settings__mdt> gsmSetting = [SELECT MasterLabel, Value__c FROM GSM_Settings__mdt where DeveloperName like 'MarketoProfileIDs'];
        if(gsmSetting.size() > 0){
            marketoProfileIDs = gsmSetting.get(0).Value__c;
        }
        List<String> akamLeadIDList = new List<String>();
        // Creating string of Akam Lead IDs
        for (Task t2 : tasks){
            if(!marketoProfileIDs.contains(Userinfo.getProfileId()) && t2.Associated_AKAM_Lead_ID__c != null){
                akamLeadIDList.add(t2.Associated_AKAM_Lead_ID__c);
            }
        }
        if(akamLeadIDList.size() > 0){
            
            List<Lead> leads = [Select id, All_Call_Activities_Count__c, Disposition__c, All_Email_Activities_Count__c, All_Other_Activities_Count__c, Last_Activity_By__c, Last_Activity_Date__c, Recent_Status_Disposition_Change_By__c, Recent_Status_Disposition_Date__c, AKAM_Lead_ID__c, status from Lead where AKAM_Lead_ID__c in :akamLeadIDList];
            
            // Inserting in map of Akam Lead ID, Lead object
            for(Lead l1 : leads){
                leadMap.put(l1.AKAM_Lead_ID__c , l1);
            }
            
            // Loop tasks to increment count
            for (Task t2 : tasks)
            {
                Lead lead;
                lead  = leadMap.get(t2.Associated_AKAM_Lead_ID__c);
                if(lead != null){
                    system.debug('MARIT-488, lead: '+lead);
                    if(eventType == 'Insert'){
                        if(t2.Subject.containsIgnoreCase('Skipped')){
                            continue;
                        }
                        if(t2.type__c == 'Email' || t2.Type == 'Email'){
                            //   t2.type__c = 'Email';
                            if(lead.All_Email_Activities_Count__c == null){
                                lead.All_Email_Activities_Count__c = 0;
                            }
                            lead.All_Email_Activities_Count__c += 1;
                        } else if((t2.type__c == 'Call' || t2.type == 'Call') || (t2.type__c == 'Phone' || t2.type == 'Phone')){
                            //      t2.type__c = 'Call';
                            if(lead.All_Call_Activities_Count__c == null){
                                lead.All_Call_Activities_Count__c = 0;
                            }
                            lead.All_Call_Activities_Count__c += 1;
                        } else {
                            if(lead.All_Other_Activities_Count__c == null){
                                lead.All_Other_Activities_Count__c = 0;
                            }
                            lead.All_Other_Activities_Count__c += 1;
                        }
                        // Update Lead Status from New to In Process if that is the first activity of the lead and status is New
                        if(lead.status == 'New' && (lead.All_Call_Activities_Count__c + lead.All_Email_Activities_Count__c + lead.All_Other_Activities_Count__c == 1)){
                            lead.status = 'In Process';
                            lead.Disposition__c = 'In Process';
                        }
                        
                    } else if(eventType == 'Delete'){
                        if((t2.type__c == 'Email' || t2.type == 'Email') && lead.All_Email_Activities_Count__c != null){
                            lead.All_Email_Activities_Count__c -= 1;
                        } else if((t2.type__c == 'Call' || t2.type == 'Call') && lead.All_Call_Activities_Count__c != null){
                            lead.All_Call_Activities_Count__c -= 1;
                        } else if(lead.All_Other_Activities_Count__c != null){
                            lead.All_Other_Activities_Count__c -= 1;
                        }
                    }
                    lead.Last_Activity_Date__c = t2.AKAM_Created_Date__c;
                    lead.Last_Activity_By__c = t2.AKAM_Created_By__c;
                    lead.Validation_Override__c = true;
                    leadMap.put(t2.Associated_AKAM_Lead_ID__c, lead);
                }
                
            }
            // check on DML results class
            update leads;
        }
    }
    
    //MARIT-961
    public static void getManagersForNewOners(List<Task> taskListToGetManagers, Map<Id, String> ownerIDToManagerNameMap){
        
        List<User> userList = [Select id, Manager__c from User where id in :ownerIDToManagerNameMap.keySet()];
		System.debug('Mayank, calling userList:' +userList);
        for(User u1: userList){
            ownerIDToManagerNameMap.put(u1.id, u1.Manager__c);
        }

        for(Task n1: taskListToGetManagers){
            n1.SC_Manager__c = ownerIDToManagerNameMap.get(n1.OwnerId);
            System.debug('Mayank, n1:' +n1);
        }

    }
    
    public static void migrateTaskToOpenCTAFromPerson(List<Id> taskIds){
        List<Id> taskWhoId = new List<Id>();
        List<Task> taskList = [Select Id, WhoId, WhatId from Task where Id in :taskIds];
        for(task task: taskList){
            taskWhoId.add(task.WhoId);
        }
        Map<Id, Id> leadsMap = new Map<Id, Id>();
        try{
            for (lead l :[Select Id,Associated_Contact__c,Parent_Lead__c from Lead where Recordtype.name = 'Akamai Lead' and Status in ('New','In Process') and (Associated_Contact__c in :taskWhoId or Parent_Lead__c in :taskWhoId)]){
                
                    if(l.Parent_Lead__c!=null){
                        leadsMap.put(l.Parent_Lead__c, l.Id);
                    }
                    if(l.Associated_contact__c!=null){
                        leadsMap.put(l.Associated_contact__c, l.Id);
                    }
                
            }
            if(leadsMap!= null && !leadsMap.keySet().isEmpty()){
                for(Task t: taskList){
                    if(leadsMap.containsKey(t.whoId)){
                    t.WhatId = null; //setting null if earlier task was assigned to contact it would error out since lead can't have what id
                    t.WhoId = leadsMap.get(t.WhoId);
                    }
                }
            }
            if(taskList != null && !taskList.isEmpty()){
                update taskList;
            }
        }
        catch(Exception e){
            Error_Log__c el = new Error_Log__c(Name='migrateTaskToOpenCTAFromPerson', Class__c='MARIT_TaskTriggerClass', Error_Message__c=e.getMessage());
            insert el;
        }
    }

    public static void stampOwnerOnCTAFromAssignedTo(List<Id> taskList){
    
        Map<Id,Id> taskMap = new Map<Id,Id>();
        List<Lead> ctaOwnerUpdate = new List<Lead>();
        String driftAlias = MarketingUtilClass.getMarketingSettingsValue('DriftAlias');
        Id globalCatchAllId = MarketingUtilClass.getMarketingSettingsValue('GlobalCacheCatchQueue');
        Id marketoSyncUserId = GSMSettings.getValue('MarketoSyncUserId');
        
        try{
            for(task t: [Select Id,OwnerId,Owner.Alias,WhoId,Who.recordtype.name from Task where Id in :taskList and Who.recordtype.name = 'Akamai Lead']){
                if(t.Owner.Alias != driftalias){
                    taskMap.put(t.WhoId,t.OwnerId);
                }
            }
            if(taskMap != null && !taskMap.keySet().isEmpty()) {
                ctaOwnerUpdate = [Select id,OwnerId,Owner_Type__c from lead where id in : taskMap.keySet() and Owner_Type__c != 'Partner' and (Owner_Type__c = 'Queue' or OwnerId =: marketoSyncUserId)];
                for(Lead l: ctaOwnerUpdate){
                    l.OwnerId = taskMap.get(l.Id);
                    l.Validation_Override__c = true;
                }
                if(ctaOwnerUpdate != null && !ctaOwnerUpdate.isEmpty()){
                    update ctaOwnerUpdate;
                }
            }  
        }
        catch(Exception e){
            Error_Log__c el = new Error_Log__c(Name='stampOwnerOnCTAFromAssignedTo', Class__c='MARIT_TaskTriggerClass', Error_Message__c=e.getMessage());
            insert el;
           
        }
    }
   
}