//Added as part of SFDC-2851
public class L2Q_AccountCreationTriggerHandler extends ApexTriggerHandlerAbstractClass {
    
    public String ProfileIds = GsmUtilClass.getGSMSettingValue('ACRProfileId'); 
    public override void beforeInsertBeforeUpdateTrigger(){
         List<Account_Creation_Request__c> accTriggerNew = (List<Account_Creation_Request__c>)newList;
        List<Account_Creation_Request__c> accTriggerOld = (List<Account_Creation_Request__c>)oldList;
        Map<Id,Account_Creation_Request__c> accTriggerNewMap = (Map<Id,Account_Creation_Request__c>)newMap;
        Map<Id,Account_Creation_Request__c> accTriggerOldMap = (Map<Id,Account_Creation_Request__c>)oldMap;
        
         
         for(Account_Creation_Request__c acc: accTriggerNew){
            if(trigger.isinsert){
                acc.Request_Created_By__c =userinfo.getuserid();
                acc.ownerid = GsmUtilClass.getGSMSettingValue('ACRQueueId');
            }
            if(trigger.isupdate){
                  
                if(Util.hasChanges('status__c', accTriggerOldMap.get(acc.id), acc) && (acc.status__c =='Closed - Complete' || acc.status__c =='Closed - Denied') && (ProfileIds.contains(UserInfo.getprofileid()))){
                    
                    acc.Close_Date__c =system.now();
                    // acc.Validation_Override__c=false;
                }
                if(Util.hasChanges('status__c', accTriggerOldMap.get(acc.id), acc) && acc.status__c =='Assigned'){
                   If(acc.Assigned_Date__c == Null)
                        acc.Assigned_Date__c =system.now();
                        acc.Ownerid=userinfo.getuserid();
                    
                 }
                
            }
        }
            ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, accTriggerNew);
            
        /* Address Validation */
             AddressValidationClass.CallValidateAddress(accTriggerNew);


    }
    
    public override void beforeDeleteBeforeUndeleteTrigger(){
    }

    public override void afterInsertAfterUpdateTrigger(){}
     public override void afterDeleteAfterUndeleteTrigger(){}
     
     }