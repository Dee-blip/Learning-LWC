/*
Author          : Sheena,Vamsee,Vishnu,Himanshu
Description     : Helper Class for all the Triggers of SI
Called From		: 
Test Class		: SC_SI_AllTestCases_TC

Date                Developer              JIRA #                 Description                                                       
------------------------------------------------------------------------------------------------------------------
14 Aug 2020         Himanshu               ESESP-3795             Initial Version
26 Feb 2020         Harshil                ESESP-4859             Populate/de-populate 'Customer Advisory' based on 
                                                                  External field and Incident Stage
------------------------------------------------------------------------------------------------------------------

*/
public class SC_SI_AllTriggerHelperClass {
    
    
    // Method - 1 : Called from SC_SI_Impacted_Account_Trigger, Used for Tier Calculations
    public static void UpdateTierDistribution(set<ID> IncomingIncidentList){
        
        // Map to store SI ID + All Tier Values
        Map<ID, string> tierName_countMap = new Map<ID, string>(); 
        
        // List of SI to Update
        List<SC_SI_Service_Incident__c> SIUpdateList = new List<SC_SI_Service_Incident__c> (); 
        SC_SI_Service_Incident__c eachSIRec;
        
        // Map Key
        string mapKey;    		
        
        // 2-Level Aggregate Query to get the Result
        AggregateResult[] groupedResults = [select Service_Incident__c SI,Account_Name__r.Customer_Tier__c Tier, count(id) 
                                            from SC_SI_Impacted_Account__c 
                                            where Service_Incident__c = :IncomingIncidentList and Account_Name__r.Customer_Tier__c != null
                                            and From_Proactive_Case__c != true
                                            group by Service_Incident__c, Account_Name__r.Customer_Tier__c 
                                            order by Service_Incident__c,Account_Name__r.Customer_Tier__c];
        
        // Iterate the Result
        for (AggregateResult ar : groupedResults)  {
            
            mapKey = string.valueOf(ar.get('SI'));
            if(tierName_countMap.containsKey(mapKey)){
                
                tierName_countMap.put(mapKey, tierName_countMap.get(mapKey) + ' | ' + string.valueOf(ar.get('Tier')) +  ' : ' + Integer.valueOf(ar.get('expr0')));
            }
            else{
                tierName_countMap.put(mapKey, string.valueOf(ar.get('Tier')) +  ' : ' + Integer.valueOf(ar.get('expr0')));
            }
            
        }
        
        // Loop for each Incoming SI
        for (ID eachSI_RecID : IncomingIncidentList){
            
            // Setting value of each SI Record
            eachSIRec = new SC_SI_Service_Incident__c(ID = eachSI_RecID, Tier_Distribution__c = tierName_countMap.get(eachSI_RecID),
                                                      Validation_Override__c = true);
            SIUpdateList.add(eachSIRec);
        }
        
        if(SIUpdateList.size() > 0){
            Update SIUpdateList;
            
        }
        
        // Finally Calling to updateSI_ImpactedAccountTableField method 
        // for constructing HTML Table for Top 10 Accounts and process asynchronously
        if(!System.isBatch())
            updateSI_ImpactedAccountTableField(IncomingIncidentList);
        
    }
    
