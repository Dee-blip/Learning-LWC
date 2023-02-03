/*=====================================================================================================+
    Class name          :   SC_CaseIssueClass 
    Author              :   Himanshu Kar
    Created             :   24-Jul-13
    Purpose             :   This class is called from "SC_Monacle_CaseIssue" Trigger on Case.
                            Req1# For Monacle Case Issue
                            Req2# For AutoGen Case 
    Last Modified       :   13-Feb-14
    Purpose             :   Initial Development
	Test Class			:	SC_CaseIssueClass_Test
    
Last Modified BY    Last Modified Date  	Purpose
----------------    ------------------  	---------
Himanshu            02-May-14           	Added method updateAttachment for Updating Attachments
Aditya Sonam 	    28-Nov-14			 	Added method for updating recordtype for Riverbed SAAS OEM
Himanshu		    17-Mar-15			 	Create Engagement Req for Premium Accounts(2871795)	
Aditya				07-May-15			 	Added method to stamp Report URL on ECOB Case
Himanshu Kar 		17-JUN-2016       	 	3333321(16.6)- For BOCC requirement
Himanshu Kar		17-AUG-2016    		 	3183601(16.8) - Service Cloud Compliance
Aditya Sonam 		21-Jun-2017			 	ESESP-534: BOCC Milestone Updates
Sumanth Naik        20-Sep-2017             ESESP-1356 Changing description to Contract Changes in 30 days
Himanshu/Sumukh 	27-Aug-2019			  	ESESP-2109 : SOCC Lightning Migration Changes
Vandhana            28-Feb-2020          	ESESP-2309 : Updated report link for ECOB cases
Vamsee S			17-Apr-2020				ESESP-1342(20.6):BOCC Lightning Migration
Pinkesh             24-Sep-2020             ESESP-3597 - Skipping Recent_Update__c=false if case updates coming from Akamai Control Center
+=====================================================================================================*/

public class SC_CaseIssueClass{
    
    //Boolean flag to byPass method updateRecentUpdateFlag_SOCC for EmailUpdates
    public static boolean byPassCaseIssueRUSOCC = false;
    
    /*Method-1 for Inserting Issue Record
    @Paramter - Map<Id,String>
    @Return Type - void 
    @Called From - SC_Monacle_CaseIssue Trigger On Case
    */
    public void insertcall(Map<Id,String> caseid_issuemap)
    {
        SC_Issues__c newIssueRec;         
        List<SC_Issues__c> IssueInsertList = new List<SC_Issues__c>();
         
        for(Id caseid : CaseId_issuemap.keyset()){
            newIssueRec                 = new SC_Issues__c();
            newIssueRec.Name  = caseid_issuemap.get(caseid);
            newIssueRec.Related_Case__c = caseid;
            newIssueRec.Case_Issue_Ext__c = caseid + '-' + caseid_issuemap.get(caseid);
            IssueInsertList.add(newIssueRec);
           
        }
        if(Issueinsertlist.size() > 0)
            Insert IssueInsertList;
    
    }
    
    /*Method-2 for Deleting old Records
    @Paramter - Map<Id,String>
    @Return Type - void 
    @Called From - SC_Monacle_CaseIssue Trigger On Case
    */
    public void deletecall(List<String> oldCaselist2)
    {
        List<SC_Issues__c> issueDeleteList = [Select id from SC_Issues__c where Case_Issue_Ext__c In :oldCaseList2];
        
        if(issueDeleteList <> Null && issueDeleteList.size() > 0)
            delete issueDeleteList;

    }

