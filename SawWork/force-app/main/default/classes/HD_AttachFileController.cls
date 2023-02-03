public class HD_AttachFileController {

    public BMCServiceDesk__Incident__c myObject {get; set;}
    public ID targetObjectIdvalue{get;set;}
    public ApexPages.StandardController Inccontroller;

    public HD_AttachFileController(ApexPages.StandardController controller) {
        Inccontroller = controller;
        //setting up standard controller 
        myObject = (BMCServiceDesk__incident__c) Inccontroller.getRecord();
        //setting up standard setting values
        targetObjectIdvalue = String.valueOf(myObject.get('Id'));
    }
    
    @AuraEnabled
    public static Id saveFile(Id incId, String fileName, String base64Data, String contentType) { 
        try{
        System.debug('In controller save file');
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        Attachment a = new Attachment();
        a.parentId = incId;

        a.Body = EncodingUtil.base64Decode(base64Data);
        a.Name = fileName;
        a.ContentType = contentType;
        
        insert a;
        
        //BMCServiceDesk__Incident__c incident = [Select Id, Name, Last_Updated_Date_Time__c from BMCServiceDesk__Incident__c where Id =:incId];
        //incident.Last_Updated_Date_Time__c = System.now();
        //update incident;
        return a.Id;
        }
        catch(Exception e){
            System.debug('Exception in save file: '+e.getMessage()+' Cause----->'+e.getCause());
            return null;
        }
    }
    
    

}