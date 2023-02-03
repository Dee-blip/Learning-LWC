// File modified by Mayank Bansal for code bulkification under SFDC-2133

public with sharing class ContentVersionTriggerController {

    private static boolean updateTagCsvHasRun =false;
    public static Boolean updateCustomNoteHasRun = false;

    public static Map<String, List<ContentVersionAttribute__c>> listOfContenntVersionAttributes;

    public static void updateTagCsvCustomField(List<ContentVersion> cvList)
    {
        if(updateTagCsvHasRun)
            return;

        List<ContentVersion> cvLists = new List<ContentVersion>();

        cvLists = [Select Id,TagCsv,Tag__c From ContentVersion Where Id IN:cvList];


        List<ContentVersion> cvListToBeUpdated = NAPUtilClass.getFilesToBeUpdated(cvLists);

        if(cvListToBeUpdated.size()>0)
            update cvListToBeUpdated;

        updateTagCsvHasRun=true;

    }

    /* AGH - WHY ISN'T THIS BULKIFIED!? */

    public static void updateAttributes(List<ContentVersion> cvList) {

     //   Map<String,String> contentVerionAndContentDocumentIdMap = new Map<String,String>();
        List<ContentVersionAttribute__c> attributesToInsert = new List<ContentVersionAttribute__c>();
        listOfContenntVersionAttributes = new Map<String, List<ContentVersionAttribute__c>>();

        List<String> cvIds = new List<String>();

        List<String> contentVersionsIDs = new List<String>();
        List<String> contentDocumentIds = new List<String>();

        for(ContentVersion cv: cvList){
            contentVersionsIDs.add(cv.Id); // here we will have cv IDs of recently inserted
            contentDocumentIds.add(cv.contentDocumentId);
        }
        
        List<ContentVersion> contentVersionList = [Select id, ContentDocumentId, createdDate from ContentVersion where 
                ContentDocumentId in :contentDocumentIds and
                // can put createdDate of the first content version
                id not in :contentVersionsIDs
                Order By ContentDocumentId, createdDate Desc];

        Map<String, ContentVersion> distinctContentVersion = new Map<String, ContentVersion>();
        contentVersionsIDs.clear();

        for(ContentVersion cv1: contentVersionList){
            if(distinctContentVersion.get(cv1.contentDocumentId) == null){
                distinctContentVersion.put(cv1.contentDocumentId, cv1);
                contentVersionsIDs.add(cv1.id); // here we will have cv IDs of existing CVs
            } else {
                continue;
            }
        }

        List<ContentVersionAttribute__c> cotentVersionAttributes = new List<ContentVersionAttribute__c>();

        if(contentVersionList.size() > 0){
        cotentVersionAttributes = [Select 
                                     Name, 
                                     Attribute_Name__c,
                                     Partner_Account__c,
                                     Attribute_Value__c,
                                     ContentVersionId__c
                                         from ContentVersionAttribute__c 
                                         where ContentVersionId__c in :contentVersionsIDs 
                                         order by ContentVersionId__c];
                                     }

        

        for(ContentVersionAttribute__c cva: cotentVersionAttributes){
            
            List<ContentVersionAttribute__c> cvaList = new List<ContentVersionAttribute__c>();

            if(!listOfContenntVersionAttributes.containsKey(cva.ContentVersionId__c)){
                listOfContenntVersionAttributes.put(cva.ContentVersionId__c, new List<ContentVersionAttribute__c> {cva});
            } else {
                cvaList = listOfContenntVersionAttributes.get(cva.ContentVersionId__c);
                cvaList.add(cva);
                listOfContenntVersionAttributes.put(cva.ContentVersionId__c, cvaList);
            }
        }
        
        Map<String, List<ContentVersionAttribute__c>> test = new Map<String, List<ContentVersionAttribute__c>>();
        

        for (ContentVersion cv:cvList) {
            Datetime latestVersionCreatedDate = cv.createdDate;
      /*      List<ContentVersion> contentVersionList = [Select id from ContentVersion where 
                ContentDocumentId=:cv.ContentDocumentId and
                createdDate < =:latestVersionCreatedDate and 
                id !=:cv.id
                Order By createdDate Desc];
            */

            if(distinctContentVersion.get(cv.ContentDocumentId) != null)
            {

              //  ContentVersion previousContentVersion = contentVersionList.get(0);
                ContentVersion previousContentVersion = distinctContentVersion.get(cv.ContentDocumentId);
                System.debug('Previous COntent Version : '+ previousContentVersion);

                List<ContentVersionAttribute__c> cvAttributesList = new List<ContentVersionAttribute__c>();
                if (previousContentVersion != null) {

                 /*   cvAttributesList = [Select 
                                     Name, 
                                     Attribute_Name__c,
                                     Partner_Account__c,
                                     Attribute_Value__c 
                                         from ContentVersionAttribute__c 
                                         where ContentVersionId__c=:previousContentVersion.id ]; */
                    if(listOfContenntVersionAttributes.containsKey(previousContentVersion.id)){
                       // cvAttributesList = listOfContenntVersionAttributes.get(previousContentVersion.id);
                        cvAttributesList.addAll(listOfContenntVersionAttributes.get(previousContentVersion.id));
                    }
                }
                if (cvAttributesList.size() > 0) {
                    for (ContentVersionAttribute__c attr: cvAttributesList) {
                        ContentVersionAttribute__c attribute = new ContentVersionAttribute__c(Attribute_Name__c = attr.Attribute_Name__c,
                                ContentVersionId__c = cv.id,
                                Partner_Account__c = attr.Partner_Account__c,
                                Attribute_Value__c = attr.Attribute_Value__c);
                        attributesToInsert.add(attribute);
                    }
                }
            }                                  
        }
        System.debug('attributesToInsert : '+attributesToInsert);
        insert attributesToInsert; 

    }

    //Start SFDC-5434
    public static void updateCustomNote(List<Id> ContentNoteIdList){

        if(updateCustomNoteHasRun) {
            return;
        }
        updateCustomNoteHasRun = true;
        //Map<Id, String> ContentIDtoStringContent = new Map<Id, String>();
        List<Custom_Notes__c> CustomNoteList = new List<Custom_Notes__c>();

        Map<Id, ContentNote> IdToContentNote = new Map<Id, ContentNote>();

        for(ContentNote cn : [Select id, TextPreview, Title, LatestPublishedVersionId, Content, LastModifiedById, LastModifiedDate From ContentNote Where Id IN : ContentNoteIdList]){
            IdToContentNote.put(cn.Id, cn);
        }
        
        for(Custom_Notes__c cn : [Select id, Note_Title__c, Notes_ID__c, Notes_Body__c from Custom_Notes__c where Notes_ID__c IN :IdToContentNote.keyset()]){
            
            cn.Notes_Body__c = IdToContentNote.get(cn.Notes_ID__c).Content.tostring().stripHtmlTags();
            System.debug('TextPreview:'+IdToContentNote.get(cn.Notes_ID__c).TextPreview);
            //cn.Notes_Body__c = IdToContentNote.get(cn.Notes_ID__c).TextPreview;
            cn.Note_Title__c = IdToContentNote.get(cn.Notes_ID__c).Title;
            cn.Notes_Last_Modified_By__c = IdToContentNote.get(cn.Notes_ID__c).LastModifiedById;
            cn.Notes_Last_Modified_Date__c = IdToContentNote.get(cn.Notes_ID__c).LastModifiedDate;
            CustomNoteList.add(cn);
        }
        if(CustomNoteList.size()>0){
            //update CustomNoteList;
            GsmUtilClass.doDatabaseUpdate(CustomNoteList,'ContentVersionTriggerController','updateCustomNote');
        }

    }
    //End SFDC-5434
}