public class PSAAttachmentHandler
{
   //Changes by Suhas Jain for FFPSA-380
   //Moving updatePSATestRecords from Common to GSS Services
   public static void updatePSATestRecords(List<SObject> newList)
    {
        //Changes by Sharath Prasanna for FFPSA-238
        //Update hasAttachment on attachment creation

        List<Attachment> atchmtTriggerNew = (List<Attachment>)newList;
        Set <Id> testRecords = new Set <Id>();            
        //String testObjectPrefix = PSA_Settings__c.getValues('TestObjectPrefix').value__c;
        String testObjectPrefix;
        PSA_Settings__c testObjectPrefixRecord = PSA_Settings__c.getValues('TestObjectPrefix');
        if (testObjectPrefixRecord != null)
        {
            testObjectPrefix = testObjectPrefixRecord.value__c;
        }
        else
        {
            testObjectPrefix = 'aAE';   
        }
        for(Attachment attachmentRecord :atchmtTriggerNew)
        {

            if(String.valueOf(attachmentRecord.ParentId).startsWith(testObjectPrefix) && !testRecords.contains(attachmentRecord.ParentId))
            {

                    testRecords.add(attachmentRecord.ParentId);   
            }
        }
        if(testRecords.size() > 0)
        {
            PSA_ProjectActions.updateTestRecordsTrue(testRecords);

        }
    }


   public static void updatePSATestRecordsfromFiles(List<SObject> newList)
    {
        //Changes by Sharath Prasanna for FFPSA-647
        //Update hasAttachment on File creation


        List<ContentDocumentLink> contentDocumentLinkList = (List<ContentDocumentLink>)newList;
        //Set <Id> contentDocIds = new Set <Id>();            
        Map<String, Schema.SObjectType> m  = Schema.getGlobalDescribe() ;
        Schema.SObjectType s = m.get('Test__c') ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        String testObjectPrefix = r.getKeyPrefix();
        
        Set <Id> testRecords = new Set <Id>();            

        for(ContentDocumentLink ContentDocumentLinkRecord: contentDocumentLinkList)
        {
            if(String.valueOf(ContentDocumentLinkRecord.LinkedEntityId).startsWith(testObjectPrefix))
            {
                testRecords.add(ContentDocumentLinkRecord.LinkedEntityId);
            }
        }
        
        if(testRecords.size() > 0)
        {
            PSA_ProjectActions.updateTestRecordsTrue(testRecords);

        }        
        
    }


   public static void checkContentVersionForDelete(List<ContentDocument> oldList)
    {
        //Changes by Sharath Prasanna for FFPSA-647
        //Update hasAttachment on File creation
        //system.assertEquals(1,3);
        Set <Id> contentDocIds = new Set <Id>(); 
        Map<Id,Id> testToContentDoc = new Map<Id,Id>();
        for(ContentDocument contentDocumentRecord: oldList)
        {
            contentDocIds.add(contentDocumentRecord.Id);
        }
        
        if(!contentDocIds.isEmpty())
        {
            Map<String, Schema.SObjectType> m  = Schema.getGlobalDescribe() ;
            Schema.SObjectType s = m.get('Test__c') ;
            Schema.DescribeSObjectResult r = s.getDescribe() ;
            String testObjectPrefix = r.getKeyPrefix();
            
            Set <Id> testRecords = new Set <Id>();            

            for(ContentDocumentLink ContentDocumentLinkRecord: [select LinkedEntityId,ContentDocumentId from ContentDocumentLink where ContentDocumentId in: contentDocIds])
            {
                if(String.valueOf(ContentDocumentLinkRecord.LinkedEntityId).startsWith(testObjectPrefix))
                {
                    testRecords.add(ContentDocumentLinkRecord.LinkedEntityId);
                    testToContentDoc.put(ContentDocumentLinkRecord.LinkedEntityId,ContentDocumentLinkRecord.ContentDocumentId);
                }
            }
            
            if(testRecords.size() > 0)
            {
                    Set<Id> testIds = PSA_ProjectActions.checkTestRecordsForDelete(testRecords);


                    for(ContentDocument contentDocumentRecord: oldList)
                    {
                        if(testIds.contains(testToContentDoc.get(contentDocumentRecord.Id)))
                        {
                            contentDocumentRecord.addError('Attachments can not be deleted when Test Status is “Report complete”. Please change the Test status in-order to delete the attachment');
                        }
                    }

            }


        }
        
    }


   public static void checkAttachmentForDelete(List<Attachment> oldList)
    {
        //Changes by Sharath Prasanna for FFPSA-647
        //Update hasAttachment on File creation

            Map<String, Schema.SObjectType> m  = Schema.getGlobalDescribe() ;
            Schema.SObjectType s = m.get('Test__c') ;
            Schema.DescribeSObjectResult r = s.getDescribe() ;
            String testObjectPrefix = r.getKeyPrefix();

        
            
            Set <Id> testRecords = new Set <Id>();            

            for(Attachment attachmentRecord: oldList)
            {
                    if(String.valueOf(attachmentRecord.ParentId).startsWith(testObjectPrefix))
                    {
                      testRecords.add(attachmentRecord.ParentId);
                    }

            }            
            if(testRecords.size() > 0)
            {
                    Set<Id> testIds = PSA_ProjectActions.checkTestRecordsForDelete(testRecords);


                    for(Attachment attachmentRecord: oldList)
                    {
                        if(testIds.contains(attachmentRecord.ParentId))
                        {
                            attachmentRecord.addError('Attachments can not be deleted when Test Status is “Report complete”. Please change the Test status in-order to delete the attachment');
                        }
                    }

            }


        
        
    }


}