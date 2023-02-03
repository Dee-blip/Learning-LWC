/* 
MARIT-678, PDG Changes
Author : Himanshu Verma
Date: 25/08/2020
*/

public without sharing class  MARIT_CTAPathComponent 
{
	public class LeadInfoWithProfile { 
		Lead lObj;
		UserRecordAccess uraObj;
	}

	@AuraEnabled
	public static string getLeadObj(Id leadId) {
		LeadInfoWithProfile liwpObj = new LeadInfoWithProfile();
		liwpObj.lObj =  [Select Id,HasOptedOutOfEmail,DoNotCall,First_SLA_DT__c,Last_SLA_DT__c,
		adg_Self_Generated_Lead_Type__c, Buyer_Pain_Points__c, Lead_Qualification_Stage__c, 
		Lead_Qualification_Status__c, Status from lead where Id =:leadId];
		List<UserRecordAccess> uraList = [SELECT HasEditAccess, RecordId FROM UserRecordAccess WHERE RecordId =: leadId AND UserId =: UserInfo.getUserId() limit 1];
		if (uraList.size() > 0) {
			liwpObj.uraObj = uraList[0]; 
		} else {
			liwpObj.uraObj = null; 
		}
		return JSON.serialize(liwpObj);
	}

	@AuraEnabled
    public static String updateLeadStatus(Lead leadRec) {
		List<Lead> recordsToBeUpdated = new List<Lead>{leadRec};
		Database.SaveResult[] saveRes = Database.Update(recordsToBeUpdated , false);
		List<Error_Log__c> errorLogs = new List<Error_Log__c>();
		String[] messages = new String[0];
		Integer count = 0;
		for(Database.SaveResult result : saveres)
           {
               if(!result.isSuccess()){
					
                   String errMessage = '';
                   for(Database.Error err : result.getErrors())
                   {
						messages.add(err.getMessage());
                   }
                   Map<String, Object> fieldsToValue = recordsToBeUpdated[count].getPopulatedFieldsAsMap();
                   String objectState = JSON.serialize(fieldsToValue);

                   Error_Log__c el = new Error_Log__c(Name='SaveLead', Class__c='MARIT_CTAPathComponent', Error_Message__c= String.join(messages, '\n') , Object_State__c=objectState);
                   System.debug(LoggingLevel.Error, ' errored insert'+el);
                   errorLogs.add(el);
               }
			   count += 1;
		   }
           if(errorLogs.size()>0) {
               Database.insert(errorLogs, false);
               return messages[0];
           }
		   System.debug('test saved result: ' + saveRes);
       	return 'Success' + leadRec.Id;
    }
}