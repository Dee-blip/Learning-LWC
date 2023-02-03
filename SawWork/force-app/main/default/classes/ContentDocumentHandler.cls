/*
 * CR: FFPSA-647
 * Developer: Sharath Prasanna
 * Enhancement: trigger for Content Document
 * Date: 21th August 2018
 * 
*/ 
public class ContentDocumentHandler extends ApexTriggerHandlerAbstractClass{
	public ContentDocumentHandler() 
	{
		
	}
    public override void beforeInsertBeforeUpdateTrigger()
    {
        //this gets called on insert and update 
        System.debug('This is before insert and before update.');
        
    }
 
    public override void afterInsertAfterUpdateTrigger()
    {
        System.debug('This is after insert and after update.');
        
        if(Trigger.isUpdate){
            //ContentNotesHandler.handleContentNotes(newList);
        }
    }
 
    public override void beforeDeleteBeforeUndeleteTrigger()
    {
        if(Trigger.isDelete)
        {
            PSAAttachmentHandler.checkContentVersionForDelete(oldList);
        }
        //SFDC-7779 -@nadesai
        Map<Id, ContentDocument> mapOfCDIdVsCD = new Map<Id, ContentDocument>();
         //Start SFDC-5434
        List<Id> ContentNoteIdlist = new List<Id>();
        for( SObject cd : trigger.old){
            //System.debug('File Type :'+ cd.FileType);
            System.debug('Hello Hello : '+cd);

            ContentNoteIdlist.add(cd.Id);
            //SFDC-7779 -@nadesai
            mapOfCDIdVsCD.put(cd.Id, (ContentDocument)cd);
        }

        if(ContentNoteIdlist.size()>0){
            L2Q_ContentDocumentLinkTriggerClass.DeleteCustomNote(ContentNoteIdlist);
            SC_Jarvis_utility.HandleContentDocumentDelete(ContentNoteIdlist);
        }
        //End SFDC-5434

        //SFDC-7779 -@nadesai
        if(mapOfCDIdVsCD.size() > 0) {
            L2Q_ContentDocumentLinkTriggerClass.contentDocumentBeforeDeleteOverride(mapOfCDIdVsCD);
        }
    }
 
    public override void afterDeleteAfterUndeleteTrigger() {
        //SFDC-7779 -@nadesai Start
        if(Trigger.isDelete) {
            Map<Id, ContentDocument> mapOfCDIdVsCD = new Map<Id, ContentDocument>();
            for(SObject eachSObject : oldList) {
                ContentDocument eachCD = (ContentDocument) eachSObject;
                mapOfCDIdVsCD.put(eachSObject.Id, (ContentDocument)eachSObject);                
            }
            if(mapOfCDIdVsCD.size() > 0) {
                L2Q_ContentDocumentLinkTriggerClass.contentDocumentAfterDeleteOverride(mapOfCDIdVsCD);
            }
        }
        //SFDC-7779 -@nadesai End
    }	
}