    /*Method-3 for Changing all Related Task Owner for the case
    @Paramter - Map<Id,Id>
    @Return Type - void 
    @Called From - SC_Monacle_CaseIssue Trigger On Case
    */
    public void changeTaskOwner_Case(Map<Id,Id> caseId_OwnerId_Map){

        // List to store Task
        List<Task> allTaskUpdateList = new List<Task>();   
    
    
        for(Task eachTaskrec : [select Id, WhoId,WhatId,Status,IsClosed
                                from Task 
                                where WhatId In :caseId_OwnerId_Map.keyset()
                                AND Status NOT IN ('Completed','Not Applicable')
                                AND IsClosed = TRUE])
                                
        {
            eachTaskrec.OwnerId =  caseId_OwnerId_Map.get(eachTaskrec.WhatId);
            allTaskUpdateList.add(eachTaskrec);         
        }
    
        // Update all Tasks
        if(allTaskUpdateList.size() > 0)
            Update allTaskUpdateList;
        
    } 
    
    /* Method-4 : 
     Called From : SC_Monacle_CaseIssue Trigger On Case
     Description : Based On CP Account Name, Populate corresponding AccountId
    */
    public void assignAccount(List<Case> caseList, set<String> accNameList) {
        
        // Account Name - Id Map
        Map<String,Id> accName_IdMap= new Map<String,Id>();
        
        // Loop for each Account
        for(Account eachAccRec :[select Id, Name from Account where name In :accNameList order by createdDate desc]){
        
            accName_IdMap.put(eachAccRec.Name, eachAccRec.Id);
        }
        
        // Loop for each case for Update
        for(case eachCaseRec : caseList){
            eachCaseRec.AccountID   =   accName_IdMap.get(eachCaseRec.CP_Account_Name__c);
        }
    }
     
    
    /* Method-5 : 
     Called From : SC_Monacle_CaseIssue Trigger On Case
     Description : To associate Task when a Case with issue!=null is created
    */
    public void taskInsert(Map<Id,Case> CaseRecsMap) {
   
	    List<Task> TaskList = new List<Task>();
	    Task newTaskRec;
	    Case caseRec;
	    List<Id> AccountIds = new List<Id>();
    
	    Map<Id,Case> CaseId_FieldsMap = new Map<Id,Case>([Select Id,Account.Name,Akam_Case_Id__c from Case where Id in :CaseRecsMap.keyset()]);
    
	    User userRec = [Select Id from User where IsActive = True and Alias = 'ONA' limit 1];
   
	    for(Id caseid : CaseRecsMap.keyset()){
		    
		    caseRec = CaseRecsMap.get(caseid);
		    
		    newTaskRec = new Task();
		    newTaskRec.WhatId = caseid;
		    newTaskRec.OwnerId = userRec.Id;
		    newTaskRec.Status='Not Started';
		    newTaskRec.Subject = '[AKAM-NOCC #'+caseRec.Issue__c+'] Akam Case Id:'+caseRec.CaseAutoId__c+' has been created in Service Cloud';
		    newTaskRec.Description = 'Case Details:\n Akam Case Id: '+ caseRec.CaseAutoId__c + '\n Severity: '+caseRec.Severity__c + '\n Subject: ' +caseRec.Subject+ '\nDescription: ' +caseRec.Description+ '\nAccount: ' +(CaseId_FieldsMap.get(caseid)).Account.Name+ '\n\nTo view this case please use this link:\n'+URL.getSalesforceBaseUrl().toExternalForm()+ '/' +caseid;
		     
		   TaskList.add(newTaskRec);     
	     }
	     
	    if(TaskList.size() > 0)
	    	insert TaskList;
    
    }
    
    
    /* Method-6 : 
     Called From : SC_Monacle_CaseIssue Trigger On Case
     Description : Update the Attachment for Cases whose Do not show in Portal = Unchecked and Attachment Name = Email.Html
    */
     public void updateAttachment(set<Id> caseIdForAttachmntUpdate) {
            
            // List to Update all Attachments
            List<Attachment> attmtUpdateList = new List<Attachment>();
            
            // Fetch all the Attachments
            for(Attachment attRec : [select Id,isprivate from Attachment where parentId In :caseIdForAttachmntUpdate and
                            Name = 'Email contents.html']){
                
                attRec.isprivate = True;            
                attmtUpdateList.add(attRec);
                            
            }
            
            // Update Attachments
            if(attmtUpdateList.size() > 0)
                Update attmtUpdateList;
     
     }

       
    /* Method-7 : 
     Called From : SC_Monacle_CaseIssue Trigger On Case
     Description : Changing Techincal Record Type for Riverbed SAAS OEM to Emerging Products Engineering 
    */
    public static void ChangeRecordType (  Set<Id> Caselist ){
    
	    //Store cases
	    List<Case> CaseRecord  = new List<Case>();
  
	    // Query fetches the records from case based on the ID passed by the trigger 
	    CaseRecord = [Select RecordTypeID,AccountID,Case_Product__c,Problem__c,Case_Product__r.Name from Case where Id IN : Caselist];
   
	    // Fetching RecordType ID of Emerging Products Engineering
	    ID CaseRecTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Emerging Products Engineering').getRecordTypeId();
    


	    //For each case which meets the criteria updating the field Product and Sub-area with Case Product and Problem respectively.
	    For(Case eachCase : CaseRecord){
		  
		  If( eachCase.Case_Product__c != null){   
		
			eachCase.ProductPL__c = eachCase.Case_Product__r.Name;
		  }
			
		  If(eachCase.Problem__c != Null ){
			
			eachCase.Sub_Area_EPE__c = eachCase.Problem__c; 
		  }
		
		
		  //Setting RecordType = Emerging Products Engineering
		  eachCase.RecordTypeID = CaseRecTypeID;
		
		  //For each case calling the assignment rule to set the owner based on record type
		  Database.DMLOptions dmo = new Database.DMLOptions();
		  dmo.assignmentRuleHeader.useDefaultRule = true;
		  dmo.EmailHeader.TriggerUserEmail = true;
		  eachCase.setOptions(dmo);  
	  
	  
	     }
     
	     try{
	     		update CaseRecord;
	     }
     
	     Catch(DmlException e){}
     
   } 
   
