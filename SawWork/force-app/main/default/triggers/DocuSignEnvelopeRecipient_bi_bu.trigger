trigger DocuSignEnvelopeRecipient_bi_bu on dsfs__DocuSign_Envelope_Recipient__c (before insert, before update) 
{
	// If Signer is not of type - Signer; set Role Name to NULL
	for (dsfs__DocuSign_Envelope_Recipient__c dser: Trigger.new)
 	{
 		dser.dsfs__DocuSign_Recipient_Role__c = dser.dsfs__RoleName__c; //Added by Swati 

 		if (dser.dsfs__DocuSign_Signer_Type__c != 'Signer')
 			dser.dsfs__RoleName__c = null;
 	}
}