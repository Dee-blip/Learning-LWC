trigger ContentVersionTrigger_ai_au on ContentVersion (after insert, after update) {

    if(Trigger.isUpdate)
    {
        ContentVersionTriggerController.updateTagCsvCustomField(Trigger.new);
    } 

    if(Trigger.isInsert) 
    {
        ContentVersionTriggerController.updateAttributes(Trigger.new);
        
        //ESESP-6789: Start of changes, setting visiblity of CDL record based on custom field
        Set<Id> contentDocIds = new Set<Id>();
        for(ContentVersion contentVersionRecord: Trigger.new){
            if(contentVersionRecord.customvisibility_fileupload__c != null){
                if(contentVersionRecord.customvisibility_fileupload__c == 'AllUsers' && contentVersionRecord.isLatest == true){
                    contentDocIds.add(contentVersionRecord.ContentDocumentId);
                }
            }
        }
        //System.Debug('### set' + contentDocIds);
        if(contentDocIds.size() > 0){
            SC_ContentVersionTriggerHandler.jarvisUpdateVisibility(contentDocIds);
        }
        //ESESP-6789: End of changes
    } 

    //Start SFDC-5434
        List<Id> ContentNoteIdList = new List<Id>();
        Map<Id, String> ContentVersionIDToStringContent = new Map<Id, String>();
        for(ContentVersion cv : trigger.new){
            ContentNoteIdList.add(cv.ContentDocumentId);
            //ContentVersionIDToStringContent.put(cv.ContentDocumentId, cv.TextPreview);
        }
        if(ContentNoteIdList.size()>0){
            ContentVersionTriggerController.updateCustomNote(ContentNoteIdList);
        }
    //End SFDC-5434  
}