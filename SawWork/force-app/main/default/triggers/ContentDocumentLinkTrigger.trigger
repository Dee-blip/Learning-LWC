/*
 * CR: FFPSA-647
 * Developer: Sharath Prasanna
 * Enhancement: trigger for ContentDocumentLinkHandler
 * Date: 21th August 2018
 *  Note: cannot use the generic trigger handler as the delete trigger is not called
 * Edited by Vikas on 20th Sep 2018 for ESESP-1678
*/ 
trigger ContentDocumentLinkTrigger on ContentDocumentLink (
    before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete) 
{

    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        ContentDocumentLinkHandler contentDocumentLinkHandlerObject = new ContentDocumentLinkHandler();
        if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))
        {
            contentDocumentLinkHandlerObject.afterInsertAfterUpdateTrigger(Trigger.New, Trigger.OldMap);
        }
        //Changes by Vikas for ESESP-1678
        if(Trigger.isBefore && Trigger.isInsert)
        {
            contentDocumentLinkHandlerObject.beforeInsertBeforeUpdateTrigger(Trigger.New);
        }
        //ApexTriggerHandlerAbstractClass.createHandler('ContentDocumentLink');
    }
    
    if((Trigger.isInsert && Trigger.isAfter)){
        SC_CreateCXMActivityController.evaluateIsFileAttachedOnTask(Trigger.new,Trigger.old);
    }
    if(Trigger.isDelete && Trigger.isBefore){
        SC_CreateCXMActivityController.evaluateIsFileAttachedOnTaskUpdateScenario(Trigger.oldMap);
    }
    

}