    // Method - 2 : Called from UpdateTierDistribution Method, Used for Constructing HTML Table for Top 10 Accounts
    @future
    public static void updateSI_ImpactedAccountTableField(Set<Id> IncidentSet){
        
        // Getting the Report ID
        String reportId = [SELECT  Value__c FROM SC_SI_Service_Incident_Utility__mdt WHERE DeveloperName = 'Impacted_Account_Report_ID'].Value__c;
        
        // List of SI to Update
        List<SC_SI_Service_Incident__c> SIUpdateList = new List<SC_SI_Service_Incident__c> ();
        SIUpdateList = [select ID,Impacted_Accounts_Table__c,Name,
                        (select Account_Name__r.Customer_Tier__c, Account_Name__r.Name, Account_Name__r.Support_Level__c, 
                         Account_Name__r.Geography_Formula__c from Impacted_Accounts__r where Account_Name__r.Customer_Tier__c != null
                        order by Account_Name__r.Customer_Tier__c, Account_Name__r.Geography_Formula__c)
                        from SC_SI_Service_Incident__c 
                        where ID IN :IncidentSet];
        
        // Loop for each SI Record
        for(SC_SI_Service_Incident__c eachSIRec : SIUpdateList){
            
            eachSIRec.Impacted_Accounts_Table__c = ConstructHTMLTable(eachSIRec.Impacted_Accounts__r, eachSIRec.Name, reportId);
            eachSIRec.Validation_Override__c = true;
            
        }
        
        // Update all SI
        update SIUpdateList;
    }
    
    // Method - 3 : for Constructing HTML Table for Top 10 Accounts
    Public Static String ConstructHTMLTable(List<SC_SI_Impacted_Account__c> impactedAccountlist, String IncidentNumber, String reportId){
        String accountTable = '<html><head><link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">'+
            '<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>'+
            '<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>'+
            '<style>table {width:60%;}table, th, td {border: 1px solid black;border-collapse: collapse;}th, td {padding: 10px;text-align: center;}'+
            'table#t01 th {background-color: rgb(0, 109, 204);color: white;height: 60px;}body{padding: 30px;}.btn {background-color: rgb(0, 109, 204);}</style>'+
            '</head><body><table id="t01"><tr ><th>Account</th><th>Geo</th><th>Tier</th><th>Support Level</th></tr>';
        
        //Variable to store count
        Integer tierCount = 0;
        For(SC_SI_Impacted_Account__c eachDetail : impactedAccountlist){
            tierCount++;
            if(tierCount>10)
                Break;
            accountTable+= '<tr><td>'+ eachDetail.Account_Name__r.Name  + '</td><td>' + 
                (eachDetail.Account_Name__r.Geography_Formula__c != null ? eachDetail.Account_Name__r.Geography_Formula__c : '-') + 
                '</td><td>'+ eachDetail.Account_Name__r.Customer_Tier__c +'</td><td> '+ 
                (eachDetail.Account_Name__r.Support_Level__c != null ? eachDetail.Account_Name__r.Support_Level__c : '-' ) + '</td></tr>';
        }
        accountTable+=   '</table><br/><br/>List of Impacted Accounts is available <a href= "'+ URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Report/'+reportId+'/view?fv0='+IncidentNumber+'">here</a></body></html>';
        
        return accountTable;
        
    }
    
    // Method - 4 : To restrict deletion for Non-IRAPT Users if the Status is not 'Incident Request'
    public static void restrictObjectDeletion_NonIRAPTUser(List<sObject> sObjectList){
        
        // Getting details of LoggedIn User
        User u = [select Id, SC_SI_IRAPT_User__c from User where Id = :UserInfo.getUserId()];
        if(!u.SC_SI_IRAPT_User__c){
            for(sObject eachRec : sObjectList){
                if(eachRec.get('Incident_Status__c')!= 'Incident Request'){
                    eachRec.addError('You are not authorized to delete this record.');
                }
            }
        }
    }
    
