/*
JIRA 			: ESESP-892 : Moved Service Cloud Code from AttachmentTrigger to SC repo
Author 			: Aditya Sonam
Description		: This class update Case field updateCaseAlert and send email to case owner
Trigger			: AttachmentTrigger
Handler 		: AttachmentTriggerHandler
Interface		: ApexTriggerInterface
Test Class 		: SCUtilTestClass
Outbound Calls 	: SCCaseAttachmentHandler
*/
public class SC_AttachmentTriggerClass {
    
    //ESESP-3751 @Bhavesh kumar
    //Method to update the attachment as Private
    // changes for ESESP-4659 : GSS PS users should be able to delete the files uploaded from ACC
    public static void updateIsPrivateToTrueInAttachment(List<SObject> newList)
	{
        List<Attachment> attList = new List<Attachment>();
        for(Attachment eachAttachment :(List<Attachment>)newList)
        {
            if(String.valueOf(eachAttachment.ParentId).startsWith('500') && eachAttachment.CreatedById != SCUserIdCustomSetting__c.getValues('PulsarCaseMgmtUserID').UserId__c)
            {
                Attachment att = new Attachment();
                att.id = eachAttachment.id;
                att.isPrivate = true;
                attList.add(att); 
            }
            
        }
        if(attList.size() > 0)
        	update attList;
    }
    
    //Method to update Case field updateCaseAlert and send email to case owner
    public static void sendMailForCaseAttachment(List<SObject> newList)
	{
		//list of cases
        list<String> lCaseIds = new list<String>();
        
        //Map to store Case Id and Attachments
        map<string,list<Attachment>> mCaseAndAttachment = new map<string,list<Attachment>>();
        
        //List of attachments
        List<Attachment> attachmentTriggerNew = (List<Attachment>)newList;

        //populating mCaseAndAttachment if attachment owner is Luna Portal Integration or Pulsar Case Mgmt Users
        for(Attachment eachAttachment :attachmentTriggerNew){
            if(String.valueOf(eachAttachment.ParentId).startsWith('500') && 
               (eachAttachment.OwnerId == SCUserIdCustomSetting__c.getValues('LunaPortalIntegration').UserId__c ||
               eachAttachment.OwnerId == SCUserIdCustomSetting__c.getValues('PulsarCaseMgmtUserID').UserId__c))
            {
                lCaseIds.add(eachAttachment.ParentId);
                
                if(!mCaseAndAttachment.containsKey(eachAttachment.ParentId))
                    mCaseAndAttachment.put(eachAttachment.ParentId, new list<Attachment>());
                
                mCaseAndAttachment.get(eachAttachment.ParentId).add(eachAttachment);   
            }
        }
        
        SCCaseAttachmentHandler instanceSCCaseAttachmentHandler = new SCCaseAttachmentHandler();
        instanceSCCaseAttachmentHandler.updateCaseAndSendMail(mCaseAndAttachment);
	}

}