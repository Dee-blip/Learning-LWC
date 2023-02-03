public class SC_PSAutomationMassDisableController {

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
        List<AccountTeamMember> atmList = [Select Id,AccountId from AccountTeamMember where UserId=: UserInfo.getUserId() AND TeamMemberRole='Security Services - Primary'];
        for(AccountTeamMember iteratedATM : atmList){
            applicableAccIds.add(iteratedATM.AccountId);
           }
        targetMailerRecs = [Select Id,Name,Parent_PS_Customer_Mailer__c,Parent_PS_Customer_Mailer__r.Name,Parent_PS_Customer_Mailer__r.PS_Customer_Mailer_Name__c,Parent_PS_Customer_Mailer__r.createdDate,Product_Name__c,Account__c,Account__r.Name,Subject__c,PS_Customer_Mailer_Name__c,Reason_for_disabling__c from PS_Customer_Mailers__c where Account__c IN:applicableAccIds AND Email_forwarded_to_Contacts_On__c = null AND Disabled_On__c = null AND Parent_PS_Customer_Mailer__c != null order by Name asc limit 50000]; 
         
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
                 
                 mainDataTableWrapperList.add(mainDataTableWrapperInstance);
             }
         }
         return JSON.serialize(mainDataTableWrapperList);
     }

     @AuraEnabled
    public static String massDisable(String recs){
        String error = '';
        PS_Customer_Mailers__c mailerRec;
        List<PS_Customer_Mailers__c> mailersToUpdate = new List<PS_Customer_Mailers__c>();
        List<ToBeDisableMailerWrapper> toDisableMailerList  = (List<ToBeDisableMailerWrapper>) JSON.deserialize(recs, ToBeDisableMailerWrapper[].class);
        for(ToBeDisableMailerWrapper iteratedWrapperRec : toDisableMailerList) {
            mailerRec = new PS_Customer_Mailers__c(Id=iteratedWrapperRec.Id);
            mailerRec.put('Reason_for_disabling__c',iteratedWrapperRec.Reason);
            mailerRec.put('Disabled_On__c',Datetime.now());
            mailerRec.put('Disabled_By__c',UserInfo.getUserId());
            mailerRec.put('Disabled_Ever__c',true);
            mailersToUpdate.add(mailerRec);
        }
        if(mailersToUpdate.size() > 0){
            
            List<Database.SaveResult> saveResult = Database.Update(mailersToUpdate);
            for(Integer i=0;i<saveResult.size();i++){
                if (!saveResult[i].isSuccess()){
                
                    // DML operation failed
                    error = saveResult[i].getErrors()[0].getMessage();
                    break;
                }
            }
        }    
        return error;
    } 

     class mainDataTableWrapper{
    
        // public PS_Customer_Mailers__c masterMailerRec;
         public PS_Customer_Mailers__c mailerRec;
         public String CreatedDate_Text;
        
         
     }

     public class ToBeDisableMailerWrapper{
    
        // public PS_Customer_Mailers__c masterMailerRec;
         public String Id;
         public String Reason;
        
         
     }


     //*************Controller method for scPSCustomerMailerDisableAura *****/
     @AuraEnabled
     public static PS_Customer_Mailers__c getRecDetail(String recId){
        Set<String> atmIds = new Set<String> ();
        PS_Customer_Mailers__c mailerRec =  [Select Id,Account__c,Is_Master_Record__c,Name,Disabled_On__c,Email_forwarded_to_Contacts_On__c,Team_Member_Id__c from PS_Customer_Mailers__c where Id=:recId];
        List<AccountTeamMember> atmList = [Select Id,UserId from AccountTeamMember where AccountId =: mailerRec.Account__c AND TeamMemberRole='Security Services - Primary'];
        for(AccountTeamMember iteratedATM : atmList){
          atmIds.add(iteratedATM.UserId);
          
        }
        if(!atmIds.contains(UserInfo.getUserId())){
            return null;
        }
        return mailerRec;
    }  
     
     @AuraEnabled
     public static string disableMailerRecord(String recId,String reason){
         String error = '';
         PS_Customer_Mailers__c mailerRec = new PS_Customer_Mailers__c(Id=recId);
            mailerRec.put('Reason_for_disabling__c',reason);
            mailerRec.put('Disabled_On__c',Datetime.now());
            mailerRec.put('Disabled_By__c',UserInfo.getUserId());
            mailerRec.put('Disabled_Ever__c',true);
          if(mailerRec != null){
            Database.SaveResult saveResult = Database.Update(mailerRec);
            
                if (!saveResult.isSuccess()){
                
                    // DML operation failed
                    error = saveResult.getErrors()[0].getMessage();
                    
                }
            
          }  
          return error;


     }

    //*************Controller method for scPSCustomerMailerEnableAura *****/
     @AuraEnabled
     public static string enableMailerRecord(String recId){
        String error = '';
        PS_Customer_Mailers__c mailerRec = new PS_Customer_Mailers__c(Id=recId);
           mailerRec.put('Reason_for_disabling__c','');
           mailerRec.put('Disabled_On__c',null);
           mailerRec.put('Disabled_By__c',null);
         if(mailerRec != null){
           Database.SaveResult saveResult = Database.Update(mailerRec);
           
               if (!saveResult.isSuccess()){
               
                   // DML operation failed
                   error = saveResult.getErrors()[0].getMessage();
                   
               }
           
         }  
         return error;
     }

    
}