    // Method - 5 : Called from SC_SI_ED_Trigger, Get Jira Info
    public static void getJiraInfo(List<SC_SI_External_Dependency__c> extDepList_New, Map<ID,SC_SI_External_Dependency__c> extDepList_OldMap,
                                   boolean isInsert){
                                       
		   // To store Jira ID List to be passed
		   Set<String> jiraIdset = new Set<String>();
		   List<SC_SI_External_Dependency__c> edFilteredList = new List<SC_SI_External_Dependency__c>();
		   
		   // Loop for all Ext Dep Records
		   for(SC_SI_External_Dependency__c eachED : extDepList_New){
			   
			   // Condition for getting Valid Jira
			   if ( (isInsert && eachED.Type__c == 'Jira') || 
				   (!isInsert && eachED.Type__c == 'Jira' && ((eachED.Type__c != extDepList_OldMap.get(eachED.Id).Type__c) || 
															  eachED.Ticket_Number__c != extDepList_OldMap.get(eachED.Id).Ticket_Number__c)) ){
																  
																  //Always Jira IDs in Upper Case
																  eachED.Ticket_Number__c = eachED.Ticket_Number__c.toUppercase();
																  
																  jiraIdset.add(eachED.Ticket_Number__c);	
																  edFilteredList.add(eachED);
															  }
		   }
		   
		   // Calling Jira Helper Method to get the data
		   if(jiraIdset.size() > 0){
			   
			   //Map to store the Jira Ids and Corresponding SF Id
			   Map<String, String> jiraRecordIdMap = New Map<String, String>();
			   
			   //Call Create Method
			   jiraRecordIdMap = SC_JiraTicketInfo_Handler.createJiraRecords(jiraIdset);
			   
			   //Populate the Lookup field
			   for(SC_SI_External_Dependency__c eachED : edFilteredList){
				   eachED.Jira_Ticket_Info__c = jiraRecordIdMap.get(eachED.Ticket_Number__c);
			   }
			   
		   }
		   
	}
    
    // Method - 6 : Called from SC_SI_EmailBE_Trigger, Update User record
    public static void updateBusinesExecOnUser(List<Id> userIdlist, boolean beCheckboxValue){
        List<User> userUpdateList = new List<User>();
        User userRecord;
        for(Id eachUserId : userIdlist){
            userRecord = new User(Id = eachUserId, SC_SI_Email_Business_Exec__c = beCheckboxValue);
            userUpdateList.add(userRecord);
        }
        Update userUpdateList;
    }
    
