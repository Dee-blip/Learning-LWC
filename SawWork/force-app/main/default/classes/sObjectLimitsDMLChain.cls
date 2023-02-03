public class sObjectLimitsDMLChain implements Promise.Deferred
{
    public sObjectLimitsDMLChain(){}

    public static Object resolve(Object incomingObject)
    {
        String returnStatus = 'res';
        if(incomingObject!= null)
        {
            List<sObject_Limit__c> limitsToSyncList = (List<sObject_Limit__c>)incomingObject;
            List<sObject_Limit__c> toUpdate = [Select Id, Component_Type__c, Object_Name__c, Current_Usage_Count__c, Max_Limit__c, Remaining_Limit__c, Date_when_Threshold_limit_exceeded__c, Ageing_in_Days__c, Proposed_Action__c from sObject_Limit__c];
            List<sObject_Limit__c> toInsert = new List<sObject_Limit__c>();

            System.Debug(LoggingLevel.Error, 'limitsToSyncList incomingObject:' + incomingObject);
            
            Integer thresholdLimit = Integer.ValueOf(GsmUtilClass.getGSMSettingValue('Threshold_limit_to_track_sObject_Limits'));
            for(sObject_Limit__c eachLimitRecord : limitsToSyncList)
            {
                Boolean recordExist = false;
                for(sObject_Limit__c sol : toUpdate)
                {
                    if(sol.Component_Type__c == eachLimitRecord.Component_Type__c && sol.Object_Name__c == eachLimitRecord.Object_Name__c)
                    {
                        sol.Max_Limit__c = eachLimitRecord.Max_Limit__c;
                        sol.Remaining_Limit__c = eachLimitRecord.Remaining_Limit__c;
                        sol.Current_Usage_Count__c = eachLimitRecord.Current_Usage_Count__c;
                        if((100 * eachLimitRecord.Current_Usage_Count__c/eachLimitRecord.Max_Limit__c) >= thresholdLimit && sol.Ageing_in_Days__c == 0)
                            sol.Date_when_Threshold_limit_exceeded__c = Date.today();
                        else if((100 * eachLimitRecord.Current_Usage_Count__c/eachLimitRecord.Max_Limit__c) < thresholdLimit)
                            sol.Date_when_Threshold_limit_exceeded__c = null;
                        recordExist = true;
                    }
                }
                if(!recordExist)
                {
                    if((100 * eachLimitRecord.Current_Usage_Count__c/eachLimitRecord.Max_Limit__c) >= thresholdLimit)
                        eachLimitRecord.Date_when_Threshold_limit_exceeded__c = Date.today();
                    else if((100 * eachLimitRecord.Current_Usage_Count__c/eachLimitRecord.Max_Limit__c) < thresholdLimit)
                        eachLimitRecord.Date_when_Threshold_limit_exceeded__c = null;
                    toInsert.add(eachLimitRecord);
                }
            }

            if(!toInsert.isEmpty())
                insert toInsert;

            if(!toUpdate.isEmpty())
                update toUpdate;

            List<sObject_Limit__c> toSendEmail = [Select Id, Component_Type__c, Object_Name__c, Current_Usage_Count__c, Max_Limit__c, Remaining_Limit__c, Date_when_Threshold_limit_exceeded__c, Ageing_in_Days__c, Proposed_Action__c from sObject_Limit__c];
            for(sObject_Limit__c sol : toSendEmail)
            {
                if(math.mod(Integer.ValueOf(sol.Ageing_in_Days__c), 100) == 1)
                    sendEmail(sol);
            }
        }
        return incomingObject;
    }

    public static Boolean sendEmail(sObject_Limit__c eachLimitRecord)
    {
        List<String> toRecipient = GsmUtilClass.getGSMSettingValue('sObject_limit_exceeded_alert_recipient').split(',');
        List<String> ccRecipient = new List<String> ();
        Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();
        List<EmailTemplate> tplList = [select Id, Body, Subject FROM EmailTemplate WHERE Name = 'sObject Threshold Limit Exceeded Email Alert' limit 1];
        if(!tplList.isEmpty())
        {
            EmailTemplate tpl = tplList[0];
            String message = tpl.Body;
            String subject = tpl.Subject;
            message = message.replace('{!sObject_Limit__c.Object_Name__c}', eachLimitRecord.Object_Name__c);
            message = message.replace('{!sObject_Limit__c.Component_Type__c}', eachLimitRecord.Component_Type__c);
            message = message.replace('{!sObject_Limit__c.Max_Limit__c}', String.valueOf(eachLimitRecord.Max_Limit__c));
            message = message.replace('{!sObject_Limit__c.Remaining_Limit__c}', String.valueOf(eachLimitRecord.Remaining_Limit__c));
            message = message.replace('{!sObject_Limit__c.Current_Usage_Count__c}', String.valueOf(eachLimitRecord.Current_Usage_Count__c));
            message = message.replace('{!sObject_Limit__c.Proposed_Action__c}', eachLimitRecord.Proposed_Action__c);
            message = message.replace('{!sObject_Limit__c.Ageing_in_Days__c}', String.valueOf(eachLimitRecord.Ageing_in_Days__c));
            Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
            mail.setToAddresses(toRecipient);
            mail.setSubject(subject);
            if(ccRecipient!=null)
                mail.setCcAddresses(ccRecipient);
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setPlainTextBody(message);
            mail.setTemplateId(tpl.Id);
            sendEmailList.add(mail);
            List<Messaging.Sendemailresult> results = Messaging.sendEmail(sendEmailList);
            if(results[0].isSuccess()==true)
                return true;
        }
        return false;
    }
}