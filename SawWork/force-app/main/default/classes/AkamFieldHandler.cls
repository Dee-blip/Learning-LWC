/***
    AkamFieldsHandler
    @author : Shivam Verma <shiverma@akamai.com>
    @Description : This class implements the following logic for different triggers :
                    - Generalize the logic to update the Akam related field on any object.
                      The class will take the list of sObject and update the Akam related fields.
					  The class can be called from any object trigger that have the Akam related fields and 
					  update the Akam Field on Insert and Update.
   
    @History
    --Developer           --Date            --Change
    Shivam Verma          06/04/2015        Created the class.

    --Developer           --Date            --Change
    Ruchika Sharma          16/04/2015      Modified updateHandler to check user id, put a check for pnet profile
***/
global class AkamFieldHandler {
    
    public static Map<Id, String> getAkamIds(List<Id> recordIds, String sObjType)
    {
        Map<Id, String> recordIdToAkamID = new Map<Id, String>();
        if('Account'==sObjType)
        {
            for(Account acc: [select Id, AKAM_Account_ID__c from Account where Id in :recordIds])
            {
                recordIdToAkamID.put(acc.Id, acc.AKAM_Account_ID__c);
            }
        }
        else if('Contact'==sObjType)
        {
            for(Contact ctct: [select Id, AKAM_Contact_ID__c from Contact where Id in :recordIds])
            {
                recordIdToAkamID.put(ctct.Id, ctct.AKAM_Contact_ID__c);
            }
        }

        return recordIdToAkamID;

    }
	public void insertHandler(List<sObject> newList) {
        List<String> integrationProfiles = GsmUtilClass.getGSMSettingValue('IntegrationProfilesForAKAMFields').split(','); //SFDC-6617
		for(sObject obj : newList) {
		
			//Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c); //SFDC-2304
            
			if(!((String)obj.get('AKAM_Alias__c')).contains('pnet')) {
			//This takes care OF AKAM fields while insert if any of these field is null or Empty
			  
				  if(integrationProfiles.contains(UserInfo.getProfileId()))
				  {
				      if(obj.get('AKAM_Created_By__c') == '')
				          obj.put('AKAM_Created_By__c',obj.get('AKAM_Alias__c'));
				      if(obj.get('AKAM_Created_Date__c') == null)
				          obj.put('AKAM_Created_Date__c',system.now());
				      if(obj.get('AKAM_System__c') =='')
				          obj.put('AKAM_System__c','FORCE') ;
				          if(obj.get('AKAM_Modified_Date__c')  == null)
	                    obj.put('AKAM_Modified_Date__c',system.now());
	                  if(obj.get('AKAM_Modified_By__c') == '' || obj.get('AKAM_Modified_By__c') == null)
	                    obj.put('AKAM_Modified_By__c',obj.get('AKAM_Alias__c'));
				  }
				  else
				  {
				        obj.put('AKAM_Created_By__c',obj.get('AKAM_Alias__c'));
				        obj.put('AKAM_Created_Date__c',system.now());
				        obj.put('AKAM_System__c','FORCE');
				        obj.put('AKAM_Modified_By__c',obj.get('AKAM_Alias__c'));
			    		obj.put('AKAM_Modified_Date__c',system.now());
				  }
				
			}   
		}
	}

	public void updateHandler(List<sObject> newList) {
        List<String> integrationProfiles = GsmUtilClass.getGSMSettingValue('IntegrationProfilesForAKAMFields').split(','); //SFDC-5817
		for(sObject obj : newList) {
            //Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c); //SFDC-2304
            
			if(!((String)obj.get('AKAM_Alias__c')).contains('pnet')) {
				if(integrationProfiles.contains(UserInfo.getProfileId())) {
		                if(obj.get('AKAM_Modified_Date__c')  == null)
		                    obj.put('AKAM_Modified_Date__c',system.now());
		                if(obj.get('AKAM_Modified_By__c') == '' || obj.get('AKAM_Modified_By__c') == null)
		                    obj.put('AKAM_Modified_By__c',obj.get('AKAM_Alias__c'));

	          	}
				else
				{
				    obj.put('AKAM_Modified_By__c',obj.get('AKAM_Alias__c'));
				    obj.put('AKAM_Modified_Date__c',system.now());
				}
			}
		}
	}
}