    // Method - 7 : Called from SC_SI_Trigger, Pre Populate Incident record fields
    public static void prePopulateIncidentFields(List<SC_SI_Service_Incident__c> newIncidentList, Map<Id,SC_SI_Service_Incident__c> oldIncidentMap, boolean isInsert){
        
        // Getting Value from Custom MDT
        SC_SI_Service_Incident_Utility__mdt incidentSetting = [SELECT Value__c FROM SC_SI_Service_Incident_Utility__mdt WHERE DeveloperName = 'Email_Config_Id'];
        
        // Loop for all Incoming Incidents
        For(SC_SI_Service_Incident__c eachIncident : newIncidentList){
            
            //Populate the Email Config Record Id
            if(!Test.isRunningTest())
            	eachIncident.Email_Config__c = incidentSetting.Value__c;
            
            //If User is not populating the Requested By field while Creating then populate it with Logged in User.
            eachIncident.Incident_Requested_By__c  = eachIncident.Incident_Requested_By__c == null ?  Userinfo.getUserId() : eachIncident.Incident_Requested_By__c;
            
            //Copy Summary Field into Summary Text field (This needed for Email Business Exec Quick action.. Remove all the Images)
            if(eachIncident.Summary__c != null)
                eachIncident.Summary_Text__c = eachIncident.Summary__c.replaceAll('<img[^>]+\\></img>','');
            
            //Multi select picklist cannot be used in Email templates and Quick actions
            eachIncident.Type_of_Customer_Impact_Text__c =  eachIncident.Type_Of_Customer_Impact__c != null ? 
                eachIncident.Type_Of_Customer_Impact__c.Replace(';',', ') : '';
            
            // Additional Logic for Insert
            if(isInsert){
                //Populate Incident Requested Date
                eachIncident.SI_Incident_Requested_Date__c = eachIncident.SI_Incident_Requested_Date__c == null ? System.now() : eachIncident.SI_Incident_Requested_Date__c;
                
                eachIncident.Impact_Started__c  = eachIncident.Impact_Started__c  == null ? System.now() : eachIncident.Impact_Started__c;
                
                if(eachIncident.Is_Migrated__c == False && eachIncident.Status__c != 'Incident Request' && eachIncident.External__c == true)
                	eachIncident.Customer_Advisory__c = 'We have identified an issue with "Product Name" where users may experience "issue(s)" with "symptom1", and/or "symptom2", and/or "symptom3".' +
                    	'The issue appears to have started around <b>' + eachIncident.Impact_Started__c.formatGMT('dd/MM/YYYY HH:MM') + ' UTC.</b> We are actively working on the mitigation and will keep this '+
                    	'advisory updated as we make progress. We apologize for the impact. <br/><br/> In the interest of time, we are providing you the most current information available, which is subject '+ 
                    	'to changes, corrections and updates.';
                
                eachIncident.Status_Path__c = (eachIncident.Status__c != 'Rejected' && eachIncident.Status__c != 'Canceled') ? eachIncident.Status__c : '';
            }
            else{
                eachIncident.Impact_Started__c  = eachIncident.Impact_Started__c  == null ? eachIncident.CreatedDate : eachIncident.Impact_Started__c;
                
                // Logic for Status change
                if(eachIncident.Status__c != oldIncidentMap.get(eachIncident.Id).Status__c){
                    
                    //Assign the Owner field with Logged In user Id when Status is changing from Incident Request and Owner is not an User;/
                    if((oldIncidentMap.get(eachIncident.Id).Status__c == 'Incident Request') && (!String.valueOf(eachIncident.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix())))
                        eachIncident.OwnerId = Userinfo.getUserId();
                    
                    if(oldIncidentMap.get(eachIncident.Id).Status__c == 'Incident Request' && eachIncident.External__c == true)
                        eachIncident.Customer_Advisory__c = 'We have identified an issue with "Product Name" where users may experience "issue(s)" with "symptom1", and/or "symptom2", and/or "symptom3".' +
                    	'The issue appears to have started around <b>' + eachIncident.Impact_Started__c.formatGMT('dd/MM/YYYY HH:MM') + ' UTC.</b> We are actively working on the mitigation and will keep this '+
                    	'advisory updated as we make progress. We apologize for the impact. <br/><br/> In the interest of time, we are providing you the most current information available, which is subject '+ 
                    	'to changes, corrections and updates.';
                        
                    
                    eachIncident.Status_Path__c = (eachIncident.Status__c == 'Rejected' || eachIncident.Status__c == 'Canceled') ?
                        '' : eachIncident.Status__c;
                }
                else if(eachIncident.Status_Path__c != oldIncidentMap.get(eachIncident.Id).Status_Path__c){
                    eachIncident.Status__c = eachIncident.Status_Path__c;
                }
                else if(oldIncidentMap.get(eachIncident.Id).External__c == true && eachIncident.External__c == false)
                    eachIncident.Customer_Advisory__c = '';
                else if(oldIncidentMap.get(eachIncident.Id).External__c == false && eachIncident.External__c == true)
                    eachIncident.Customer_Advisory__c = 'We have identified an issue with "Product Name" where users may experience "issue(s)" with "symptom1", and/or "symptom2", and/or "symptom3".' +
                    'The issue appears to have started around <b>' + eachIncident.Impact_Started__c.formatGMT('dd/MM/YYYY HH:MM') + ' UTC.</b> We are actively working on the mitigation and will keep this '+
                    'advisory updated as we make progress. We apologize for the impact. <br/><br/> In the interest of time, we are providing you the most current information available, which is subject '+ 
                    'to changes, corrections and updates.';
            }
        }
        
    }
    
