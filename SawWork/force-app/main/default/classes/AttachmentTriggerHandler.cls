//SFDC-2135
public class AttachmentTriggerHandler extends ApexTriggerHandlerAbstractClass
{
                public override void beforeInsertBeforeUpdateTrigger()
                {
                                System.debug('This is before insert and before update.');
                }
 
                public override void afterInsertAfterUpdateTrigger()
    {
                if(Trigger.isInsert)
                {
                                L2Q_AttachmentTriggerClass.updateDraftInvoiceForNewAttachment(newList);
                                //SFDC-3953 @ Nagaraj Desai
                                L2Q_AttachmentTriggerClass.migrateAttachmentToContentDocument(newList);
                                SC_AttachmentTriggerClass.sendMailForCaseAttachment(newList);
                                PSAAttachmentHandler.updatePSATestRecords(newList);
                                //ESESP-3751 @Bhavesh kumar
                    			SC_AttachmentTriggerClass.updateIsPrivateToTrueInAttachment(newList);
                }
    }
 
    public override void beforeDeleteBeforeUndeleteTrigger()
    {
        if(Trigger.isDelete)
        {
                List<Attachment> atchmtTriggerOld = (List<Attachment>)oldList;
               
                //Changes by Sharath Prasanna for FFPSA-238
                //Prevent attachment deletion if the test status is set to Report complete
                                //PSA_ProjectActions.checkTestRecords(atchmtTriggerOld);
                PSAAttachmentHandler.checkAttachmentForDelete(atchmtTriggerOld); 
                //Changes for 1916
                AttachmentDeletionAMG.preventAttachmentDelAMG(atchmtTriggerOld);               
        }
    }
 
    public override void afterDeleteAfterUndeleteTrigger()
    {
                if(Trigger.isDelete)
                {
                                L2Q_AttachmentTriggerClass.updateDraftInvoiceForDeletedAttachment(oldList);
                }
    }
}