trigger populate_accnt_name on Multi_Batch_Order_ID__c (before insert,before update) {
 for(Multi_Batch_Order_ID__c mbRecord:trigger.new){
   List<Account> accnt= [select Name from Account where id in (select Account_Name__c from Merge_Contract_Header__c where id=:mbRecord.Original_ID__c)];
   if(accnt.size() > 0)
   {
      for(Account accntList:accnt)
      {
           mbRecord.Account_Name__c = accntList.Name;
      }
   }
 }
}