    // Method - 7 : Called from SC_SI_Trigger, To update child Transition Record for New Owner field /Marking Completed
    public static void updateLatestTransitionRecordForNewOwner(Map<Id,SC_SI_Service_Incident__c> oldSIMap,Map<Id,SC_SI_Service_Incident__c> newSIMap){
        
        // For List of SI IDs
        Set<Id> serviceIndidentToUpdateTransition = new Set<Id>();
        
        // Transition List to Update
        List<SC_SI_Transition_Request__c> transitionsToUpdateNewOwner = new List<SC_SI_Transition_Request__c>();
        String transitionQueueId = [select Id from Group where Name = 'ATS_IRAPT_TRANSITION_QUEUE' and Type = 'Queue'].Id;
        
        //Iterating over SI to filter SIs where owner is changed and earlier owner was transition queue.
        for(SC_SI_Service_Incident__c iteratedIncident : newSIMap.values()){
            
            if(iteratedIncident.ownerId != oldSIMap.get(iteratedIncident.Id).ownerId 
               && iteratedIncident.ownerId.getSObjectType().getDescribe().getName() == 'User' 
               && oldSIMap.get(iteratedIncident.Id).ownerId == transitionQueueId){
                   serviceIndidentToUpdateTransition.add(iteratedIncident.Id);
               }
        }
        
        if(serviceIndidentToUpdateTransition.size() > 0){
            
            for(SC_SI_Service_Incident__c itrSI : [Select Id,(Select Id,SC_SI_New_Owner__c,SC_SI_Completed__c,SC_SI_Completed_Date__c from Transition_Requests__r where  SC_SI_New_Owner__c ='' order By createdDate desc limit 1) from SC_SI_Service_Incident__c where Id IN: serviceIndidentToUpdateTransition]){
                
                // Always get 1 Transition rec per each SI
                for(SC_SI_Transition_Request__c itrTransition : itrSI.Transition_Requests__r){
                    
                    itrTransition.SC_SI_New_Owner__c = newSIMap.get(itrSI.Id).ownerId;
                    itrTransition.SC_SI_Completed__c = true;
                    itrTransition.SC_SI_Completed_Date__c = System.now();
                    transitionsToUpdateNewOwner.add(itrTransition);
                }                   
            }    
            
            if(transitionsToUpdateNewOwner.size() > 0){
                update transitionsToUpdateNewOwner;
            }
        }    
        
    }
    
    // Method 8 : Called from SC_SI_Trigger - To restrict users from deleting Service Incident
    public static void restrictSIDeletion(List<SC_SI_Service_Incident__c> incidentList){
        //CRM Ops should be able to delete the records 
        if(UserInfo.getName() != 'CRM Ops'){
            for(SC_SI_Service_Incident__c eachIncident: incidentList){
                eachIncident.addError('You are not authorized to delete this record.');
            }
        }
    }
    
    // Method 9 : Called from SC_SI_Trigger - To update last queue change date/time
    public static void updateQueueChangeDatetime(Map<Id,SC_SI_Service_Incident__c>oldSIMap,List<SC_SI_Service_Incident__c>newSIList,String event){
      
        Id serviceIncidentQueueId =  [select Id from Group where Name = 'SERVICE_INCIDENTS_QUEUE' and Type = 'Queue' limit 1].Id;
        Id transitionQueueId =  [select Id from Group where Name = 'ATS_IRAPT_TRANSITION_QUEUE' and Type = 'Queue' limit 1].Id;
        if(event == 'Update'){
            for(SC_SI_Service_Incident__c iteratdSI : newSIList){
                if((iteratdSI.ownerId == serviceIncidentQueueId || iteratdSI.ownerId == transitionQueueId) && iteratdSI.ownerId != oldSIMap.get(iteratdSI.Id).ownerId){
                    iteratdSI.SC_SI_Queue_Change__c = System.now();
                }
            }
    	}else if(event == 'Create'){
        	for(SC_SI_Service_Incident__c iteratdSI : newSIList){
                if(iteratdSI.ownerId == serviceIncidentQueueId || iteratdSI.ownerId == transitionQueueId)
                iteratdSI.SC_SI_Queue_Change__c = System.now();
            }    
    	}
       
    }
    
}