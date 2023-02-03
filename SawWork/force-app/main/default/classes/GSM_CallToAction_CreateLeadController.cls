public class GSM_CallToAction_CreateLeadController {

    /**
      @author: Hitesh Chawda
      SFDC-2328
     * History:
     * =========================
     * Developer        Date        Description

     Hitesh Chawda    19/02/2018  Added this class part of SFDC-2328
     **/

    @AuraEnabled
    public static List<String> loadPicklistValues(String sobjectName, String picklistFieldName)
    {
        List<String> options = GSMLite_UtilClass.populatePickList(sobjectName,picklistFieldName);
        return options;
    }

    @AuraEnabled
    public static String getUIThemeDescription() 
    {
        String theme = UserInfo.getUiThemeDisplayed();
        system.debug('theme == '+theme);
        return theme;
    }

    @AuraEnabled
    public static String creteActivityAndGetUITheme(String productSelected, String leadTypeSelected, String Notes, String WhatId) 
    {
        try {
            // MARIT-210. Create an activity if the C2A lead exists
            Task newTask = new Task();
            newTask.Subject = 'Note from SDR';
            newTask.status = 'Completed';
            newTask.ActivityDate = System.today();
            newTask.Priority = 'Normal';
            newTask.OwnerId = System.UserInfo.getUserId();
            newTask.WhoId = WhatId;
            newTask.Description = 'Self Gen Lead Type - ' + leadTypeSelected + ', Product Line - ' + productSelected + ', Notes - ' + Notes;
            insert newTask;
        } catch (Exception e) {
            system.debug(Logginglevel.ERROR,'Error Message '+e.getMessage());
        }
        return getUIThemeDescription();
    }

    @AuraEnabled
    public static Boolean isSDRUserCheck()
    {
        return ProfileUtils.isSDR();
    }

   // This function checks if the C2A lead exists or not.
   // If lead does not exists then it returns Object type as 'Contact' and its person Id 
   // If lead exists then it will return if it is a SDR user or not along with C2A id and person id
    @AuraEnabled
    public static String callToActionLeadExists(Id genericRecordID,Boolean changeOwner)
    {
        //SFDC-5332
        Id personId;

        Boolean isSDRUser = false;
        if(ProfileUtils.isSDR() ||  GSMUtilClass.getGSMSettingValue('ContactConversion_Prof_BuyAkamai').contains(UserInfo.getProfileId()))
           isSDRUser = true; 

        String objectType =  String.valueOf(genericRecordID.getSobjectType());
        String returnValue;
        Lead leadRec;

        if( objectType == 'LiveChatTranscript')
        {
            LiveChatTranscript liveTranscriptRecord = getLiveChatTranscriptRecord(genericRecordID);
            personId = liveTranscriptRecord.Contact.Id;
        }
        else if(objectType == 'Contact' || objectType == 'Lead')//SFDC-5332
        {
            personId = genericRecordID;
        }
        if(personId != null)
        {
            leadRec = getC2ALead(personId);//existingLeadList = [Select Id,name,CreatedDate,Associated_Contact__c From Lead where Associated_Contact__c =:personId AND Status IN ('In Process','New') AND RecordTypeId =:akamaiLeadRecordTypeId Order By CreatedDate DESC];
        }

        if(!changeOwner && leadRec != null) 
        {
            if(isSDRUser && leadRec.OwnerId != UserInfo.getUserId() )
                return '1'+':'+leadRec.Id +':'+personId;
            else
                return '2'+':'+leadRec.Id+':'+personId;
        }
        else{
            if(objectType=='Lead' || objectType=='Contact')
                objectType = 'Contact';
            return '0'+':'+objectType+':'+personId;
        }
    }

    private static LiveChatTranscript getLiveChatTranscriptRecord(String liveChatTranscriptId)
    {
        return [select Id, Contact.Id,LeadId,Lead.Name from LiveChatTranscript where Id=:liveChatTranscriptId];
    }

    @AuraEnabled
    public static Lead getC2ALead(Id personId)
    {
        String akamaiLeadRecordTypeId = GSMUtilClass.getGSMSettingValue('AkamaiLeadRecordTypeId');
        List<Lead> existingLeadList = new List<Lead>();

        if(personId != null)
        {
            //SFDC-5332
            existingLeadList = [Select Id,name,CreatedDate,Associated_Contact__c,OwnerId From Lead where (Associated_Contact__c =:personID OR parent_lead__c=:personID) AND Status IN ('In Process','New') AND RecordTypeId =:akamaiLeadRecordTypeId Order By CreatedDate DESC];
        }

        if(existingLeadList.size() > 0)
        {
            return existingLeadList[0];
        }

        else
            return null;
    }
}