/* 
Author          : Harshil
Description     : SC Handler class for ContentVersionTrigger
References		: ContentVersionTrigger_ai_au


Date                    Developer             		JIRA #                      Description                                                       
---------------------------------------------------------------------------------------------------------------------------------------------------------------
8 Apr 2022				Author						ESESP-6789					function to stamp visiblity of CDL record based on Content Version custom field
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

public without sharing class SC_ContentVersionTriggerHandler {
    
    //@Method: called in ContentVersionTrigger_ai_au
    public static void jarvisUpdateVisibility (Set<Id> contentDocIds){
        List<ContentDocumentLink> contentDocLinkRecs = [Select Id, Visibility, ShareType from ContentDocumentLink Where ContentDocumentId IN :contentDocIds];
        for(contentDocumentLink contentDocLinkRec : contentDocLinkRecs){
            if(contentDocLinkRec.Visibility != 'AllUsers') { contentDocLinkRec.Visibility = 'AllUsers'; }
        }
        //System.Debug('###' + contentDocLinkRecs);
        Update contentDocLinkRecs;
    }
}