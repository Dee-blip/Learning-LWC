trigger PaymentTrigger on Payment__c (before insert, before update,after insert,after update) 
{
	List<Payment__c> paymentList=new List<Payment__c>();
	if(Trigger.isBefore)
	{
		for(Payment__c payment: Trigger.new)
		{
			if(Trigger.isInsert && payment.CI_Akam_Invoice_Id__c!=null)
			{
				paymentList.add(payment);
			}
			else if(!Trigger.IsInsert && payment.CI_Akam_Invoice_id__c !=Trigger.oldMap.get(payment.Id).CI_Akam_Invoice_id__c)
			{
				payment.addError('Invoice Id can not be updated after insert.');
			}
		 }
		 if(paymentList.size()>0)
			{
				CastIronClass.Resolve_Payment_Invoice_ForeignKeys(paymentList);
			}
	 }
	 if(Trigger.isAfter)
	 {
	   List<Payment__c> recieptPaymentList=new List<Payment__c>();
	   for(Payment__c rpay : Trigger.New)
	   {
	   	if(rpay.Name=='RECEIPT')
	   	{
	   		recieptPaymentList.add(rpay);
	   	}
	   }
	   if(recieptPaymentList.size()>0)
	   CastIronClass.updateAccountLastPaymentDetails(recieptPaymentList);	
	 }

}