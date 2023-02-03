Public class L2Q_NewAccountCreationController{
    
    
    @AuraEnabled
    public static String getErrorMessage(id recordId) 
    {
        string ErrorMessage='';
        String ProfileIds = GsmUtilClass.getGSMSettingValue('ACRProfileId'); 
        
        Account_Creation_Request__c  AccReqRec=[select id,Name,Website__c,City__c,Zip_Postal_Code__c,Street__c,State__c,Country__c,status__c,account__c,CreatedbyId,Account_Name__c from Account_Creation_Request__c where id=:recordId];
        
         if(!ProfileIds.contains(UserInfo.getprofileid())){
            
            
            ErrorMessage = GsmUtilClass.getGSMSettingValue('ACRCreateAcc');
            
        }
        else If(AccReqRec.status__c !='In-Progress'){
            
            
            ErrorMessage = GsmUtilClass.getGSMSettingValue('ACRStatusError');
            
        }
        else if(AccReqRec.Account__c != null){
            ErrorMessage =GsmUtilClass.getGSMSettingValue('ACRAlreadyAcc');
        }
        
        return ErrorMessage;
    }
    
@AuraEnabled
public Static String CreateNewAccount(id RecId){
    
    list<account> acctList =new list<account>();
    Boolean DuplicateFlag =false;
    String error ='Error :';
    string Accinfo ='Duplicate Records Found::';
    Id accReassignmentRuleID ;
    system.debug('value::'+RecId);
    Account_Creation_Request__c  AccReqRec=[select id,Vertical__c,Sub_Vertical__c,Assign_To__c,Name,Website__c,City__c,Zip_Postal_Code__c,Street__c,State__c,Country__c,status__c,account__c,CreatedbyId,Account_Name__c,Request_Created_By__c from Account_Creation_Request__c where id=:RecId];
        system.debug('value::2'+AccReqRec);
    //SFDC-6598 - Assign and fetch Assignment Rule selected else assign to No Owner-ONA, added new field to skip assignment from trigger -IsAccountGovernanceProcessed__c
    
    if(AccReqRec.Assign_To__c != null)
        accReassignmentRuleID = AccReqRec.Assign_To__c;
    else 
        accReassignmentRuleID = Id.valueOf(GsmUtilClass.getGSMSettingValue('ONA_Rule_Id'));
    Account_Reassignment_Rule__c accReassignRule =  [select Name, Id, Associated_User__c from Account_Reassignment_Rule__c where Id =: accReassignmentRuleID];
system.debug('ARR ==== '+accReassignRule);
    //Create New Account 
    Account acc=new Account();
    acc.Name=AccReqRec.Account_name__c;
    acc.Website = AccReqRec.Website__c;
    acc.BillingCountry = AccReqRec.Country__c;
    acc.BillingPostalCode =AccReqRec.Zip_Postal_Code__c;
    acc.BillingState = AccReqRec.State__c;
    acc.BillingStreet = AccReqRec.Street__c;
    acc.BillingCity = AccReqRec.City__c;
    //SFDC-6598 changes- V,SV and Owner
    acc.Vertical__c = AccReqRec.Vertical__c;
    acc.Sub_Vertical__c = AccReqRec.Sub_Vertical__c;
    acc.IsAccountGovernanceProcessed__c = true;
    
   // SFDC-8735 Changes - Rajul Vishwakarma
   // SFDC-9191 Bug
   String businessOpsIdsList = GsmUtilClass.getGSMSettingValue('Business_Ops_User_Ids');
   if(businessOpsIdsList.contains(Userinfo.getUserId()) && businessOpsIdsList.contains(AccReqRec.Request_Created_By__c)){
       acc.Ops_Validated__c = UserInfo.getUserId();
       acc.Last_Validated_Date__c = System.today();
   }
    if(accReassignRule!= null)
        acc.OwnerId = accReassignRule.Associated_User__c;

    try{
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult sr = Database.insert(acc, dml);
            if (sr.isSuccess()) { 
                AccReqRec.Validation_Override__c =true;
                AccReqRec.account__c=acc.id;
                AccReqRec.status__c ='Closed - Complete';
                update AccReqRec;
                //SFDC-6598 - Create and auto approve Account Reassignment Request for the Owner
                List<Account_Reassignment__c> accReassignList = new List<Account_Reassignment__c>();
                Account_Reassignment__c accReassign = new Account_Reassignment__c();
                accReassign.Account__c = acc.Id;
                accReassign.Assign_To__c = accReassignRule.Id;
                accReassign.CurrencyIsoCode = acc.CurrencyIsoCode;
                accReassign.Reassign__c = true;
                accReassignList.add(accReassign);
                GsmUtilClass.doDatabaseInsert(accReassignList,'L2Q_NewAccountCreationController','CreateNewAccount',false);

                return acc.id;
            }
            else{
                for(Database.Error err : sr.getErrors()) {
                    
                    System.debug('The following error has occurred.');                   
                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    error += err.getMessage();
                }
                system.debug(error);
                return error;
            }
            
            
        }   
    catch(Exception e){
        system.debug('Error::'+e.getMessage());
        throw new AuraHandledException(e.getMessage()); 
} 
     
}
    @AuraEnabled
    public Static list<sobject> DupAccountCheck(id RecIds){
        
        string Accinfo ='Akam' ;
        system.debug('value::'+RecIds);
        Account_Creation_Request__c  AccReqRec=[select id,Name,Website__c,City__c,Zip_Postal_Code__c,Street__c,State__c,Country__c,status__c,account__c,CreatedbyId,Account_Name__c from Account_Creation_Request__c where id=:RecIds];
        list<account> acctList =new list<account>();
        list<sobject> acctList1 =new list<sobject>();
        //set<sobject> Accountset = new set<sobject>();
        //Create New Account 
        Account acc=new Account();
        acc.Name=AccReqRec.Account_name__c;
        acc.Website = AccReqRec.Website__c;
        acc.BillingCountry = AccReqRec.Country__c;
        acc.BillingPostalCode =AccReqRec.Zip_Postal_Code__c;
        acc.BillingState = AccReqRec.State__c;
        acc.BillingStreet = AccReqRec.Street__c;
        acc.BillingCity = AccReqRec.City__c;
        
        //system.debug(sr);
        acctList.add(acc);
        try{
        //Find Duplicate Accounts
        Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(acctList);
        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        string Akamid='AKAM Account Id::'+ matchRecord.getRecord().get('AKAM_Account_ID__c');
                                if(!Accinfo.contains(Akamid)){
                                    Accinfo +='Account Name::'+matchRecord.getRecord().get('Name') + 'AKAM Account Id::'+ matchRecord.getRecord().get('AKAM_Account_ID__c')+'\n';
                                 
                        acctList1.add(matchRecord.getRecord());
                        system.debug('acctList1'+acctList1);
                    }
                    }
                }
            }
        } 
       }catch(Exception e){
        system.debug('Error::'+e.getMessage());
        throw new AuraHandledException(e.getMessage()); 
    } 
            return acctList1;
        
        }

}