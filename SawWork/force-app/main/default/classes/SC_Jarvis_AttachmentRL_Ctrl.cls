/*=====================================================================================================+
Class name        	:   SC_Jarvis_AttachmentRL_Ctrl
Author              :   Vamsee Surya
Created             :   01-Aug-2021
Purpose             :   Controller class for Attachment Related List Component
Test Class          :   SC_Jarvis_TestClass

Last Modified 	Developer   	Purpose             
============= 	==========  	=======
01-Aug-21     	Vamsee Surya  	Initial Development(Jira Ticket# ESESP-5659)
01 Dec 2021     Harshil         Check #days since case closed to disable file upload(ESESP-6070) 
19-Jan-22       Harshil         Added condition to disable upload access for PTS(ESESP-6568)
29-Apr-22       Harshil         Added file size column(ESESP-7094)
+=====================================================================================================*/

public with sharing class SC_Jarvis_AttachmentRL_Ctrl {
    Public SC_Jarvis_AttachmentRL_Ctrl(){

    }

    Public Class AttachmentRelatedListWrapper{
        @AuraEnabled public String title {get;set;}
        @AuraEnabled public String extension {get;set;}
        @AuraEnabled public String fileSize {get;set;}
        @AuraEnabled public String lastModified {get;set;}
        @AuraEnabled public String createdBy {get;set;}
        @AuraEnabled public String downloadURL {get;set;}

        public AttachmentRelatedListWrapper(String titleValue, String extensionValue, String fileSizeValue, String lastModifiedDate, String createdByName, string url)
        {
            title=titleValue;
            extension =extensionValue;
            //ESESP-7094
            fileSize = fileSizeValue;
            lastModified = lastModifiedDate;
            createdBy = createdByName;
            downloadURL = url;
        }
        
    }

    public Class AttachmentRLDetailsWrapper{
        @AuraEnabled Public list<AttachmentRelatedListWrapper> attachmentRecords {get;set;}
        @AuraEnabled public boolean displayUploadFileButton{get;set;}

        public AttachmentRLDetailsWrapper(list<AttachmentRelatedListWrapper> attachmentRecordslist, boolean displayUploadFileButtonValue){
            attachmentRecords = attachmentRecordslist;
            displayUploadFileButton = displayUploadFileButtonValue;
        }
    }
    @AuraEnabled
    public static AttachmentRLDetailsWrapper getAttachmentRelatedListWrapper(String caseId){
        List<AttachmentRelatedListWrapper> wrapperList = new List<AttachmentRelatedListWrapper>();
        //ESESP-7094 : Added field to query
        for(ContentDocumentLink eachDoc : [SELECT id, contentdocumentId, contentdocument.title, contentdocument.ContentModifiedDate, contentdocument.FileExtension, contentdocument.owner.name, contentdocument.LatestPublishedVersion.File_Size__c FROM ContentDocumentLink WHERE LinkedEntityId = :caseId]){
            // '/sfc/servlet.shepherd/document/download/'
            wrapperList.add(new AttachmentRelatedListWrapper(eachDoc.contentdocument.title, (eachDoc.contentdocument.FileExtension != null) ? eachDoc.contentdocument.FileExtension : System.Label.Jarvis_EmailMessage_Unknown, eachDoc.contentdocument.LatestPublishedVersion.File_Size__c, eachDoc.contentdocument.ContentModifiedDate.format(), eachDoc.contentdocument.owner.name, eachDoc.contentdocumentId));
        }

        User loggedInUser = [SELECT Id, ContactId, AKAM_User_Id__c, Profile.Name FROM User WHERE Id =: UserInfo.getUserId()];
        Id contactId;
        if(loggedInUser.contactId != null){
            contactId = loggedInUser.contactId;
        }
        else{
            Contact contactRec = [SELECT Id,AccountId FROM Contact WHERE AKAM_Contact_Id__c = :loggedInUser.AKAM_User_Id__c 
            AND active_portal_login__c = true LIMIT 1];
            contactId = contactRec.Id;
        }

        //ESESP-6070 - start of changes
        case caserec = [select AKAM_Closed_Date__c, RecordType.Name, Status from case where id = :caseid];

        boolean displayUploadFileButton;
        if(contactId != null){
            //ESESP-6568: Set file upload to false if RT is PTS
            displayUploadFileButton = !(caserec.RecordType.Name == 'Partner Technical Support') && SC_Jarvis_utility.hasCreateAccess(contactId) && ((caserec.AKAM_Closed_Date__c != null && caserec.Status.containsIgnoreCase('closed')) ? SC_Jarvis_utility.getDaysSinceClosed(caserec.AKAM_Closed_Date__c) <= 14 : true);
        }
        //End of changes

        return new AttachmentRLDetailsWrapper(wrapperList,displayUploadFileButton);

    }
}