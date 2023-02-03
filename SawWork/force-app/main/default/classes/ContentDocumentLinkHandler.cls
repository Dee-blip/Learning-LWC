/*
* CR: FFPSA-647
* Developer: Sharath Prasanna
* Enhancement: trigger handler for ContentDocumentLinkHandler
* Date: 21th August 2018
* 
*15 Mar 2021        Sumukh SS                 JARVIS Initial Development
*/ 
public class ContentDocumentLinkHandler{
    public ContentDocumentLinkHandler() 
    {
        
    }
    //Changes by Vikas for ESESP-1678
    public  void beforeInsertBeforeUpdateTrigger(List<contentDocumentLink> newList)
    {
        for(ContentDocumentLink thisDocument: newList){
            //Vamsee: Jarvis Related Code... Set the visibility when attachments are uploaded from ACC (ESESP-6034)
            if(String.valueOf(thisDocument.LinkedEntityId.getsobjecttype()) == 'Case' && (Userinfo.getName() == 'Pulsar Case Mgmt' || Userinfo.getName().containsIgnoreCase('Mulesoft Integration')) && thisDocument.Visibility != 'AllUsers'){
                thisDocument.Visibility = 'AllUsers';
             }
            if(String.valueOf(thisDocument.LinkedEntityId.getsobjecttype()) == 'Customer_Community_Document__c' && thisDocument.Visibility != 'AllUsers'){
                thisDocument.Visibility = 'AllUsers';
            }
        }
    }
    
    
    public void afterInsertAfterUpdateTrigger(List<contentDocumentLink> newList, Map<Id,contentDocumentLink> triggerOldMap)
    {
        //JARVIS Related Changes
        map<string,string> contentDocCaseIdMap = new map<string,string>();
        Set<id> caseIdsetforUpdate = new Set<id>();
        List<contentDocumentLink> casePublicCdl = new List<contentDocumentLink> ();
        for(ContentDocumentLink ContentDocumentLinkRecord: newList)
        {
            if(Trigger.isInsert)
            {
                if(String.valueOf(ContentDocumentLinkRecord.LinkedEntityId.getsobjecttype()) == 'Case'){
                    caseIdsetforUpdate.add(ContentDocumentLinkRecord.LinkedEntityId);
                    
                }
                if(String.valueOf(ContentDocumentLinkRecord.LinkedEntityId).startsWith('500') && ContentDocumentLinkRecord.Visibility=='AllUsers')
                {
                    contentDocCaseIdMap.put(ContentDocumentLinkRecord.ContentDocumentId ,ContentDocumentLinkRecord.LinkedEntityId);
                }
            }
            if(Trigger.isUpdate)
            {
                if(triggerOldMap.get(ContentDocumentLinkRecord.id).Visibility!=ContentDocumentLinkRecord.Visibility && ContentDocumentLinkRecord.Visibility=='AllUsers')
                {
                    contentDocCaseIdMap.put(ContentDocumentLinkRecord.ContentDocumentId ,ContentDocumentLinkRecord.LinkedEntityId);
                }
            }
        }
                
      if(UserInfo.getUserType() != 'Standard' ) {             
          Set<Id> contentDocIds = new Set<id>();
          for(ContentDocumentLink cdl: newList) {
              if(String.valueOf(cdl.LinkedEntityId).startsWith('500')) {
                  contentDocIds.add(cdl.ContentDocumentId);
              }
          }
          // Jarvis File Extension Check
          Map<Id, ContentDocument> contentDocs = new Map<Id, ContentDocument>([select id, filetype, FileExtension from ContentDocument where Id in :contentDocIds]);
          SC_Utility__mdt fileExtSetting = [select id, Value__c from SC_Utility__mdt where DeveloperName = 'Jarvis_File_Extensions'];
          List<String> allowedExtensions = fileExtSetting.Value__c.split(',');
          for(ContentDocumentLink cdl: newList) {
              ContentDocument cd = contentDocs.get(cdl.ContentDocumentId);
              if(cd == null) {
                  continue;
              }
              Boolean invalidFileExtension = String.isBlank(cd.fileExtension) 
                                             || !allowedExtensions.contains(cd.fileExtension.toLowerCase());
              
              if(invalidFileExtension) {
                  cdl.addError('Unsupported file type');
              }
          }
      }
        if(contentDocCaseIdMap.size()>0)
        {
            SC_CommunityCommentTriggerHandler.createCommentFromFileUpload(contentDocCaseIdMap);
        } 
        
        //ESESP-5691(Vamsee) -  File Size flag against Case 
        if(caseIdsetforUpdate.size() > 0){
            SC_Jarvis_utility.updateCaseAttachmentFlag(caseIdsetforUpdate);
        }
        if(Trigger.isInsert)
        {
            PSAAttachmentHandler.updatePSATestRecordsfromFiles(newList);
        }
        
    }
    
    
}