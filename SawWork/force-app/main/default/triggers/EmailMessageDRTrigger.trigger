/* ========================================================================
    Author: Sonia Sawhney
    Description: CR 2753364 - Need to Sync Email messages from Prod to DR and Vice Verse
                 Used for creating entries in the Email message shadow object
                 when a new email message is created
    Created Date : 07/24/2014
    ========================================================================
    Pinkesh               19-May-2020       ESESP-3043 : Adding Private Email Draft Functionality
    ======================================================================== */
trigger EmailMessageDRTrigger on EmailMessage (after insert, after update) {
    if(!UserInfo.getName().equalsIgnoreCase('Connection User') && trigger.isAfter && (trigger.isInsert || trigger.isUpdate) &&
    (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass)))
    {
        List<Email_Message_Shadow__c> emailMessages = new List<Email_Message_Shadow__c>();
        //Create a record in the shadow object when new email message is created
        for(EmailMessage msg : Trigger.new){
            if(msg.ParentId != null && msg.ParentId.getSObjectType() == Schema.Case.sobjectType && msg.Status != '5')
            {
                Email_Message_Shadow__c msgShadow = new Email_Message_Shadow__c(
                    ActivityId__c = msg.ActivityId,
                    Bcc__c = msg.BccAddress,
                    Cc__c = msg.CcAddress,
                    FromAddress__c = msg.FromAddress,
                    FromName__c = msg.FromName,
                    Email_Headers__c = msg.Headers,
                    HtmlBody__c = msg.HtmlBody,
                    Incoming__c = msg.Incoming,
                    MessageDate__c = msg.MessageDate,
                    ParentId__c = msg.ParentId,
                    ReplyToEmailMessageId__c = msg.ReplyToEmailMessageId,
                    Status__c = msg.Status,
                    Subject__c = msg.Subject,
                    TextBody__c = msg.TextBody,
                    To__c = msg.ToAddress,
                    LocalRecordId__c = msg.Id
                );
                emailMessages.add(msgShadow);
            }
        }
        if(emailMessages.size()>0)
            database.insert(emailMessages,false);
    }
}