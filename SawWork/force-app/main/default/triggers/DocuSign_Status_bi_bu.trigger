/***
    DocuSign_Status_ai_au
    @version 1.0
    @author Ali KM <mohkhan@akamai.com>
    @Description : This trigger is called on 'before insert' and 'before update' events on the dsfs__DocuSign_Status__c object.
                   It takes care of the following :
                   - It looks at DocuSign Envelope and associated DERecipients and if 'dser.dsfs__RoleName__c' is Customer 
                   related it updates the DocuSign_Status__c.isCustomerUpdate to true.
    
	@History
	--Developer		      --Date			--Change
	Ali KM	  			  31/05/2011		CR 1132858 E-Sign: Flipping to SS-6 once signing process is complete shold work only 
											if Customer Signee is part of the envelope
												-> Created this Trigger 
	Ali KM				  20/06/2011		CR 1130608 eSignature enhancements
												-> Invoking Update to NextReminder Date on DocuSign Status object.
												-> Invoking a job that pulls sends out Email to Initiator (sender) after RepeatReminderNdays days inactivity by the 
												Signeed on the Envelope	
	Ali KM				  04/07/2011		CR 1185160 e-Signature: Signatory role should be updated appropriatory when a CC is added
												-> Updated logic that check for isCustomerEnvelope to also look at Signer Role Type = Signer if not then do not mark 
												the envelope as isCustomerEnvelope.																							
*/
trigger DocuSign_Status_bi_bu on dsfs__DocuSign_Status__c (before insert, before update) 
{
	// For Manual running of SS-6 flipping logic when toggle is TRUE/ON
	String strCustEnvelopeCheckManualToggle = GsmUtilClass.getGSMSettingValue('ESignature_CheckIfCustEnvToggle'); // SFDC-2705 Custom Settings Migration 
	// Feature toggle for Sender Reminder Alert email feature.
	String strDSSenderReminderAlertToggle = GsmUtilClass.getGSMSettingValue('ESignature_DSSenderReminderToggle'); // SFDC-2705 Custom Settings Migration
	
	if (strDSSenderReminderAlertToggle.equalsIgnoreCase('true'))
	{	
 		// List of all qualified DSS records
		List<dsfs__DocuSign_Status__c> dssUpdateNextAlertRunList = new List<dsfs__DocuSign_Status__c>();
		
		//String strDSEnvelopeExceptionStatus = 'Completed, Voided';
		String strDSEnvelopeExceptionStatus = GsmUtilClass.getGSMSettingValue('ESignature_DSEnvlopStatusInvalid'); 	// SFDC-2705 Custom Settings Migration
		for (dsfs__DocuSign_Status__c dss: Trigger.new)
	 	{
		 	if( dss.dsfs__Sent_Date_Time__c != null && dss.dsfs__DocuSign_Envelope_ID__c !=null && dss.dsfs__Envelope_Status__c !=null && !strDSEnvelopeExceptionStatus.contains(dss.dsfs__Envelope_Status__c)
		 		&& (Trigger.isInsert || (!Trigger.isInsert && dss.Next_Reminder_Alert__c == null && Trigger.oldMap.get(dss.Id).Next_Reminder_Alert__c == null)))
		 		{
		 			// List of all DocuSign Status Objects that Qualify for NextReminderAlert fields update.
		 			dssUpdateNextAlertRunList.add(dss);
		 			//System.debug('dss=' + dss);
		 		}
	 	}
	 	if (dssUpdateNextAlertRunList.size()>0)
	 	{
	 		DocuSignStatusTriggerClass.initializeNextReminderDate(dssUpdateNextAlertRunList);
	 	}
 	}
	
	/* SECOND APPROACH - It considers the Associated DocuSign Envelope Records ExpireDays value, this is more appropriate if you are looking for envelope specific Reminder Alerts.
	// Run only if feature is ON for both Insert & Update
	if (strDSSenderReminderAlertToggle.equalsIgnoreCase('true'))
	{
		// holds DocuSign__Status__c Id = external id map 
	 	Map<Id, String> eDSSDSExEnvIdMap = new Map<Id, String>();
	 		 	
	 	// holds set of all DocuSign__Envelope__c that contains external DocuSign Envelope Id
	 	Set<Id> dsEnvelopeIDSet = new Set<Id>();
	 	
	 	// holds set of all external Envelope IDs that have customer userRole
	 	Set<String> dssExEnvIDToUpdateSet = new Set<String>();
	 	
	 	// List of all qualified DSS records
		List<dsfs__DocuSign_Status__c> dssUpdateNextAlertRunList = new List<dsfs__DocuSign_Status__c>();
		
	 	// holds set of all External DocuSign Envelope ID
	 	Set<String> dssExternalEnvelopeIDSet = new Set<String>();
	 	
	 	// holds Map of DocuSign.Envelope ID (external Envelope Id) & the relevant DocuSign Envelope Record.
	 	Map<String, dsfs__DocuSign_Envelope__c> eDSExEnvIdDSEMap = new Map<String, dsfs__DocuSign_Envelope__c>();
		
		String strDSEnvelopeExceptionStatus = 'Completed, Voided';
		for (dsfs__DocuSign_Status__c dss: Trigger.new)
	 	{
		 	if( dss.dsfs__Sent_Date_Time__c != null && !strDSEnvelopeExceptionStatus.contains(dss.dsfs__Envelope_Status__c) && dss.dsfs__DocuSign_Envelope_ID__c !=null
		 		&& (Trigger.isInsert || (!Trigger.isInsert && dss.Next_Reminder_Alert__c == null && dss.Next_Reminder_Alert__c != Trigger.oldMap.get(dss.Id).Next_Reminder_Alert__c )))
		 		{
		 			// List of all DocuSign Status Objects that Qualify for NextReminderAlert fields update.
		 			dssUpdateNextAlertRunList.add(dss);
		 			System.debug('dss=' + dss);
		 			
		 			// Set of all ExternalEnvelopeIDs that qualify.
	 				dssExternalEnvelopeIDSet.add(dss.dsfs__DocuSign_Envelope_ID__c);
	 				System.debug('dss.dssExternalEnvelopeIDSet=' + dss.dsfs__DocuSign_Envelope_ID__c);
		 		}
	 	}
	 	if (dssExternalEnvelopeIDSet.size()>0)
	 	{
 		 	/*
	 			dsfs__Reminder_Interval__c = 1
				dsfs__Reminder_Repeat_Interval_in_Days__c = 2
				dsfs__Days_before_Envelope_is_Expired_Voided__c = 4
 			
	 		// Go over all the DocuSign Envelope records that match the DSS.External Envelope Id Set
	 		for (dsfs__DocuSign_Envelope__c dse : [Select Id, dsfs__DocuSign_Envelope_ID__c, dsfs__Reminder_Interval__c, dsfs__Reminder_Repeat_Interval_in_Days__c, 
	 			dsfs__Days_before_Envelope_is_Expired_Voided__c from dsfs__DocuSign_Envelope__c where dsfs__DocuSign_Envelope_ID__c IN :dssExternalEnvelopeIDSet]) 
	 			{
	 				// Store the DocuSign Envelope Id (external) Id & relevant DocuSign Envelope Record.
	 				eDSExEnvIdDSEMap.put((dse.dsfs__DocuSign_Envelope_ID__c).toUpperCase(), dse);
	 			}
 			System.debug('eDSExEnvIdDSEMap=' + eDSExEnvIdDSEMap);	 		
	 	}
	 	if (eDSExEnvIdDSEMap.size()>0)
	 	{
	 		for (dsfs__DocuSign_Status__c dss : dssUpdateNextAlertRunList)
	 		{	
	 			if (eDSExEnvIdDSEMap.containsKey(dss.dsfs__DocuSign_Envelope_ID__c) )
	 				//&& tempExpireSentDateTime > Datetime.now() )
 				{ 
 					Datetime tempSentDateTime = dss.dsfs__Sent_Date_Time__c;
		 			Decimal ExpireDays = eDSExEnvIdDSEMap.get(dss.dsfs__DocuSign_Envelope_ID__c).dsfs__Days_before_Envelope_is_Expired_Voided__c;
		 			Datetime tempExpireSentDateTime = tempSentDateTime.addDays(ExpireDays.intValue());
		 			System.debug('Expiration Date=' + tempExpireSentDateTime);
		 			System.debug('SentDateTime Date=' + tempSentDateTime);
		 			//System.debug('Date of Expiration = ' + dss.dsfs__Sent_Date_Time__c.addDays(Integer.valueOf(eDSExEnvIdDSEMap.get(dss.dsfs__DocuSign_Envelope_ID__c).dsfs__Days_before_Envelope_is_Expired_Voided__c)) > Datetime.now() );
		 			//System.debug('Date of Expiration = ' + dss.dsfs__Sent_Date_Time__c.addDays((eDSExEnvIdDSEMap.get(dss.dsfs__DocuSign_Envelope_ID__c).dsfs__Days_before_Envelope_is_Expired_Voided__c).intValue()) > Datetime.now() );
		 			
		 			Decimal reminderDays = eDSExEnvIdDSEMap.get(dss.dsfs__DocuSign_Envelope_ID__c).dsfs__Reminder_Repeat_Interval_in_Days__c;
		 			Datetime tempNextReminderDateTime = tempSentDateTime.addDays(reminderDays.intValue());
		 			System.debug('NextReminderDate=' + tempNextReminderDateTime);
 					//dss.Next_Reminder_Alert__c = dss.dsfs__Sent_Date_Time__c.addDays(Decimal.valueOf(eDSExEnvIdDSEMap.get(dss.dsfs__DocuSign_Envelope_ID__c).dsfs__Reminder_Repeat_Interval_in_Days__c));
 					dss.Next_Reminder_Alert__c = tempNextReminderDateTime;
 					//System.debug('dss Next Reminder Alert Date =' + dss.dsfs__Sent_Date_Time__c.addDays(Decimal.valueOf(eDSExEnvIdDSEMap.get(dss.dsfs__DocuSign_Envelope_ID__c).dsfs__Reminder_Repeat_Interval_in_Days__c)) );
 				}
	 		}
	 	}
	} */
	
	 // run only on Insert
	 if (Trigger.isInsert || strCustEnvelopeCheckManualToggle.contains('true'))
	 {
 	 	// SS-6 fix
	 	
	 	// holds DocuSign__Envelope__c Id = external id map 
	 	Map<Id, String> eDSEDSExEnvIdMap = new Map<Id, String>();
	 	
	 	// holds set of all External DocuSign Envelope ID
	 	Set<String> dssExternalEnvelopeIDSet = new Set<String>();
	 	
	 	// holds set of all DocuSign__Envelope__c that contains external DocuSign Envelope Id
	 	Set<Id> dsEnvelopeIDSet = new Set<Id>();
	 	
	 	// holds set of all external Envelope IDs that have customer userRole
	 	Set<String> dssExEnvIDToUpdateSet = new Set<String>();
	 	
 		for (dsfs__DocuSign_Status__c dss: Trigger.new)
	 	{
	 		// run this only if Envelope Status = Sent & isCustomerEnvelope is not already checked.
	 		// move this to custom setting.
	 		if (dss.dsfs__DocuSign_Envelope_ID__c != null && dss.isCustomerEnvelope__c != true )//&& dss.dsfs__Envelope_Status__c != 'Completed')
	 		{
	 			//System.debug('dss.dsfs__Envelope_Status__c=' + dss.dsfs__Envelope_Status__c);
	 			// Map of DocuSign Envelope Id & DocuSign Status Ids
	 			dssExternalEnvelopeIDSet.add(dss.dsfs__DocuSign_Envelope_ID__c);
	 		}
	 	}
	 	System.debug('dssExternalEnvelopeIDSet =' + dssExternalEnvelopeIDSet);
	 	if (dssExternalEnvelopeIDSet.size()>0)
	 	{
	 		for (dsfs__DocuSign_Envelope__c dse : [Select Id, dsfs__DocuSign_Envelope_ID__c from dsfs__DocuSign_Envelope__c 
		 		where dsfs__DocuSign_Envelope_ID__c IN :dssExternalEnvelopeIDSet])
	 			{
	 				dsEnvelopeIDSet.add(dse.Id);
	 				eDSEDSExEnvIdMap.put(dse.Id, dse.dsfs__DocuSign_Envelope_ID__c);
	 			}
 			//System.debug('dsEnvelopeIDSet =' + dsEnvelopeIDSet);
 			//System.debug('eDSEDSExEnvIdMap=' + eDSEDSExEnvIdMap);
 			if (dsEnvelopeIDSet.size()>0)
 			{
 				for (dsfs__DocuSign_Envelope_Recipient__c  dser : [Select Id, dsfs__RoleName__c, dsfs__DocuSign_Signer_Type__c, dsfs__DocuSign_EnvelopeID__c 
					from dsfs__DocuSign_Envelope_Recipient__c where dsfs__DocuSign_EnvelopeID__c IN : dsEnvelopeIDSet])
					{ 
						//if (dser.dsfs__RoleName__c != null && dser.dsfs__RoleName__c.contains('Customer'))
						if (dser.dsfs__DocuSign_Signer_Type__c != null && dser.dsfs__DocuSign_Signer_Type__c == 'Signer' && dser.dsfs__RoleName__c != null 
								&& dser.dsfs__RoleName__c.contains('Customer'))
								{
									//System.debug('dser external envelopeid =' + eDSEDSExEnvIdMap.get(dser.dsfs__DocuSign_EnvelopeID__c));
									String strEIDlower = eDSEDSExEnvIdMap.get(dser.dsfs__DocuSign_EnvelopeID__c);
									dssExEnvIDToUpdateSet.add(strEIDlower.toUpperCase());	
								}
								//System.debug('dssExEnvIDToUpdateSet=' + dssExEnvIDToUpdateSet);
					}
 			}
 			if (dssExEnvIDToUpdateSet.size()>0)
			{
				system.debug('Updating the associated DSS records');
				for (dsfs__DocuSign_Status__c dss: Trigger.new)
				{
					//System.debug('dss.dsfs__DocuSign_Envelope_ID__c=' + dss.dsfs__DocuSign_Envelope_ID__c);
					if (dssExEnvIDToUpdateSet.contains(dss.dsfs__DocuSign_Envelope_ID__c))
					{
						//System.debug('successfully updating the field');
						dss.isCustomerEnvelope__c = true;
					}
				}
			}	
	 	}
	 }	
	 	/* OTHER APPROACH
	 	
	 	//List<String> eDSSList = new List<String>();
	 	Map<String,Id> eDSEnvDSSMap = new Map<String,Id>();
	 	Map<Id,Id> eDSSDSEMap = new Map<Id,Id>();
	 	
	 	for (dsfs__DocuSign_Status__c dss: Trigger.new)
	 	{
	 		if (dss.dsfs__DocuSign_Envelope_ID__c != null && dss.isCustomerEnvelope__c != true) // && dss.dsfs__Envelope_Status__c == 'Sent')
	 		{
	 			// Map of DocuSign Envelope Id & DocuSign Status Ids
	 			//dssExternalEnvelopeIDSet.add(dss.dsfs__DocuSign_Envelope_ID__c)
	 			eDSEnvDSSMap.put(dss.dsfs__DocuSign_Envelope_ID__c, dss.Id);
	 		}
	 	}
	 	if (eDSEnvDSSMap.size()>0)
	 	{	
	 		System.debug('eDSEnvDSSMap = ' + eDSEnvDSSMap);
	 		for (dsfs__DocuSign_Envelope__c dse : [Select Id, dsfs__DocuSign_Envelope_ID__c from dsfs__DocuSign_Envelope__c where dsfs__DocuSign_Envelope_ID__c IN :eDSEnvDSSMap.keySet()])
 			{
 				// Map of DocuSign Status & DocuSign Envelope Ids
 				System.Debug('Envelope DocuSign Envelope ID = ' + dse.dsfs__DocuSign_Envelope_ID__c );
 				System.Debug('DSEnvDSSMap contains  eDSEnvDSSMap.get(dse.dsfs__DocuSign_Envelope_ID__c)= ' + eDSEnvDSSMap.get(dse.dsfs__DocuSign_Envelope_ID__c) );
 				eDSSDSEMap.put(dse.Id, eDSEnvDSSMap.get(dse.dsfs__DocuSign_Envelope_ID__c));
 			}
 			//Select Id, Name, dsfs__DocuSign_Envelope_ID__c from dsfs_DocuSign_Envelope__c where dsfs__DocuSign_Envelope_ID__c = '682B6A1E-8F9A-42D1-A59D-87F4290914AA'
 			if (eDSSDSEMap.size()>0)
 			{
 				System.debug('eDSSDSEMap = ' + eDSSDSEMap);
 				List<Id> toUpdateDSSList = new List<Id>();
 				Map<Id, Boolean> eDSSBoolMap = new Map<Id, Boolean>();
 				for (dsfs__DocuSign_Envelope_Recipient__c  dser : [Select Id, dsfs__RoleName__c, dsfs__DocuSign_Signer_Type__c, dsfs__DocuSign_EnvelopeID__c 
					from dsfs__DocuSign_Envelope_Recipient__c where dsfs__DocuSign_EnvelopeID__c IN : eDSSDSEMap.keySet()])
					{ //Customer Signatory 2 || Customer Signatory 1
						if (dser.dsfs__RoleName__c == 'Customer Signatory 1' || dser.dsfs__RoleName__c.contains('Customer'))
						{
							// set the dss.isCustomerEnvelope=true.
							// instead create a list and then update isCustomerEnvelope=true for those DocuSignStatus objects.
							//Trigger.newMap.get(eDSSDSEMap.get(dser.dsfs__DocuSign_EnvelopeID__c)).isCustomerEnvelope__c = true;
							//toUpdateDSSList.add(eDSSDSEMap.get(dser.dsfs__DocuSign_EnvelopeID__c));
							eDSSBoolMap.put(eDSSDSEMap.get(dser.dsfs__DocuSign_EnvelopeID__c), true);
						}
						if (eDSSBoolMap.size()>0)
						{	
							System.debug('eDSSBoolMap =' + eDSSBoolMap);
							for (dsfs__DocuSign_Status__c dss: Trigger.new)
							{
								if (eDSSBoolMap.containsKey(dss.Id))
								{
									System.debug('Updating isCustomerEnvelope');
									dss.isCustomerEnvelope__c = eDSSBoolMap.get(dss.Id);
									update dss;
								}
								System.debug('DSSBoolMap not found');
								// update the dss.isCustomerEnvelope
							}
						}
						else
							System.debug('Customer Match Not Found');
					}
	 		}
	 	}
	 */
	      //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); // SFDC-2705 Custom Settings Migration
    for(dsfs__DocuSign_Status__c dstatus : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (dstatus.AKAM_Created_By__c =='' || 
          dstatus.AKAM_Created_Date__c == null ||dstatus.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          dstatus.AKAM_Created_By__c = dstatus.AKAM_Alias__c ;
          dstatus.AKAM_Created_Date__c = system.now();
          dstatus.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (dstatus.AKAM_Modified_Date__c  == null|| 
        dstatus.AKAM_Modified_By__c == '' || dstatus.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        dstatus.AKAM_Modified_By__c = dstatus.AKAM_Alias__c;
        dstatus.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}