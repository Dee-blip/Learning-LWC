public class LeanData_Account_Match_Controller {
    public String Record {get;set;}
    public List<sObject> Records {get;set;}
    public String initialURL {get;set;}
    public String errorUnselected {get;set;}
    public String ErrorMessage {get;set;}
    public LeanData_Account_Match_Controller(ApexPages.StandardSetController controller) {
          controller.setPageSize(10);
          Records = new List<sObject>();
          Records = (List<sObject>)controller.getSelected();
          List<String> recordIds = new List<String>();
          for(sObject ld: Records)
            recordIds.add(ld.id);
           system.debug(LoggingLevel.ERROR,'List of Records:: '+Records);
           System.PageReference prf= controller.cancel();
           initialURL = prf.getUrl();
           //Check if the invocation is from list view
           //To do: try if you can get the list view call from redirctor page.
           String curPageId = ApexPages.currentPage().getParameters().get('id');
           if(curPageId!=null){
               recordIds.clear();
               recordIds.add(curPageId);
           }
           Record = json.serialize(recordIds);
           
    }
    @AuraEnabled
    public static Boolean checkProfile(string sObjectName)
    {
        Id profileId= userinfo.getProfileId();
		String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
		system.debug(Logginglevel.ERROR,'Profile Name:'+profileName);
        List<String> profiles = new List<string>();
        List<String> ProfileList = new List<String>();
        if(sObjectName == 'Lead')
            ProfileList = MarketingUtilClass.getMarketingSettingValuePartialMatch('LeanDataAccountMatchLeadProfiles');
        else if (sObjectName == 'Contact')
	        ProfileList = MarketingUtilClass.getMarketingSettingValuePartialMatch('LeanDataAccountMatchContactProfiles');
        System.debug(Logginglevel.ERROR,'Profile List:'+ProfileList);
        for(String s:ProfileList)
        {
            profiles.addAll(s.split(','));
            
        }
        if (!profiles.contains(profileName))
        {
            return false;
        }
        return true;
        
    }
    @AuraEnabled
    public static String checkRecords(string sObjectName,List<Id> recordIds){
        string returnMessage = '';
        if(sObjectName == null && !recordIds.isEmpty())
        {
            sObjectName = recordIds[0].getSObjectType().getDescribe().getName();
        }
        List<Lead> leadList = new List<Lead>();
        List<Contact> contactList = new List<Contact>();
        List<string> errors = new List<string>();
        Integer countErrorRecords = 0; 
        if(!recordIds.isEmpty())
        {
            if(sObjectName == 'Contact')
            {
                Boolean isValidProfile = checkProfile(sObjectName);
                if(!isValidProfile)
                {
                    return 'This operation is not permitted for the current user';
                }
                system.debug(Logginglevel.ERROR,'Checking In Contact Control');
                contactList = [Select id,Name,AccountId,LeanData_Reporting_Matched_Account__c from Contact where Id in :recordIds];
                system.debug(Logginglevel.ERROR,'Contacts:'+contactList);
                for (Contact personContact: contactList)
                {
                    if(personContact.LeanData_Reporting_Matched_Account__c  == null)
                    {
                        errors.add('No LeanData reporting matched Account for Contact : '+ personContact.Name);
                        countErrorRecords++;
                    }
                }       
            }
            else if(sObjectName == 'Lead')
            {
                Boolean isValidProfile = checkProfile(sObjectName);
                if(!isValidProfile)
                {
                    return 'This operation is not permitted for the current user';
                }
                system.debug(Logginglevel.ERROR,'In Lead Control');
                leadList = [Select id,Name,Associated_Account__c,LeanData__Reporting_Matched_Account__c,Lead_Record_Type__c from Lead where Id in :recordIds];
                system.debug(Logginglevel.ERROR,'Leads:'+leadList);
                for(Lead personLd: leadList)
                {  
                    if(personLd.Lead_Record_Type__c != 'Marketo Lead')
                    {
                        errors.add('The Lead:'+personLd.name+' is not a marketo Lead.Accepting the Account match is available only for Marketo Leads');
                        countErrorRecords++;
                    }
                    else if(personLd.LeanData__Reporting_Matched_Account__c == null)
                    {
                        errors.add('No LeanData reporting matched Account for Lead : '+ personLd.Name);      
                        countErrorRecords++;
                    }
                }
            }
        }
        if(recordIds.isEmpty())
        {
            returnMessage = 'Error|No records selected';
        } 
        else 
        {
            if(errors.isEmpty())
            {
                system.debug(Logginglevel.ERROR,'No Error Records');
	            returnMessage = 'Success';
            }
            else
            {
                if(countErrorRecords == recordIds.size() && countErrorRecords!=0)
                {
                    returnMessage+='Error|';
                }
                else
                {
                    returnMessage+='Success|';
                }
                returnMessage += 'Error in '+countErrorRecords+' out of '+ recordIds.size() +' records. Please Check if all the selected items have the LeanData Reporting Matched Account set or in the case of Leads , if they are Marketo Leads';
            }
                
        }
        return returnMessage;
    }
    
    @AuraEnabled
    public static String updateMultipleAccountControl(string sObjectName,List<Id> recordIds){
        String returnMessage = 'Success';
        if(sObjectName == null && !recordIds.isEmpty())
        {
            sObjectName = recordIds[0].getSObjectType().getDescribe().getName();
        }
        system.debug(Logginglevel.ERROR,'Entered Multiple Account update function:'+recordIds);
        List<Lead> leadList = new List<Lead>();
        List<Contact> contactList = new List<Contact>();
        List<Contact> toUpdateContacts = new List<Contact>();
        List<Lead> toUpdateLeads = new List<Lead>();
        List<String> errors = new List<string>();
        if(!recordIds.isEmpty())
        {
            if(sObjectName == 'Contact')
            {
                Boolean isValidProfile = checkProfile(sObjectName);
                if(!isValidProfile)
                {
                    return 'This operation is not permitted for the current user';
                }
                system.debug(Logginglevel.ERROR,'In Contact Control');
                //MARIT-919 added LeanData_Account_Match_Source__c logic 
                contactList = [Select id,Name,AccountId,LeanData_Reporting_Matched_Account__c,LeanData_Account_Match_Source__c from Contact where Id in :recordIds];
                system.debug(Logginglevel.ERROR,'Contacts:'+contactList);
                for (Contact personContact: contactList)
                {
                    if(personContact.LeanData_Reporting_Matched_Account__c  != null)
                    {
                        personContact.AccountId = personContact.LeanData_Reporting_Matched_Account__c;
                        personContact.LeanData_Account_Match_Source__c = 'Accept Account Match - Manual Association';
                        toUpdateContacts.add(personContact);
                        
                    }
                    else 
                    {
                        errors.add('No LeanData reporting matched Account for Contact : '+ personContact.Name);
                    }
                }       
            }
            else if(sObjectName == 'Lead')
            {
                Boolean isValidProfile = checkProfile(sObjectName);
                if(!isValidProfile)
                {
                    return 'This operation is not permitted for the current user';
                }
                system.debug(Logginglevel.ERROR,'In Lead Control');
                //MARIT-919 added LeanData_Account_Match_Source__c logic 
                leadList = [Select id,Name,Associated_Account__c,LeanData__Reporting_Matched_Account__c,Lead_Record_Type__c,LeanData_Account_Match_Source__c from Lead where Id in :recordIds];
                system.debug(Logginglevel.ERROR,'Leads:'+leadList);
                for(Lead personLd: leadList)
                {
                
                    if(personLd.Lead_Record_Type__c == 'Marketo Lead' && personLd.LeanData__Reporting_Matched_Account__c != null)
                    {
                        personLd.Associated_Account__c = personLd.LeanData__Reporting_Matched_Account__c;
                        personLd.LeanData_Account_Match_Source__c = 'Accept Account Match - Manual Association';
                        toUpdateLeads.add(personLd);
                        
                    }
                    else 
                    {
                        if(personLd.Lead_Record_Type__c != 'Marketo Lead')
                            errors.add('The Lead:'+personLd.name+' is not a marketo Lead.Accepting the Account match is available only for Marketo Leads');
                        else if(personLd.LeanData__Reporting_Matched_Account__c == null)
                        	errors.add('No LeanData reporting matched Account for Lead : '+ personLd.Name);
                     }
                    
                }
            }
            try
            {
                if(!toUpdateLeads.isEmpty())
                {
	                update toUpdateLeads;
                }
                else
                {
                    if(sObjectName == 'Lead')
	                    return String.join(errors,'<br />');
                }
                
                if(!toUpdateContacts.isEmpty())
                {
                    update toUpdateContacts; 
                }
                else
                {
                    if(sObjectName == 'Contact')
                       return String.join(errors,'<br />');
                }
            }
            catch(DmlException e)
            {
                system.debug(Logginglevel.ERROR,'Error Message '+e.getMessage());
                return e.getMessage();
            }
            catch (Exception e)
            {                     
                system.debug(Logginglevel.ERROR,'Error Message '+e.getMessage());
                
                //String errorMessage = e.getMessage();
                //errorMessage = e.getMessage();
                //Error_Log__c elc = new Error_Log__c(Name='', Class__c='LeanData_Account_Match_Controller', Error_Message__c=e.getMessage());
                //insert elc;
                
                return e.getMessage();
            }
            
        }
        return returnMessage;
    }
    @AuraEnabled
    public static String getUIThemeDescription() 
    {
        system.debug(Logginglevel.ERROR,'Getting Theme');
        String theme = UserInfo.getUiThemeDisplayed();
        system.debug(Logginglevel.ERROR,'theme == '+theme);
        return theme;
    }

}