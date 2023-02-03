/*
    Author : Saket More
    Ticket : SFDC-6908
*/
global class GSM_AccountReassignmentAutoRejection implements Schedulable
{
    Map<Id, String> arrIdToEmail= new Map<Id, String>();
    Map<Id, Account_Reassignment__c> arrIdToARR= new Map<Id, Account_Reassignment__c>();
    
    global void execute(SchedulableContext ctx) 
    {
        sendMailAndAutoRejectARR();
    }
    
    public void sendMailAndAutoRejectARR(){
        
        Set<Account_Reassignment__c> arrAutoRejectList = new Set<Account_Reassignment__c>(); //List containing Account Reassignment Requests that need to be Auto Rejected
        Set<Id> arrIdForSendEmail = new Set<Id>(); // List containing Account Reassignment Requests for which we need to send the notification email.
        List<Messaging.SingleEmailMessage > mailList = new List<Messaging.SingleEmailMessage >();
        Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();
       
        Date sendEmailDate = Date.today().addDays(-1 * Integer.valueof(GsmUtilClass.getGSMSettingValue('Acc_Reassignment_Pending_Days_Interval'))); // 30 days from submission of ARR approval
        Date sendReminderEmailDate = Date.today().addDays(-1 * Integer.valueof(GsmUtilClass.getGSMSettingValue('Acc_Reassignment_Reminder_Days_Interval'))); // 44 days from submission of ARR approval
        Date autoRejectDate = Date.today().addDays(-1* Integer.valueof(GsmUtilClass.getGSMSettingValue('AccReassignment_AutoReject_Days_Interval'))); // 45 days from submission of ARR approval

        List<String> PoolUserAlias = GsmUtilClass.getGsmSettingValue('Account_Pool_Users').split(',');

        List<String> emailTemplateDevNames = GsmUtilClass.getGSMSettingValue('AccountReassignmentReminderEmail').split(',');
        List<EmailTemplate> templates = [select Id, DeveloperName, Subject, HtmlValue, Body from EmailTemplate where DeveloperName IN : emailTemplateDevNames Order by DeveloperName];

        for(Account_Reassignment__c arr : [Select id, CreatedById, CreatedBy.name, CreatedBy.Email, Approval_Submitted_Date__c, Reassign_Status__c, Account__r.name, Rejected_On__c, Status_Message__c, Validation_Override__c from Account_Reassignment__c where Reassign_Status__c = 'Approval Pending' and Reassign__c = false and (Approval_Submitted_Date__c =: sendEmailDate OR Approval_Submitted_Date__c =: sendReminderEmailDate OR Approval_Submitted_Date__c =: autoRejectDate) limit 50000]){
            arrIdToARR.put(arr.Id, arr);
        }
    
        if(arrIdToARR.size() > 0){
            List<Approval.ProcessWorkitemRequest> allReq = new List<Approval.ProcessWorkitemRequest>(); 
            Approval.ProcessResult[] result2;
            
            for(ProcessInstanceWorkitem piw : [Select id, ActorId, Actor.Name, actor.Email, actor.isactive, actor.alias,ProcessInstance.TargetObjectId from ProcessInstanceWorkitem where ProcessInstance.TargetObjectId IN :arrIdToARR.keyset() limit 50000]){
                if(arrIDtoArr.get(piw.ProcessInstance.TargetObjectId).Approval_Submitted_Date__c == autoRejectDate){
                    System.debug('Inside This IF');
                    //Auto Reject the Account Reassignment Request with the following details.
                    Account_Reassignment__c arrAutoReject = new Account_Reassignment__c(Id = piw.ProcessInstance.TargetObjectId);
                    arrAutoReject.Reassign_Status__c = 'Auto Rejected';
                    arrAutoReject.Rejected_On__c = Date.today();
                    arrAutoReject.Status_Message__c = 'The account reassignment request was Auto Rejected.';
                    arrAutoReject.Validation_Override__c = True;
                    arrAutoRejectList.add(arrAutoReject);

                    //Auto Reject the pending approval on the Account Reassignment Request
                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setAction('Reject');
                    req.setComments('Auto Rejected');
                    req.setWorkitemId(piw.Id);
                    allReq.add(req);
                    system.debug('allReq:'+allReq);
                    
                }
                else{
                    //Creating Account Reassignment Request Id to Approver ID map
                    if(piw.actor.isactive && !PoolUserAlias.contains(piw.actor.alias)){
                        arrIdForSendEmail.add(piw.ProcessInstance.TargetObjectId);
                        if(arrIdToEmail.containsKey(piw.ProcessInstance.TargetObjectId)){
                            String toEmail = arrIdToEmail.get(piw.ProcessInstance.TargetObjectId);
                            toEmail = toEmail + ',' + piw.ActorId;
                            arrIdToEmail.put(piw.ProcessInstance.TargetObjectId, toEmail);
                        }
                        else{
                            String toEmail = piw.ActorId;
                            arrIdToEmail.put(piw.ProcessInstance.TargetObjectId, toEmail);
                        }
                    }
                }
            }

            System.debug('arrIdToEmail:'+arrIdToEmail);
            System.debug('arrIdToARR:'+arrIdToARR);
            
            //Proccessing and creating emails(Notification/Reminder) for pending Account Assignment Request approvals
            for(Id arrId : arrIdForSendEmail){
                Account_Reassignment__c arr = arrIdToARR.get(arrId);
                if(arr.Approval_Submitted_Date__c == sendEmailDate){
                    sendEmailList.add(createEmailFromTemplate(templates[1],arrId));             
                }
                else if(arr.Approval_Submitted_Date__c == sendReminderEmailDate){
                    sendEmailList.add(createEmailFromTemplate(templates[0],arrId));
                }
            }
            
            //Sending notification emails to the approvers. 
            if(sendEmailList.size()>0){
                System.debug('Mail triggered:'+sendEmailList);
                Messaging.SendEmailResult[] sendEmailResultList = new List<Messaging.SendEmailResult>();
                Integer count = 0;
                Integer failedcount = 0;
                String result='\nSending Email started:';
                sendEmailResultList = Messaging.sendEmail(sendEmailList, false);
                //For Debugging purposes:
                for(Messaging.SendEmailResult sr : sendEmailResultList) {
                    if(!sr.isSuccess())
                    {
                        //string err = sr.getErrors();//[0];
                        result+='\nError getMessage:'+sr.getErrors()[0].getMessage();
                        result+='##getFields:'+sr.getErrors()[0].getFields();
                        result+='##getStatusCode:'+sr.getErrors()[0].getStatusCode();
                        result+='##getTargetObjectId:'+sr.getErrors()[0].getTargetObjectId();
                        result+='##record count:'+count;
                    }
                    count++;
                }
                result+='\nNo. Of emails sent:'+(count-failedcount);
                System.debug('Email Result:'+result);
            }

            
            if(arrAutoRejectList.size() > 0){
                result2 = Approval.process(allReq);
                System.debug('result2:'+result2);
                List<Account_Reassignment__c> arrAutoRejectionList = new List<Account_Reassignment__c>(arrAutoRejectList);
                GsmUtilClass.doDatabaseUpdate(arrAutoRejectionList,'GSM_AccountReassignmentAutoRejection','sendMailAndAutoRejectARR');
            }
        }
    }
    // Creating email for Account Reassignment Notification(30th Day email and 44th day Reminder Email)
    @TestVisible private Messaging.SingleEmailMessage createEmailFromTemplate(EmailTemplate emailTemplate, Id arrId){
        System.debug('Account Reassignment ID:'+arrId);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String email = arrIdToARR.get(arrId).CreatedBy.Email;
        list<String> toAdd = arrIdToEmail.get(arrId).split(',');
        list<String> ccAddress = email.split(',');
        list<Id> toAddress = new list<Id>();
        mail.setTargetObjectId(Id.valueOf(toAdd[0]));
        for(Integer i = 1; i < toAdd.size(); i++){
            toAddress.add(Id.valueOf(toAdd[i]));
        }      
        mail.setWhatId(arrId);
        if(!toAddress.isEmpty())
            mail.setToAddresses(toAddress);
        mail.setCcAddresses(ccAddress);
        mail.setTemplateId(emailTemplate.Id);
        mail.setSaveAsActivity(false);
        return mail;
    }
}