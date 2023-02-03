/*

Initial Developer: Shashank Hegade
Date: 25/03/2020
Purpose: A standard utility class for generic lightning web components
Test Class: HD_Test_lwcUtilityClass
Components: hdFileUploader

*/


public without sharing class HD_lwcUtilityClass {
    public class FileInfo {
        //class to deserialize the file data from client-side controller
        public string idParent;
        public string strFileName;
        public string base64data;
    }

    @AuraEnabled
    public static Integer saveAttachments(List<string>  attachmentList){
        //logic for file deserelize and convert it into attachments 
        try{
        List<Attachment> newAttachmentList = new List<Attachment>();
        for(Integer i = 0; i < attachmentList.size();i++){
            FileInfo attachmentClass = (FileInfo)JSON.deserialize(attachmentList[i],FileInfo.class);

            Attachment newAttachment = new Attachment();
            newAttachment.Name = attachmentClass.strFileName;
            newAttachment.ParentId = attachmentClass.idParent;
            

            string base64data = EncodingUtil.urlDecode(attachmentClass.base64data, 'UTF-8');
            newAttachment.Body = EncodingUtil.base64Decode(base64Data);

            newAttachmentList.add(newAttachment);
        }
            insert newAttachmentList; 
            return newAttachmentList.size();  
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<HD_Category__mdt> getDataTableValues() {
        return [SELECT Label, DeveloperName, Number__c, RCA__c, Description__c FROM HD_Category__mdt WHERE DataTable__c = TRUE ORDER By Number__c ASC LIMIT 500];
    }

    @AuraEnabled(cacheable=true)
    public static List<BMCServiceDesk__Status__c> getStatusId(List<String> statusList) {
        return [SELECT Id, Name FROM BMCServiceDesk__Status__c WHERE Name IN :statusList and BMCServiceDesk__inactive__c = FALSE and BMCServiceDesk__appliesToIncident__c = TRUE];  
    }

}