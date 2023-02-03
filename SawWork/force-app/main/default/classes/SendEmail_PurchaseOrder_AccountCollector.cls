/* History:
 * =========================
 * @author 	Hitesh CHawda, 	25th May 2017   
 */	
 	public class SendEmail_PurchaseOrder_AccountCollector implements Queueable {
	
	//String reportLink;
	Id defaultCollectorEmail;
	Decimal remainingFundPercentage;
	EmailTemplate templateId;
	EmailTemplate templateIdDefault;

	
	public SendEmail_PurchaseOrder_AccountCollector() {
		//reportLink
		defaultCollectorEmail = GsmUtilClass.getGSMSettingValue('PurchaseOrderDefaultCollector');
		remainingFundPercentage = Decimal.valueOf(GsmUtilClass.getGSMSettingValue('PurchaseOrderRemainingFundPercentage'));
		templateId = [Select id from EmailTemplate where name = 'Notify Collector Purchase Order Fund VF'];
		templateIdDefault = [Select id from EmailTemplate where name = 'Notify Collector Purchase Order Fund Default VF'];

		system.debug('Inside Default Const');
		
	}

	
   	public void execute(QueueableContext context) {

   		String res = '';
   		List<Merge_Contract_PO__c> mchPOList = new List<Merge_Contract_PO__c>();
   		List<Merge_Contract_PO__c> mchPOListFiltered = new List<Merge_Contract_PO__c>();

   		Map<Id,Id> collectorEmailToAccountIdMap = new Map<Id,Id>();
   		Map<Id,Id> defaultcollectorEmailToAccountIdMap = new Map<Id,Id>();
        mchPOList = [Select PO_Fund__c,Remaining_Fund_Percentage__c,Original_Contract_Id__r.Account_Name__c,Original_Contract_Id__r.Account_Name__r.Collector__c,Remaining_Fund__c from Merge_Contract_PO__c Where Start_Date__c < TODAY AND End_Date__c > TODAY AND PO_Fund__c != null AND Remaining_Fund__c != null AND Remaining_Fund_Percentage__c < :remainingFundPercentage  ];
		system.debug('Inside  Execute Method '+mchPOList);
   		for(Merge_Contract_PO__c mchPO :mchPOList )
   		{
   			   						system.debug('Inside for '+mchPO.Original_Contract_Id__r.Account_Name__r.Collector__c);

   					
   					if(mchPO.Original_Contract_Id__r.Account_Name__r.Collector__c != null)
   					{
   						system.debug('Inside collector');
   						if(collectorEmailToAccountIdMap.containsKey(mchPO.Original_Contract_Id__r.Account_Name__r.Collector__c))
   							continue;
   						else
   							collectorEmailToAccountIdMap.put(mchPO.Original_Contract_Id__r.Account_Name__r.Collector__c,mchPO.Original_Contract_Id__r.Account_Name__c);
   					}
   					else
   					{
   						   						system.debug('Inside non collector '+defaultcollectorEmailToAccountIdMap);

   						if(defaultcollectorEmailToAccountIdMap.containsKey(defaultCollectorEmail))
   							continue;
   						else
   							defaultcollectorEmailToAccountIdMap.put(defaultCollectorEmail,mchPO.Original_Contract_Id__r.Account_Name__c);
   					}
				
   		}

   				system.debug('Inside  Execute Method Maps  '+collectorEmailToAccountIdMap +'MAp2 '+defaultcollectorEmailToAccountIdMap);

   		
   		List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

   		if(!collectorEmailToAccountIdMap.isEmpty())
   		{

   			for(String toAddressEmail : collectorEmailToAccountIdMap.keySet())
   			{

				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				system.debug('Target Id '+toAddressEmail + ' What Id '+collectorEmailToAccountIdMap.get(toAddressEmail));
				mail.setTargetObjectId(toAddressEmail);
				mail.setTemplateId(templateId.Id);
				mail.setWhatId(collectorEmailToAccountIdMap.get(toAddressEmail));  
				mail.setSaveAsActivity(false);
				mails.add(mail);
			}
		}
		if(!defaultcollectorEmailToAccountIdMap.isEmpty())
   		{
			for(String toAddressEmailD : defaultcollectorEmailToAccountIdMap.keySet())
			{
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				system.debug('Target Id '+toAddressEmailD + ' What Id '+defaultcollectorEmailToAccountIdMap.get(toAddressEmailD));
				mail.setTargetObjectId(toAddressEmailD);
				mail.setTemplateId(templateIdDefault.Id);
				mail.setWhatId(defaultcollectorEmailToAccountIdMap.get(toAddressEmailD));
				mail.setSaveAsActivity(false);
				mails.add(mail);
			}
		}
			
			Messaging.SendEmailResult[] resultMail = new Messaging.SendEmailResult[]{};
			 resultMail = Messaging.sendEmail(mails);

    		system.debug('Email results '+resultMail);
    		//display success or error message
    		if( resultMail.size() > 0)
    		{
	    		if (resultMail[0].isSuccess()) 
        		res = '1:Mail sent succesfully';
    		else 
        		res = 'There was some issue sending mail :'+resultMail[0].getErrors().get(0).getMessage();
        	}

        	Util.updateCronRunWithResult('Purchase Order Account Collector Email', res);


    		
   		
   			
   	}
			

	
}