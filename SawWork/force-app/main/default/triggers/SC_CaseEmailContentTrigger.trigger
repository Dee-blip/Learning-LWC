trigger SC_CaseEmailContentTrigger on Case_Email_Content__c (after insert) {
    if(Trigger.isAfter && Trigger.isInsert){
        SC_SendEmailFromAPIs sendEmailFromAPIInstance = new SC_SendEmailFromAPIs();
        sendEmailFromAPIInstance.sendEmailToCase(Trigger.new, Trigger.newMap);
    }
}