   /* Method-8 : 
    Called From : SC_Monacle_CaseIssue Trigger On Case
    Description : Create Engagement Req for Premium Accounts(CR# 2871795)
    */
   @future
   public static void createERForPrmAccounts(Set<Id> CaselistForER){
   
     	// Fetching RecordType ID of Emerging Products Engineering
      	ID ERRecTypeID = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('CCare Technical Escalation').getRecordTypeId();
      
     	// List to store All ER to be Inserted
     	List<Engagement_Request__c> allERInsertList = new List<Engagement_Request__c>();
     	
     	// Map to store Case Product - Area Mapping from Custom Setting
     	Map<string, string> caseProd_AreaMap = new Map<string, string>();
     	
     	// For Each ER record
     	Engagement_Request__c eachER;
     	
     	// Variable for Description
     	string setERDesc;
     	
     	// Loop for each value from Custom Setting - SC Case Product ER Mapping
        for(SC_Case_Product_ER_Mapping__c eachRec : SC_Case_Product_ER_Mapping__c.getall().values()){
              
        	caseProd_AreaMap.put(eachRec.Name,eachRec.ER_Area__c);
        }
     	
     	// Loop for all satisfied Cases
     	for(case eachCaseRec : [select Id,subject, description, Account.Name, Case_Product__r.Name 
     					from Case 
     					where Id In :CaselistForER and
     						Account.Auto_Escalate_Sev_1_Technical_Cases__c = True
     					]){
     		
     		// Setting Description
     		setERDesc = 'This is an automatically generated ER for - ' + eachCaseRec.Account.Name +
     				' Sev 1 Case. A Technical Expert must be engaged right away to work with the owner of this Case. \n\n' +
     				'Case Subject: ' + eachCaseRec.subject + '\n\n' +
     				'Case Description: ' + eachCaseRec.description;
     		setERDesc = (setERDesc.length() > 32001) ? setERDesc.substring(32000) : setERDesc;
     		
     				
     		// Creating ER Data
     		eachER = new Engagement_Request__c();
     		eachER.RecordTypeId = ERRecTypeID;
     		eachER.Area__c = (eachCaseRec.Case_Product__r.Name <> null && caseProd_AreaMap.get(eachCaseRec.Case_Product__r.Name) <> null) ?
     					caseProd_AreaMap.get(eachCaseRec.Case_Product__r.Name) :
     					caseProd_AreaMap.get('Default Value');
     					
     		eachER.Description__c = setERDesc;
     		eachER.Case__c = eachCaseRec.Id;
     		
     		allERInsertList.add(eachER);
     					
     	}
     	
     	// Insert all ER
     	Insert allERInsertList;
   
   }
   
