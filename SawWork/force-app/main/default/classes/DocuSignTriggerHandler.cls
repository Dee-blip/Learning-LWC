public without sharing class DocuSignTriggerHandler extends ApexTriggerHandlerAbstractClass{

    public DocuSignTriggerHandler(){}
    
    public override void beforeInsertBeforeUpdateTrigger()
    {
        Map<String,OA_eSign_Intermediate__c> customSettings = OA_eSign_Intermediate__c.getAll();
        map<id,string> opptyOrderIdMap =new map<id,string>();
        set<id> orderApprovalIds= new set<id>();
        set<id> opptyids = new set<id>();
        list<order_approval__c> orderApprovalList = new list<order_approval__c>();
        map<id,date> IdExpireExecuteDateMap=new map<id,date> ();
        list<opportunity> associatedOppty=new list<opportunity>();
         List<dsfs__DocuSign_Envelope__c> EnvelopeTriggerNew = (List<dsfs__DocuSign_Envelope__c>)newList;
       
        for(dsfs__DocuSign_Envelope__c dsEnvelope : EnvelopeTriggerNew){
            if(dsEnvelope.dsfs__Source_Object__c != '' )
                orderApprovalIds.add(dsEnvelope.dsfs__Source_Object__c);

         }

          orderApprovalList=[select id,Order_Expires_Unless_Duly_Executed_By__c, Associated_Opportunity__c from order_approval__c where id in: orderApprovalIds];

          for(order_approval__c ord : orderApprovalList){
                if(!IdExpireExecuteDateMap.containsKey(ord.id))
                    IdExpireExecuteDateMap.put(ord.id,ord.Order_Expires_Unless_Duly_Executed_By__c);
                if(!opptyOrderIdMap.containsKey(ord.Associated_Opportunity__c))
                    opptyOrderIdMap.put(ord.Associated_Opportunity__c,ord.id);
                 
                    opptyids.add(ord.Associated_Opportunity__c);

          }

          
        for(dsfs__DocuSign_Envelope__c dsEnvelope : EnvelopeTriggerNew){
            system.debug('swati>>'+dsEnvelope.dsfs__Source_Object__c);
            
           system.debug('swati>>'+dsEnvelope.dsfs__DocuSign_Email_Message__c);
    
           // String emailBodyStr ='I am sending you this request for your electronic signature, please review and electronically sign by following the link below.';
             string   emailBodyStr = GSMSettings.getVerbose('DocuSignAccountConfiguration_EmailBody');
               system.debug('Swati>>'+emailBodyStr);
                emailBodyStr = emailBodyStr.replace('[FirstName]',Userinfo.getFirstName());
                emailBodyStr = emailBodyStr.replace('[LastName]',Userinfo.getLastName());
                emailBodyStr = emailBodyStr.replace('[Email]',userinfo.getuserEmail());
                dsEnvelope.dsfs__DocuSign_Email_Subject__c = GSMUtilClass.getGSMSettingValue('DocuSignAccConfig_EmailSubject');
               system.debug('Swati>>'+emailBodyStr);
                dsEnvelope.dsfs__DocuSign_Email_Message__c = emailBodyStr;
                
                system.debug('swati>>'+dsEnvelope.dsfs__DocuSign_Email_Message__c);
                // Reminder & Expiration fields
                dsEnvelope.dsfs__Day_Prior_to_Warn_of_expiration__c = integer.valueof(GSMUtilClass.getGSMSettingValue('Docusign_DefaultWarnOfExpireNDays')); //dsConfiguration.dsfs__DefaultWarnOfExpireNDays__c;
                dsEnvelope.dsfs__Reminder_Interval__c = integer.valueof(GSMUtilClass.getGSMSettingValue('Docusign_DefaultReminderNDays')); //dsConfiguration.dsfs__DefaultReminderNDays__c;             
                dsEnvelope.dsfs__Reminder_Repeat_Interval_in_Days__c = integer.valueof(GSMUtilClass.getGSMSettingValue('Docusign_DefaultRepeatReminderNDays')); //dsConfiguration.dsfs__DefaultRepeatReminderNDays__c;
                
    
     //Add Logic to populate the Expire dates based on some date (Ex: Order_Expires_Unless_Duly_Executed_By__c)
                Decimal expireDays;
                String customExpireSettingToggle = GSM_Custom_Settings__c.getInstance('ESignature#'+'CustomExpireSettings').Value__c;
                if (customExpireSettingToggle.equalsIgnoreCase('true') && IdExpireExecuteDateMap.get(dsEnvelope.dsfs__Source_Object__c) != null && IdExpireExecuteDateMap.get(dsEnvelope.dsfs__Source_Object__c) > datetime.now())
                {
                    DateTime orderExpiresUnlessDulyExecutedBy = IdExpireExecuteDateMap.get(dsEnvelope.dsfs__Source_Object__c);
                    Date tempDate = orderExpiresUnlessDulyExecutedBy.date(); //dateGmt();
                    Date currentDate = Date.today();
                    expireDays = currentDate.daysBetween(tempDate) + Decimal.valueOf(GSM_Custom_Settings__c.getInstance('ESignature#'+'ExpireEnvelopeGraceDays').Value__c);
                    if (expireDays > 120)
                        expireDays = decimal.valueof(GSMUtilClass.getGSMSettingValue('Docusign_DefaultExpireNDays'));
                }
                else
                {
                    if (IdExpireExecuteDateMap.get(dsEnvelope.dsfs__Source_Object__c) == null)
                        expireDays = decimal.valueof(GSMUtilClass.getGSMSettingValue('Docusign_DefaultExpireNDays'));
                    else
                        expireDays= Integer.valueOf(GSM_Custom_Settings__c.getInstance('DefaultEnvelopeExpireDays'));
                       
                }
                dsEnvelope.dsfs__Days_before_Envelope_is_Expired_Voided__c = expireDays;
                system.debug('swati>>'+dsEnvelope.dsfs__Days_before_Envelope_is_Expired_Voided__c);
                
               if (customSettings.get('SendEmailReminder').Value__c !=null && customSettings.get('SendEmailReminder').Value__c =='true')
                    dsEnvelope.dsfs__Send_Reminder__c = true;
                else
                    dsEnvelope.dsfs__Send_Reminder__c = false;
                    
                    system.debug('swati>>'+dsEnvelope.dsfs__Send_Reminder__c);
        }
    
      associatedOppty = [Select Id, Associated_Order_Approval_Id__c from Opportunity where Id in :opptyids];
      
              for(opportunity oppty:associatedOppty){
                        Oppty.Associated_Order_Approval_Id__c = opptyOrderIdMap.get(oppty.id);
                        Oppty.Validation_Override__c = true;
                    }
                    //  Update Associate Opportunity
                    try
                    {
                        update associatedOppty;
                   }catch (exception ex)
                    {
                       
                        throw new CustomException('An error has occcured during email process. Please contact system administrator. Error Details : ' + ex);
                    }
    
    }
     public override void beforeDeleteBeforeUndeleteTrigger()
    {}
    public override void afterInsertAfterUpdateTrigger()
    {
    }
    public override void afterDeleteAfterUndeleteTrigger()
    {
        System.debug('This is after delete and after undelete.');
    }

}