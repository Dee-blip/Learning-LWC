public class SC_Autogen_SOA_Reminder_Support {
    
    List<Merge_Contract_Detail__c> detailList = new List<Merge_Contract_Detail__c>();
    List<String> productIdSOAList = new List<String>();
    List<SC_Utility__mdt> utilityList = new List<SC_Utility__mdt>([Select DeveloperName,Value__c from SC_Utility__mdt where DeveloperName IN ('Autogen_SOA_Add_Subtract_Days','Autogen_SOA_Case_Products')]);// This needs to go in custom metadatatype
    List<Merge_Contract_Detail__c> detailListForCaseCreation = new List<Merge_Contract_Detail__c>();
    //Map<Id,Integer> detailReviewCountMap;
    Integer dayToAddSubFromCurrentDate = 0; // gives flexibility to run job to process contracts which were missed due to failure
    Date currentDate = Date.valueOf(System.Today());
    public void main_SOA_Method(List<Merge_Contract_Header__c> allReturnContracts)
    {
        for(SC_Utility__mdt forEachRec :utilityList){
            if(forEachRec.DeveloperName == 'Autogen_SOA_Case_Products'){
                productIdSOAList = forEachRec.Value__c.split(',');
            }
            else if(forEachRec.DeveloperName == 'Autogen_SOA_Add_Subtract_Days'){
                dayToAddSubFromCurrentDate = Integer.valueOf(forEachRec.Value__c);
            }
        }
        
        //detailReviewCountMap = new Map<Id,Integer>();
        
        Date executionDate  = Date.valueOf(System.Today()+dayToAddSubFromCurrentDate);
        
        detailList = [Select Id, Name, Effective_Start_Date__c, Effective_End_Date__c, Original_Contract_Id__c,Original_Contract_Id__r.Account_Name__c,
                      Original_Detail_Id__c,Product_Id__c, Units_Low__c, Product__c, Unit_of_Measure__c  from Merge_Contract_Detail__c where Original_Contract_Id__c IN :allReturnContracts 
                      and Unit_of_Measure__c ='Reviews' and Product_Id__c IN : productIdSOAList and Effective_End_Date__c != Null and Effective_Start_Date__c != Null];
        system.debug('---detailList---'+detailList);
        
        if(detailList.size() >0){
            
            for(Merge_Contract_Detail__c forEachDetail :detailList){
                system.debug('---forEachDetail---'+forEachDetail);
                Integer contractTermInDays = forEachDetail.Effective_Start_Date__c.daysBetween(forEachDetail.Effective_End_Date__c) == 0 ? 1 : forEachDetail.Effective_Start_Date__c.daysBetween(forEachDetail.Effective_End_Date__c);
                Decimal totalReviewCount = (contractTermInDays/335.0)*forEachDetail.Units_Low__c;
                Integer reviewInterval =  Integer.valueOf((contractTermInDays/totalReviewCount).round(System.RoundingMode.HALF_UP));
                
                system.debug('---contractTermInDays---'+contractTermInDays);
                system.debug('---totalReviewCount---'+totalReviewCount);
                system.debug('---reviewInterval---'+reviewInterval);
                system.debug('---executionDate---'+executionDate);
                for(integer i=1; i<= Integer.valueOf(totalReviewCount.round(System.RoundingMode.HALF_UP));i++){
                    
                    if(executionDate <= (forEachDetail.Effective_End_Date__c -15)){
                        Date effectiveReviewStartDate = forEachDetail.Effective_Start_Date__c +(reviewInterval*i);
                        system.debug('---effectiveReviewStartDate---'+effectiveReviewStartDate);
                        if(executionDate == effectiveReviewStartDate){
                            detailListForCaseCreation.add(forEachDetail);
                            //detailReviewCountMap.put(forEachDetail.Id,i);
                            break;
                        }
                    }
                }
            }
            system.debug('---detailListForCaseCreation---'+detailListForCaseCreation);
            if(detailListForCaseCreation.size()>0)
                getAccountTeamDetails(detailListForCaseCreation);
            
            //clearing list
            detailListForCaseCreation.clear();
        }  
    }
    
    public void getAccountTeamDetails(list<Merge_Contract_Detail__c> detailList){
        system.debug('---Inside getAccountTeamDetails---'+detailList);
        Map<Id,List<Merge_Contract_Detail__c>> accountContractDetailMap = new Map<Id,List<Merge_Contract_Detail__c>>();
        
        for(Merge_Contract_Detail__c forEachLine : detailList){
            if(accountContractDetailMap.containsKey(forEachLine.Original_Contract_Id__r.Account_Name__c)){
                List<Merge_Contract_Detail__c> contLineItemList = accountContractDetailMap.get(forEachLine.Original_Contract_Id__r.Account_Name__c);
                contLineItemList.add(forEachLine);
                accountContractDetailMap.put(forEachLine.Original_Contract_Id__r.Account_Name__c,contLineItemList);
            }
            else{
                accountContractDetailMap.put(forEachLine.Original_Contract_Id__r.Account_Name__c, new List<Merge_Contract_Detail__c>{forEachLine});
            }
        }
        
        Map<Id,String> accountUserMapForPrimaryRole = new Map<Id,String>();
        for(Account acc : [select id,(Select Id,UserId, TeamMemberRole, AccountId, Title,User.isActive from AccountTeamMembers) from Account where Id IN :accountContractDetailMap.keyset()]){
            integer priorityVal = 5;  
            accountUserMapForPrimaryRole.put(acc.Id,'None');
            for(AccountTeamMember eachAtm : acc.AccountTeamMembers){
                
                if(eachAtm.Title != Null && eachAtm.User.isActive && !eachAtm.Title.contains('Solutions Architect')){ 
                    
                    if(eachAtm.TeamMemberRole == 'PS - Primary'){
                        if(!eachAtm.Title.contains('Technical Project Manager') && priorityVal > 4){
                            accountUserMapForPrimaryRole.put(eachAtm.AccountId,eachAtm.UserId);
                            priorityVal = 4;
                        }
                        if(eachAtm.Title.contains('Technical Project Manager') && priorityVal > 3){
                            accountUserMapForPrimaryRole.put(eachAtm.AccountId,eachAtm.UserId);
                            priorityVal = 3;
                        }
                        
                    }
                    if(eachAtm.TeamMemberRole == 'Security Services - Primary'){
                        if(!eachAtm.Title.contains('Technical Project Manager') && priorityVal > 2){
                            accountUserMapForPrimaryRole.put(eachAtm.AccountId,eachAtm.UserId);
                            priorityVal = 2;
                        }
                        if(eachAtm.Title.contains('Technical Project Manager') && priorityVal > 1){
                            accountUserMapForPrimaryRole.put(eachAtm.AccountId,eachAtm.UserId);
                            priorityVal = 1;
                            break;
                        }
                    }
                }  
            }
        }
        
        system.debug('---Exiting getAccountTeamDetails:accountUserMapForPrimaryRole---'+accountUserMapForPrimaryRole);
        system.debug('---Exiting getAccountTeamDetails:accountContractDetailMap---'+accountContractDetailMap);
        if(!accountUserMapForPrimaryRole.isEmpty())
            createCase(accountUserMapForPrimaryRole,accountContractDetailMap);
        
        //clearing Map
        accountUserMapForPrimaryRole.clear();
        accountContractDetailMap.clear();
    }
    
    //Case Creation
    public void createCase(Map<Id,String> accountUserMap,Map<Id,List<Merge_Contract_Detail__c>> accountDetailMap){
        system.debug('---Inside createCase---');
        Date executionDate  = Date.valueOf(System.Today()+dayToAddSubFromCurrentDate);
        Map<String,Case> existingCaseMap = new Map<String,Case>();
        for(Case eachCase :[Select id,Contract_Detail__c,Autogen_UseCase__c from Case where createddate >= :executionDate and Autogen_UseCase__c ='SOA-Review']){
            existingCaseMap.put(eachCase.Contract_Detail__c,eachCase); 
        }
        
        Id psRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        List<Case> caseListForInsert = new List<Case>();
        Case eachCase;
        for(Id eachAccId : accountDetailMap.keySet()){
            for(Merge_Contract_Detail__c eachLineItem :accountDetailMap.get(eachAccId)){
                system.debug('---Inside eachLineItem---'+eachLineItem);
                if(!existingCaseMap.containsKey(eachLineItem.Original_Detail_Id__c)){
                    String subjectStr = 'Threat Update Review #X';//detailReviewCountMap.get(eachLineItem.id);
                    String descStr =    'Please assign an SA to perform '+subjectStr+ ' based on XXXX firewall policy. Please use data from MM/DD/YYYY to MM/DD/YYYY. Customer review call will be scheduled for MM/DD/YYYY \n'+
                        				'Policy ID: \n'+
                                        'Data collection: \n'+
                                        'Project for time tracking: \n'+
                                        'Milestone: \n'+
                                        'Expected completion Date: \n'+
                                        'US citizen required?';
                    boolean assignementRuleFire = accountUserMap.containsKey(eachAccId) && accountUserMap.get(eachAccId) == 'None' ? true : false;
                    
                    eachCase = new Case();
                    eachCase.AccountId 					= eachAccId;
                    eachCase.RecordTypeId 				= psRecTypeId;
                    eachCase.Service__c 				= 'Security Optimization Assistance';
                    eachCase.Request_Type__c 			= 'Security Service Review';
                    eachCase.Origin 					= 'Autogen';
                    eachCase.Do_Not_Show_in_Portal__c 	= true;
                    eachCase.Severity__c 				= '3';
                    eachCase.Status 					= 'Unassigned';
                    eachCase.Subject					= subjectStr;
                    eachCase.Description 				= descStr;
                    eachCase.Contract__c 				= eachLineItem.Original_Contract_Id__c;
                    eachCase.Contract_Detail__c 		= eachLineItem.Original_Detail_Id__c;
                    eachCase.Autogen_UseCase__c 		= 'SOA-Review';
                    eachCase.Case_Assignment_Using_Active_Rules__c = assignementRuleFire;
                    if(!assignementRuleFire)
                        eachCase.OwnerId 				= accountUserMap.get(eachAccId);
                    eachCase.Validation_Override__c 	= true;
                    caseListForInsert.add(eachCase);
                }
            }
        }
        system.debug('---Exiting createCase:caseListForInsert---'+caseListForInsert);
        if(caseListForInsert.size()>0){
            try{
                insert caseListForInsert;
            }
            
            catch(Exception ex){
                
                string errorMessage =	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                    'Batch Class Name = SC_Autogen_SOA_Reminder_Batch\n' + 
                    'Support Class Name = SC_Autogen_SOA_Reminder_Support\n' +
                    'Method Name = main_SOA_Method\n';
                
                sendEmailForError('Exception: In Batch Job - SC_Autogen_SOA_Batch-Logs', errorMessage,caseListForInsert);
                
            }
        }
    }
    
    //Error Handling
    public void sendEmailForError(string emailSubject, string emailBody, List<Case> caseList)
    {    
        
        system.debug('---sendEmailForError---');
        
        string header = 'Contract Detail \t Account Id \t Contract Id \n';
        
        for(Case c: caseList)
        {
            
            header += c.Contract_Detail__c+'\t'+c.AccountId+'\t'+c.Contract__c +'\n';
        }
        
        system.debug('---header---'+header);
        
        Messaging.EmailFileAttachment[] AllExcelAttc = new Messaging.EmailFileAttachment[]{};
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(header);
        string csvname= 'SOA_Details_File'+'.xls';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        AllExcelAttc.add(csvAttc);
        
        // Fetch Support Email Address from Custom Setting - SC_SupportEmail__c
        SC_SupportEmail__c supEmailValues = SC_SupportEmail__c.getValues('1');
        
        // Setting To Address
        String[] toAdd = new String[] {};
            toAdd.add(supEmailValues.Support_Email_AutoGen__c);
        
        // Sending Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = emailSubject;
        mail.plainTextBody = emailBody;
        mail.setFileAttachments(AllExcelAttc);
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
    } 
    
}