  //Method called from SC_AUTOGEN_ECOB_SUPPORT to set the description field with Report Link
  // changes by Vandhana for ESESP-3197
   public static void ecobContractReport(list<case> caseECOBID)
   {
        List<Case> caseToUpdate = new List<case>();
        case eachUpdateCase;
        
        //Loop for all ECOB cases
        for(Case eachCaseRec : caseECOBID)
        {    
            // appending report url in description
            // changes by Vandhana JIRA ESESP-854, updated onboarding link
            eachUpdateCase = new Case(Id = eachCaseRec.Id);
            //ESESP-1356 Updating description to Contract changes in past 30 days:
            // ESESP-3197 : updated report link for lightning
            eachUpdateCase.description = eachCaseRec.description +'\n' + 'Contract changes in past 30 days: ' +'\n' +
                                        URL.getSalesforceBaseUrl().toExternalForm() +'/lightning/r/Report/' + 
                                        SC_ECOB_Report_ID__c.getValues('ECOB Contract-Detail Information').Report_ID__c +
                                        '/view?fv0='+eachCaseRec.id + '\n' + 
                                        'Please refer to the detailed on-boarding steps located at:' + '\n' +
                                        'https://ac.akamai.com/docs/DOC-9991';           
            
            if(eachCaseRec.Is_ECOB_Update__c == true)
            {
                eachUpdateCase.Is_ECOB_Update__c = true;
            }
            caseToUpdate.add(eachUpdateCase);
        }
        
        //Updating all ECOB Cases
        update caseToUpdate;
        
    }
    
    /* Method for creating BOCC Entitlement
     * [17/04/2020] Modified By Vamsee : BOCC record type is merging with technical cases as part of Lightning migration
     * Jira - ESESP-1342
	 */
    public void createBOCCEntitlement(set<ID> boccContractLnIds){

    	// List to Upsert Entitlements
    	List<Entitlement> allBOCCEntitlementUpsert = new List<Entitlement>();
             
      	// Map to store AccountId + List of Entitlements
     	Map<Id,List<Entitlement>> accountId_EntitlementListMap = new Map<Id,List<Entitlement>>();
         
      	//List to store all the Entitlements
      	List<Entitlement> EntitlementList;
          
      	//Map to store Account Id + Latest Effective Start Date
      	Map<Id,Date> AccountId_LEEDMap = new Map<Id,Date>();
          
      	//Setting key value
      	string mapKey;
      
      	//Query to fetch all Parent Account Ids    
      	for(Merge_Contract_Detail__c eachLine : [SELECT Original_Contract_Id__r.Account_Name__c,Effective_Start_Date__c, Effective_End_Date__c
                          						 FROM Merge_Contract_Detail__c WHERE Id in :boccContractLnIds]){
        
              mapKey = eachLine.Original_Contract_Id__r.Account_Name__c;
                
              // Calculation for AccountId_LEEDMap Map
              if(AccountId_LEEDMap.get(mapKey) == null){
                    AccountId_LEEDMap.put(mapKey,eachLine.Effective_End_Date__c);
              }
              else{
                    if(AccountId_LEEDMap.get(mapKey) < eachLine.Effective_End_Date__c){
                        AccountId_LEEDMap.put(mapKey,eachLine.Effective_End_Date__c);
                    }
              }                
      	}
        
        String boccEntitlementId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'Technical_BOCC_Entitlement_Id' AND Active__c = True LIMIT 1].Value_Text__c;
  		
