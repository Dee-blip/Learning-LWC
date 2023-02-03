//SFDC-2135
public without sharing class L2Q_AttachmentTriggerClass
{
  public static void updateDraftInvoiceForNewAttachment(List<SObject> newList)
  {
    List<Attachment> atchmtTriggerNew = (List<Attachment>)newList;
        List<Id> hasAttachmentDIList = new List<Id>();

        for (Attachment a : atchmtTriggerNew)
        {
            String tempStr = a.ParentId;
            if (tempStr.startsWith(Schema.Sobjecttype.Draft_Invoice__c.getKeyPrefix()))
                hasAttachmentDIList.add(a.ParentId);
        }
        
        if (hasAttachmentDIList.size()>0 || Test.isRunningTest())
        {
            List<Draft_Invoice__c> diTOUpdateList = new List<Draft_Invoice__c>();
            for (Id diID: hasAttachmentDIList){
                diToUpdateList.add(new Draft_Invoice__c(id=diID, hasAttachment__c=true));
            }
            
            if (diToUpdateList.size()>0) update diToUpdateList;
        }
  }

  public static void updateDraftInvoiceForDeletedAttachment(List<SObject> oldList)
  {
        List<Attachment> atchmtTriggerOld = (List<Attachment>)oldList;
      List<Id> hadAttachmentDIList = new List<Id>();

        for (Attachment a : atchmtTriggerOld)
        {
            String tempStr = a.ParentId;
            if (tempStr.startsWith(Schema.Sobjecttype.Draft_Invoice__c.getKeyPrefix()))
                hadAttachmentDIList.add(a.ParentId);
        }

        if (hadAttachmentDIList.size()>0 || test.isRunningTest())
        {
            List<Draft_Invoice__c> diTOUpdateList = new List<Draft_Invoice__c>();
            for (Id diID: hadAttachmentDIList){
                diToUpdateList.add(new Draft_Invoice__c(id=diID, hasAttachment__c=false));
            }
            
            if (diToUpdateList.size()>0) update diToUpdateList;
        }
  }
    
  //SFDC-3953 @ Nagaraj Desai : function to create copy of ContentDocument for every Attachment being inserted
  public static void migrateAttachmentToContentDocument(List<SObject> newList) {
          if(newList != null && newList.size() > 0) {
                  List<Attachment> atchmtTriggerNew = (List<Attachment>)newList;
                  List<Attachment> newAttachmentList = [SELECT Id, Name, Body, ParentId, Parent.Type FROM Attachment WHERE Id IN :atchmtTriggerNew];

                  List<ContentVersion> listOfContentVersion = new List<ContentVersion>();
                  String L2Q_ObjectsUsingAttachment = GSMSettings.getVerbose('L2Q_ObjectsUsingAttachment');
                  List<String> listOfObjects = L2Q_ObjectsUsingAttachment.split(',');
                  List<Attachment> listOf_L2QAttachments = new List<Attachment>();

                  for(Attachment eachAttachment : newAttachmentList) {
                        if(listOfObjects.contains(String.valueOf(eachAttachment.Parent.Type))) {
                                listOf_L2QAttachments.add(eachAttachment);
                                ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', eachAttachment.Name, eachAttachment.Name, eachAttachment.Body);
                                conVer.FirstPublishLocationId = eachAttachment.ParentId;
                                // SFDC-8683 -Start
                                if(Userinfo.getUserType().contains('PowerPartner') || Test.isRunningTest()) {
                                        if(Network.getNetworkId() != null) {
                                                conVer.NetworkId = Network.getNetworkId();
                                        } else {
                                                if(NAPSettings.getValue('ObjectsRequiringNetworkIds').containsIgnoreCase(String.valueOf(eachAttachment.ParentId.getSObjectType()))) {
                                                        conVer.NetworkId = NAPSettings.getValue('partnerPortalNetworkId');
                                                }
                                        }
                                }
                                // SFDC-8683 -End
                                listOfContentVersion.add(conVer);
                        }
                  }
                  if(listOfContentVersion.size() > 0) {
                          try {
                                  insert listOfContentVersion;
                          }
                          catch(Exception e) {
                                  Error_log__c erroLog = new Error_log__c(Name = 'Attachment To File Convertion Error', Class__c = 'L2Q_AttachmentTriggerClass',Error_Message__c = e.getMessage());insert erroLog;
                          }
                  }
          }
  }
}