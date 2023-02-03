//SFDC 9141
///calculate the Contract Length on Opportunity, whenever Start Date or End Date on the Contract Changes.

global class UpdateOpptyFromContractBatchClass extends GenericBatchClass implements Database.Batchable<Sobject>, Database.Stateful {
    //global final string query;
    global DMLResults opptyResults = new DMLResults(true);
    global DMLResults contractResults = new DMLResults(true);

   
    global UpdateOpptyFromContractBatchClass() {
        super();
        className = 'UpdateOpptyFromContractBatchClass';
        // SFDC-9285
        // Integer year22 = 2022; Cannot pass variable as genericbatchclass doesn't support it
        // query = 'SELECT id, Revision_Effective_Start_Date__c, Effective_Start_Date__c, Effective_End_Date__c ,(Select id, Contract_Length__c,Payout_Date__c,Rebate__c from Merge_Contracts__r where StageName  = 'Closed/Won') where sync_needed__c = true'
        query = 'Select id, Opportunity_Name__c, Revision_Effective_Start_Date__c, Effective_Start_Date__c, Effective_End_Date__c,Opportunity_Name__r.Rebate__c,Opportunity_Name__r.Account.name, Opportunity_Name__r.AccountId,Opportunity_Name__r.Partner_Involved__c,Opportunity_Name__r.Partner_Involved__r.POA_Email_List__c from Merge_Contract_Header__c where  sync_needed__c = true and Opportunity_Name__c != null and Opportunity_Name__r.StageName  IN (\'Closed Won\')   and   Opportunity_Name__r.Account.No_Rebate_Required__c = false and Opportunity_Name__r.Deal_Reg_Account_Status__c  IN (\'New Account\',\'Existing Account\') and CALENDAR_YEAR( Opportunity_Name__r.Deal_Registration_Approved_Date__c) >=2022';


    }

   /* global Database.QueryLocator start(Database.BatchableContext bc){ 
        

        contractResults = new DMLResults();
        return Database.getQueryLocator(query);
   }*/


    global override void execute(Database.BatchableContext bc, List<sObject> scope){
       Map<Id,Opportunity> rebateChangedOpptyMap = new Map<Id,Opportunity>();
	 List<Opportunity> errorList = new List<Opportunity>();
       List<merge_contract_header__c> contractList = (List<merge_contract_header__c>)scope;
        Map<Id,Opportunity> contractIdtoOppty = new map<Id, Opportunity>();
       List<Opportunity> updateOpptyList = new List<Opportunity>();
		system.debug(LoggingLevel.Error, 'contractList:: '+contractList);
       //Set<Opportunity> updateOpptyList = new Set<Opportunity>();
       //List<Opportunity> listStrings = new List<Opportunity>(setStrings);
		Set<id> opptyIds = new Set<Id>();
		List<Id> contractIdToOpportunityId = new List<Id>();
       for(merge_contract_header__c mch : contractList){
              //opptyIds.add(mch.Opportunity_Name__c);
              system.debug(LoggingLevel.Error, 'mch.Opportunity_Name__c::: '+mch.Opportunity_Name__c+' ::: '+mch.id);
           if(mch.Opportunity_Name__c!=null)
              contractIdToOpportunityId.add(mch.Opportunity_Name__c);
        }
       	//List<Opportunity> oppList = [select id, Account.name, Contract_Length__c,Payout_Date__c,Rebate__c,Partner_Involved__c from Opportunity where id in :opptyIds ];
		system.debug(LoggingLevel.Error, ':::contractIdToOpportunityId::: '+contractIdToOpportunityId);
        Map<Id,Opportunity> oppMap= new Map<Id, Opportunity>([select id, Name, Account.name, AccountId, Contract_Length__c,Payout_Date__c,Rebate__c,  Partner_Involved__c,Partner_Involved__r.POA_Email_List__c  from Opportunity where id in :contractIdToOpportunityId ]);
		system.debug(LoggingLevel.Error, ':::oppMap::: '+oppMap);
        // for (merge_contract_header__c mch : contractList){
        //     for(Opportunity opp : oppList){
        //         if (mch.Opportunity_Name__c == opp.id){
        //             contractIdtoOppty.put(mch.id, opp);
        //             break;
        //         }
        //     }
        // }      
        for(merge_contract_header__c mch : contractList){

            String initialRebate = mch.Opportunity_Name__r.Rebate__c;
            Opportunity opp = oppMap.get(mch.Opportunity_Name__c);
            //Rebate__c,Opportunity_Name__r.Account.name, Opportunity_Name__r.AccountId,Opportunity_Name__r.Partner_Involved__c
           /* opp.Rebate__c = mch.Opportunity_Name__r.Rebate__c;
            opp.AccountId = mch.Opportunity_Name__r.AccountId;
            opp.Account.name = mch.Opportunity_Name__r.Account.name;
            opp.Partner_Involved__c = mch.Opportunity_Name__r.Partner_Involved__c;
            opp.Partner_Involved__r.POA_Email_List__c = mch.Opportunity_Name__r.Partner_Involved__r.POA_Email_List__c;*/


                //oppMap.get(contractIdToOpportunityId.get(mch.id));
            opp = PRM_opportunity.updateOpptyFields(mch,opp);
            
            if(!opptyIds.contains(opp.id)){
                opp.validation_override__c = true;
            	updateOpptyList.add(opp);
                opptyIds.add(opp.id);
                if(initialRebate != opp.Rebate__c){
                rebateChangedOpptyMap.put(opp.id, opp);

            //OpportunityPRMTriggerClass.sendEmailWhenRebateChanges(opp);
            	}
            }
            
            mch.sync_needed__c = false;
            
        }

        List<Opportunity> rebateChangeOpptyList = new List<Opportunity>();
        
		
        if(updateOpptyList.size() >0){
            //opptyResults.dmlUpdate(updateOpptyList);
            Database.SaveResult[] srList = Database.update(updateOpptyList, false);
            //GsmUtilClass.doDatabaseUpdate(updateOpptyList,'UpdateOpptyFromContractBatchClass','UpdateOpptyFromContractBatchClass');
            
            for (Database.SaveResult sr : srList) {
                if(sr.isSuccess() && sr.getId()!=null && rebateChangedOpptyMap.get(sr.getId())!=null){
                    rebateChangeOpptyList.add(rebateChangedOpptyMap.get(sr.getId()));
                }
                // else{
                //      //taruni
                //      errorList.add(oppMap.get(sr.getId()));
                //  }
            
            }
             
            if(rebateChangeOpptyList.size()>0){
                
                OpportunityPRMTriggerClass.sendEmailWhenRebateChanges(rebateChangeOpptyList);
                
            }
            
            
            if(contractList.size()>0){
            	contractResults.dmlUpdate(contractList);
            }
            
        //    if(errorList.size() >0 )
        //   	 GsmUtilClass.doDatabaseUpdate(errorList,'UpdateOpptyFromContractBatchClass','UpdateOpptyFromContractBatchClass');
            


        }
        
		
		SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk = true;
    }

    global override void finish(Database.BatchableContext BC){
        super.finish(BC);
     System.Debug(LoggingLevel.Error, '**************  in finish');
    //opptyResults.withClassName('UpdateOpptyFromContractBatchClass').withJobName('Update Oppty From Contract').insertRecordsInErrorLog();
    //opptyResults.withJobName('Update Oppty From Contract').toAddress('tsunder@akamai.com').sendLogMail();

    //contractResults.withClassName('UpdateOpptyFromContractBatchClass').withJobName('Update Oppty From Contract').insertRecordsInErrorLog();
    //contractResults.withJobName('Update Oppty From Contract').toAddress('tsunder@akamai.com').sendLogMail();

    }



}