    	// For Individual Entitlement record
    	Entitlement eachEntitlementRec;
    	
    	// Map to store Account Id - Account + Entitlement records
    	Map<Id, Account> accMap;
    	accMap = new Map<Id, Account>([SELECT Id,(SELECT Id, StartDate, EndDate, Entitlement_Name_Account__c FROM Entitlements 
                                        WHERE Name = 'Technical (BOCC)') FROM Account WHERE Id IN :AccountId_LEEDMap.keySet()]); 
      	
        for(Id eachAccountId : accMap.keyset()){
            accountId_EntitlementListMap.put(eachAccountId, accMap.get(eachAccountId).Entitlements); 
                
        }
    	
    	// Loop for all Account Ids
    	for(Id eachAccountId : AccountId_LEEDMap.keySet()){
    	
          // If it is New Account, then Insert Milestone otherwise Update.
    		if(accountId_EntitlementListMap.get(eachAccountId).isEmpty()){
      			eachEntitlementRec = new Entitlement();
                eachEntitlementRec.AccountId 	= eachAccountId;
                eachEntitlementRec.Name 		= 'Technical (BOCC)';
                eachEntitlementRec.Entitlement_Name_Account__c = 'Technical (BOCC)-' + eachAccountId;
                eachEntitlementRec.StartDate 	= system.today();
                eachEntitlementRec.EndDate 		= AccountId_LEEDMap.get(eachAccountId);
                eachEntitlementRec.SlaProcessId = boccEntitlementId;
                
                allBOCCEntitlementUpsert.add(eachEntitlementRec);
    		}
    		else{
                EntitlementList = accountId_EntitlementListMap.get(eachAccountId);    
                for(Entitlement eachExistingEnt : EntitlementList){
                    eachExistingEnt.EndDate 	= (AccountId_LEEDMap.get(eachAccountId) > eachExistingEnt.EndDate ) ?
                                                    AccountId_LEEDMap.get(eachAccountId) :
                                                    eachExistingEnt.EndDate;
                    
                    allBOCCEntitlementUpsert.add(eachExistingEnt);
            	}
			}
  		}
        
