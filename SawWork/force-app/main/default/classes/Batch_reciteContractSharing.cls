/**
 * This Batch class is a clean up class used to give sharing to the Account Owner  in Case  if 
 * AccountOwner is not having an access  over the Contracts related to the Account.
 * History:
 * =========================
 * Developer        Date        Description
 * Rahul Gaira     25/07/2014   Created Class(CR-2697069)
 * --------------------------------------------------------------------------------------------------
 **/
global class Batch_reciteContractSharing implements DataBase.Batchable<Sobject>, DataBase.Stateful{
    
  // public string batchName = 'Recite Contract Sharing - ' + Datetime.now();  
   
   // Setting Error Message
    public string errorMessage = 'Batch Class Name = Batch_reciteContractSharing\n' ;
                            
    public integer noOfErrors = 0;
    
   final static String query = 'Select Id, Account_name__c, Account_name__r.OwnerId from Merge_Contract_Header__c where Account_name__r.Owner.isActive = true';
   //TestMethod Query
   //final static String testquery ='Select Id, Account_name__c, Account_name__r.OwnerId from Merge_Contract_Header__c where Account_name__r.Owner.isActive = true limit 10';
    
    global Database.QueryLocator start(Database.batchableContext Bc){
       // if(!Test.IsrunningTest()){
            return DataBase.getQueryLocator(query);   
      /*  }else{
           return DataBase.getQueryLocator(testquery);  
        }*/
    }
    
    global void execute(DataBase.batchableContext bc , List<Merge_Contract_Header__c> scope) {
      //Map Storing the Contract Id as Key and Account OwnerId as Value.                
       Map<Id, Id> ContIdAccountOwnerMap = new  Map<Id, Id>();
       //List Storing the result from the  MCHShare object result.
       List<Merge_Contract_Header__Share> mchShareList;
       //List Storing the record that need to be inserted in the MchShare Table
       List<Merge_Contract_Header__Share> AddmchShareList = new List<Merge_Contract_Header__Share>();
      
       if(scope!=null) {
          for(Merge_Contract_Header__c mch : scope) {
             ContIdAccountOwnerMap.put(mch.Id, Mch.Account_name__r.OwnerID);
          }
     //     System.debug('ContIdAccountOwnerMap##'+ ContIdAccountOwnerMap);
         if(ContIdAccountOwnerMap != null && !ContIdAccountOwnerMap.isEmpty()) {
             mchShareList=[select Id,UserOrGroupId,ParentId from Merge_Contract_Header__Share where userOrGroupId in :ContIdAccountOwnerMap.values()
                           and ParentId IN : ContIdAccountOwnerMap.keyset()];
       //                    System.debug('mchShareList##'+ mchShareList);
             if(mchShareList!=null && !mchShareList.isEmpty()) {
                 for(Merge_Contract_Header__Share mchShare : mchShareList){
                    if(ContIdAccountOwnerMap.containsKey(mchShare.ParentId)){
                        if(ContIdAccountOwnerMap.get(mchShare.ParentId) == mchShare.userOrGroupId){
                            ContIdAccountOwnerMap.remove(mchShare.ParentId);
                        }
                    }
                 }
             }    
            for(Id contractId : ContIdAccountOwnerMap.keyset()){
                AddmchShareList.add(new Merge_Contract_Header__Share(AccessLevel = 'Read', UserOrGroupId = ContIdAccountOwnerMap.get(contractId), ParentId = contractId));
               }  
           }
        }     
        if( AddmchShareList != null && !AddmchShareList.isEmpty()){
            try{
                insert AddmchShareList;    
            } catch(Exception e) {
                 noOfErrors += 1;
                 string errHdr = ' ###### ';
                 errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                + '\n' + errHdr + '\n';
                
            }
        }
    }

    global void finish(DataBase.batchableContext bc) {
        // Fetch Support Email Address from Custom Setting - SC_SupportEmail__c
     /*   if(noOfErrors > 0){
            SC_SupportEmail__c supEmailValues = SC_SupportEmail__c.getValues('1');
    
            // Setting To Address
            String[] toAdd = new String[] {};
            toAdd.add(supEmailValues.Support_Email_AutoGen__c);
            
            // Setting Subject
            string setSubject = 'Exception: In Batch Job - Batch_reciteContractSharing';
            
            // Sending Email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAdd);
            mail.subject = setSubject;
            mail.plainTextBody = errorMessage;
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
        } */ 
    }
}