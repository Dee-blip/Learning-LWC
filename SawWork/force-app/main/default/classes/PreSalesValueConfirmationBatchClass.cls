global class PreSalesValueConfirmationBatchClass implements Database.Batchable<Sobject>, Database.Stateful{

    global final string query;
    global DMLResults results;
    
    global PreSalesValueConfirmationBatchClass()
    {
        query = 'select Id, Name, OwnerId, Global_Account_Relationships__c, AKAM_Account_ID__c, Account_Status__c, Target_Category__c, Division_Formula__c, Commercial_Segmentation__c, Geography_Formula__c, Owner.alias, Owner.IsActive, (Select id, UserId, AccountId from AccountTeamMembers where TeamMemberRole = \'Technical Sales - Primary\' and user.IsActive = true limit 1) from Account where Division_Formula__c In (\'Web\',\'Media & Carrier\') and (NOT Account_Status__c Like \'%Inactive%\') and (NOT Account_Status__c Like \'%Lead%\')';
 
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc)
    { 
         results = new DMLResults();
         return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        List<Account> filteredAccounts = new List<Account>();
        List<Account> acc = new List<Account>();
       
        Integer year= Date.Today().Year();
        //To get the current year
        String currentYear = (string.valueOf(year)).substring(2);   
        //To get the current Fiscal Quarter.
        Integer currentQtr = Decimal.valueOf(Date.Today().month()).divide(3.0, 0, System.RoundingMode.UP).intValue(); 

        List<String> quarterlyCommercialSegmentType = new List<String>(); 
        List<String> halfYearlyCommercialSegmentType = new List<String>();
        List<String> accountPoolUserAlias = new List<String>();
        
        for(String quarterlyCommercialSegmentValue : GsmUtilClass.getGSMSettingValue('Quarterly_Commercial_Segment_Value').split(',')){            
            quarterlyCommercialSegmentType.add(quarterlyCommercialSegmentValue.trim());
        }

        for(String halfYearlyCommercialSegmentValue : GsmUtilClass.getGSMSettingValue('Half_Yearly_Commercial_Segment_Value').split(',')){            
            halfYearlyCommercialSegmentType.add(halfYearlyCommercialSegmentValue.trim());
        }

        for(String accountPoolUserAliasValue : GsmUtilClass.getGsmSettingValue('Account_Pool_Users').split(',')){            
            accountPoolUserAlias.add(accountPoolUserAliasValue.trim());
        }


        //TotalAccount is a map of (account id, user id for whom task is created+','+account name)
        Map<Id, Id> totalAccount = new Map<Id, Id>(); 
        
        acc = (List<Account>)scope;

        for(Account account: acc){
            //Criteria for Web Division
            if(account.Division_Formula__c == 'Web' && account.AccountTeamMembers.size() > 0){
                totalAccount.put(account.Id, account.AccountTeamMembers[0].UserId);
            }
            //Criteria for Media Division
            else if(account.Division_Formula__c == 'Media & Carrier' && (account.Global_Account_Relationships__c == account.AKAM_Account_ID__c || account.Global_Account_Relationships__c == null) && account.Commercial_Segmentation__c != null){
                if(quarterlyCommercialSegmentType.contains(account.Commercial_Segmentation__c) && account.AccountTeamMembers.size() > 0){
                    totalAccount.put(account.Id, account.AccountTeamMembers[0].UserId);
                }
                else if(currentQtr == 1 || currentQtr == 3){
                    if(account.Commercial_Segmentation__c == 'Standardized: IAE' && account.Geography_Formula__c == 'Media EMEA' && !AccountPoolUserAlias.contains(account.Owner.alias) && account.Owner.IsActive){
                        totalAccount.put(account.Id, account.OwnerId);
                    }else if(account.Commercial_Segmentation__c == 'Standardized: IAE' && account.Geography_Formula__c != 'Media EMEA' && account.AccountTeamMembers.size() > 0){
                        totalAccount.put(account.Id, account.AccountTeamMembers[0].UserId);
                    }
                    else if(halfYearlyCommercialSegmentType.contains(account.Commercial_Segmentation__c) && account.AccountTeamMembers.size() > 0){
                        totalAccount.put(account.Id, account.AccountTeamMembers[0].UserId);
                    }
                }
            }
        }

        System.debug('Map content  '+totalAccount);

        Date startDate;
        if(currentQtr == 1){
            startDate = date.newinstance(year, 1, 1);
        }
        else if(currentQtr == 2){  
            startDate = date.newinstance(year, 4, 1);
        }
        else if(currentQtr == 3){
            startDate = date.newinstance(year, 7, 1);
        }
        else{
            startDate = date.newinstance(year, 10, 1);
        }

        //List of all the DSR with type - "CBR"
        List<Deal_Support_Request__c> dsrListTobeInserted = new List<Deal_Support_Request__c>();

        //Creating new DSR.
        Integer count=0;
        for(Id accountId : totalAccount.keyset()){

            count++;

            Deal_Support_Request__c dsr = new Deal_Support_Request__c();
            dsr.Account__c = accountId;
            dsr.OwnerId = totalAccount.get(accountId);
            dsr.SE__c = totalAccount.get(accountId);
            dsr.POC_Status__c = 'Planned';
            dsr.Request_Type__c = 'CBR';
            //dsr.RecordTypeId = Deal_Support_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Pre-Sales Engagement').getRecordTypeId();
            dsr.RecordTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Pre_Sales_Engagement').getRecordTypeId();
            dsr.Start_Date__c = startDate;
            dsrListTobeInserted.add(Dsr);

        }
        if(dsrListTobeInserted.size() > 0){
            System.debug('Inside task:  '+dsrListTobeInserted);
            System.debug('counter  :'+count);
            results.add(Database.insert(dsrListTobeInserted,false),dsrListTobeInserted);
        }
    }
    
     global void finish(Database.BatchableContext BC){
        
        results.withJobName('\'Automation of Task Creation for Pre Sales Group\'').toAddress(GsmUtilClass.getGSMSettingValue('PreSalesValueBatchClass_EmailId')).sendLogMail();
        results.withClassName('PreSalesValueConfirmationBatchClass').insertRecordsInErrorLog();
    
    }
    
}