        if(allBOCCEntitlementUpsert.size() > 0)
            Upsert allBOCCEntitlementUpsert Entitlement_Name_Account__c;
        
    }
    
        
    // Method for Updating WorkType Field - 
    public void updateWorkType(List<Case> caseListForWorkTypeUpdate, map<Id, string> rTypesMap, boolean isInsert){
    
    		// Map to store SubType/RequestType + WorkType Values from SC WorkType Mapping CS
    		set<string> allValues = new set<string>();
    		
    		// Design the Key
    		string key;
    		
    		// Boolean to check whether current Logged in User is NOCC User or not
    		boolean isNOCCUser = false;
    		
    		// Setting the value only during Insert Time
    		if(isInsert && Userinfo.getProfileId() == SCUserIdCustomSetting__c.getValues('NOCC/Network Agent').UserId__c)
    			isNOCCUser = true;
    		
    		// Loop to iterate all the values
    		for(SC_WorkType_Mapping__c eachCSValue : SC_WorkType_Mapping__c.getall().values()){
    		
    			allValues.add(eachCSValue.RecType_SubType_ReqType_Map__c);
    		}
    		
    		// Iterating all the cases
    		for (Case eachCaseRec : caseListForWorkTypeUpdate){
    		
    			// For AMG Cases
    			if(rTypesMap.get(eachCaseRec.RecordTypeId).equals('AMG')){
    			
    				key = rTypesMap.get(eachCaseRec.RecordTypeId) + '-' + eachCaseRec.Service__c + '-' +
    					eachCaseRec.Request_Type__c ;
    			}
    			// For Technical Cases
    			else if(rTypesMap.get(eachCaseRec.RecordTypeId).equals('Technical')){
    			
    				key = rTypesMap.get(eachCaseRec.RecordTypeId) + '-' + eachCaseRec.Sub_Type__c + '-' +
    					eachCaseRec.Service_Category__c + '-' + eachCaseRec.Problem__c;
    					
    				// Setting Origin Value for NOCC/Network Agent Profile
    				if(isNOCCUser)
    					eachCaseRec.Origin = 'Akamai';
    			}
    			
    			// Assigning the Work type if present. Else leave it blank as system will take care the default value
    			if(allValues.contains(key) ){
    			
    				eachCaseRec.Work_Type__c = 'Proactive';
    			}
    			else
    			{
    				eachCaseRec.Work_Type__c = 'Reactive';
    			}
    		}
    }
    
    public void calculateNextActionDetails(List<Case> newCaseList, Map<Id,Case> oldCaseMap) {

// Variable to store the Case list for which Next Action Field is changed
List<Case> modifiedNextActionCaseList = new List<Case>();

// Step - 1 : Calculate if Next Action Field has changed
for(integer caseCount =0 ; caseCount < newCaseList.size(); caseCount++){
if(newCaseList[caseCount].Next_Action__c != oldCaseMap.get(newCaseList[caseCount].Id).Next_Action__c)
modifiedNextActionCaseList.add(newCaseList[caseCount]);
}

// Step - 2 : Call the setNextActionFieldvalues method
if(modifiedNextActionCaseList.size() > 0)
setNextActionFieldvalues(modifiedNextActionCaseList,oldCaseMap);
}

     public void setNextActionFieldvalues(List<Case> modifiedNextActionCaseList,Map<Id,Case> oldCaseMap) {
         
         Decimal getPrevious_Time_Spent_Customer;
         Decimal getPrevious_Time_Spent_CaseOwner;
         Decimal getPrevious_Time_Spent_Engg;
         
         for(Case eachCaserec : modifiedNextActionCaseList){
             
              getPrevious_Time_Spent_Customer = (eachCaserec.Previous_Time_Spent_Customer__c != null) ? 
        											eachCaserec.Previous_Time_Spent_Customer__c : 0;
        	  getPrevious_Time_Spent_CaseOwner = (eachCaserec.Previous_Time_Spent_Owner__c != null) ? 
        											eachCaserec.Previous_Time_Spent_Owner__c : 0;
         	  getPrevious_Time_Spent_Engg = (eachCaserec.Previous_Time_Spent_Engineering__c != null) ?
        											eachCaserec.Previous_Time_Spent_Engineering__c : 0;
             
             // 1. If Previous Next Action = Customer 
             if(oldCaseMap.get(eachCaserec.Id).Next_Action__c == 'Customer' && eachCaserec.Start_Time_for_Customer__c != null) {
                 eachCaserec.Previous_Time_Spent_Customer__c = getPrevious_Time_Spent_Customer + 
                     										((system.now().getTime())/1000/60) - ((eachCaserec.Start_Time_for_Customer__c.getTime())/1000/60);
             }
             else if(oldCaseMap.get(eachCaserec.Id).Next_Action__c == 'Case Owner' && eachCaserec.Start_Time_for_Owner__c != null) {
                 eachCaserec.Previous_Time_Spent_Owner__c = getPrevious_Time_Spent_CaseOwner + 
                     										((system.now().getTime())/1000/60) - ((eachCaserec.Start_Time_for_Owner__c.getTime())/1000/60);
             }
             else if(oldCaseMap.get(eachCaserec.Id).Next_Action__c == 'Engineering' && eachCaserec.Start_Time_for_Engineering__c != null) {
                 eachCaserec.Previous_Time_Spent_Engineering__c = getPrevious_Time_Spent_Engg +
                     											((system.now().getTime())/1000/60) - ((eachCaserec.Start_Time_for_Engineering__c.getTime())/1000/60);
             }
             
             // 1. For Next Action = Customer 
             if(eachCaserec.Next_Action__c == 'Customer'){
                 eachCaserec.IsStopped = true;
                 eachCaserec.Start_Time_for_Customer__c = system.now(); 
                 eachCaserec.Start_Time_for_Owner__c = null;
                 eachCaserec.Start_Time_for_Engineering__c  = null;
             }
             
             // 2. For Next Action = Case Owner 
             else if(eachCaserec.Next_Action__c == 'Case Owner'){
                 eachCaserec.IsStopped = false;
                 eachCaserec.Start_Time_for_Owner__c = system.now();
                 eachCaserec.Start_Time_for_Customer__c = null;
                 eachCaserec.Start_Time_for_Engineering__c  = null;
             }
             
             // 3. For Next Action = Engineering 
             else if(eachCaserec.Next_Action__c == 'Engineering'){
                 eachCaserec.IsStopped = false;
                 eachCaserec.Start_Time_for_Engineering__c  = system.now();
                 eachCaserec.Start_Time_for_Customer__c = null;
                 eachCaserec.Start_Time_for_Owner__c = null;
             }
             else{
                 eachCaserec.IsStopped = false;
                 eachCaserec.Start_Time_for_Engineering__c  = null;
                 eachCaserec.Start_Time_for_Customer__c = null;
                 eachCaserec.Start_Time_for_Owner__c = null;
             }
             
             
         }
     }

     //SOCC Lightning Migration changes -- ESESP-2198
     public void updateRecentUpdateFlag_SOCC(List<Case> allCases,map<Id, string> rTypesMap)
     {
		 System.debug(' ### updateRecentUpdateFlag_SOCC ' + byPassCaseIssueRUSOCC);
         //ESESP-3597 - Skipping Recent_Update__c=false if case updates coming from Akamai Control Center
		 String lPulsarUserId = '';
		 for(SC_Utility__mdt eachRec : [SELECT Id, Value_Text__c FROM SC_Utility__mdt WHERE Active__c=true AND DeveloperName LIKE 'Pulsar_Users%']) {
             lPulsarUserId += eachRec.Value_Text__c + ',';
		 }
         if(lPulsarUserId.contains(UserInfo.getUserId())) {
             byPassCaseIssueRUSOCC = true;
         }
         //ESESP-3597 - End of changes
        
        if(!byPassCaseIssueRUSOCC)
        {
            
            for(case eachCaserec : allCases)
            {       
                if(rTypesMap.get(eachCaseRec.RecordTypeId).equals('Managed Security'))
                {                
                    eachCaseRec.Recent_Update__c = false;
                    eachCaseRec.Last_Case_Update__c = Datetime.now();
                    
                    if(eachCaseRec.SOCC_Image_Banner_Category__c=='Managed Security: Policy Domain Pending' && eachCaseRec.Policy_Domain__c!=null)
                    {
                        eachCaseRec.SOCC_Image_Banner_Category__c='Managed Security: Contact Authorized';
                    }
                    if(eachCaseRec.SOCC_Image_Banner_Category__c=='Non Managed' && (eachCaseRec.Service_Category__c=='Managed Security'||eachCaseRec.Service_Category__c=='RRS'))
                    {
                        eachCaseRec.Is_Socc_Case_Authorized__c =false;
                        eachCaseRec.SOCC_Image_Banner_Category__c='';
                    }
                    if(eachCaseRec.SOCC_Image_Banner_Category__c=='Managed Security: Contact Authorized' && (eachCaseRec.Service_Category__c=='Internal'||eachCaseRec.Service_Category__c=='SOA'||eachCaseRec.Service_Category__c=='Non-Managed'))
                    {
                        eachCaseRec.Is_Socc_Case_Authorized__c =false;
                        eachCaseRec.SOCC_Image_Banner_Category__c='';
                    }
                }
                else if(rTypesMap.get(eachCaseRec.RecordTypeId).equals('Professional Services'))
                {
                    eachCaseRec.Plx_Update__c = false;
                }
            }
        }
    }
}