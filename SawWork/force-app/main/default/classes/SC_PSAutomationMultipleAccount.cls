public class SC_PSAutomationMultipleAccount {

   @AuraEnabled
   public static Id getTargetListViewId(){
    List<ListView> listViewRec = [Select Id,Name , DeveloperName , SobjectType from ListView where SobjectType = 'PS_Customer_Mailers__c' AND DeveloperName='My_Pending_Mailers' limit 1];
    return listViewRec[0].Id;
}   

   @AuraEnabled
   public static string getInitData(){
      // String searchKey = '%'+UserInfo.getUserId()+'%';
       List<PS_Customer_Mailers__c> targetMailerRecs = new List<PS_Customer_Mailers__c> ();
       List<mainDataTableWrapper> mainDataTableWrapperList = new List<mainDataTableWrapper>();
       mainDataTableWrapper mainDataTableWrapperInstance = new mainDataTableWrapper();
       List<Id> accIds = new List<Id>();
       List<Id> applicableAccIds = new List<Id>();
       Map<Id,Id> accVsDLRec = new Map<Id,Id>();
       List<AccountTeamMember> atmList = [Select Id,AccountId from AccountTeamMember where UserId=: UserInfo.getUserId() AND TeamMemberRole='Security Services - Primary' limit 50000];
       for(AccountTeamMember iteratedATM : atmList){
        applicableAccIds.add(iteratedATM.AccountId);
       }
       targetMailerRecs = [Select Id,Name,Parent_PS_Customer_Mailer__c,Parent_PS_Customer_Mailer__r.Name,Parent_PS_Customer_Mailer__r.PS_Customer_Mailer_Name__c,Parent_PS_Customer_Mailer__r.createdDate,Product_Name__c,Account__c,Account__r.Name,Subject__c,PS_Customer_Mailer_Name__c from PS_Customer_Mailers__c where Account__c IN:applicableAccIds AND Email_forwarded_to_Contacts_On__c = null AND Disabled_On__c = null AND Parent_PS_Customer_Mailer__c != null order by Name asc limit 50000]; 
       
       if(targetMailerRecs.size() > 0){
            for(PS_Customer_Mailers__c iteratedRec : targetMailerRecs){
                accIds.add(iteratedRec.Account__c);
            }
            for(PS_Automation_Admin_DL__c itrDL : [Select Id,Account__c from PS_Automation_Admin_DL__c where Account__c IN:accIds AND recordType.Name = 'External']){
                if(!accVsDLRec.containsKey(itrDL.Account__c)){
                    accVsDLRec.put(itrDL.Account__c,itrDL.Id);
                }
            }
            for(PS_Customer_Mailers__c iteratedRec : targetMailerRecs){
                mainDataTableWrapperInstance = new mainDataTableWrapper();
                mainDataTableWrapperInstance.mailerRec = iteratedRec;
                mainDataTableWrapperInstance.CreatedDate_Text = iteratedRec.Parent_PS_Customer_Mailer__r.createdDate.format();
                if(accVsDLRec.containsKey(iteratedRec.Account__c)){
                    mainDataTableWrapperInstance.areRecipientsPresent = true;
                }else{
                    mainDataTableWrapperInstance.areRecipientsPresent =false;
                }
                mainDataTableWrapperList.add(mainDataTableWrapperInstance);
            }
        }
        return JSON.serialize(mainDataTableWrapperList);
    }

    @AuraEnabled
    public static String createDLRec(String accId,String recName,String recipients){
        String error = '';
        PS_Automation_Admin_DL__c newDL = new PS_Automation_Admin_DL__c();
        newDL.Account__c = accId.split('/')[1];
        newDL.DL_Email_Address__c = recipients;
        newDL.Name = recName;
        newDL.RecordTypeId = Schema.SObjectType.PS_Automation_Admin_DL__c.getRecordTypeInfosByName().get('External').getRecordTypeId();
        Database.SaveResult saveResult = Database.Insert(newDL);
        if(!saveResult.isSuccess()){
            error = saveResult.getErrors()[0].getMessage();
        }
        return error;
    } 



    @AuraEnabled
    public static void massEmailToCustomers(String recs){
        //Running batch class to create child customer mailer recs and notify SSP team members.
        SC_PSAutomationMultipleAccount_BatchJob asyncJob= new SC_PSAutomationMultipleAccount_BatchJob(recs);
        Database.executeBatch(asyncJob,10);
    }    

   class mainDataTableWrapper{
    
   // public PS_Customer_Mailers__c masterMailerRec;
    public PS_Customer_Mailers__c mailerRec;
    public String CreatedDate_Text;
    public Boolean areRecipientsPresent;
    
}
}