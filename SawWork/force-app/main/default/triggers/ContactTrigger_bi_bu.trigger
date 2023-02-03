/***
    ContactTrigger_bi_bu
    @version 1.0
    @author Karteek Mekala <kmekala@akamai.com>
    @Description : This trigger is called on 'before insert' and 'before update' events on the Contacts object.
                   It takes care of the following :
                   - Address Validation.
                   - For CRM Integration Users,use Contact.Associated AKAM Account Id to populate Contact.AccountId
   @History
    --Developer         --Date          --Change
    ALI KM              06/Jul/2012     CR 1741378 Manage scores during Contact merge process
    Sonia Sawhney       30/Sep/2013     CR 2394210 Need to disable code. Bypass logic for records created through S2S sync
    Mayank Shishodia  11/Feb/2014    CR 2504208 Downgrading ERM Web Form User Access
    Shivam Verma      28/10/2014     CR 2802054 Added logic to identify the language input in the last name and update the UserInputLanguage field
    Ruchika Sharma    26/02/2015        CR 2919927 Create Contact Accout Pick list limited to User Account and children
                                            restrict the partner to create a contact on other account (for which partner should not have access to create account like customer account)
                                            except the account associated with partner contact or children of that account
    Shivam Verma        25/03/15        CR 2962001 - Country Conversion for Data.com
    Ruchika Sharma    17/04/2015     CR 2988866: Contacts & Contracts: created in Siebel has Akam System "FORCE" in SFDC
    Kartikay Nagal      27/05/15        CR 3032381- Addition of populating Sync_To_Siebel__c field on contact.
    Shivam Verma        08/10/15        CR 3176771 - Remove special characters from phone for clearing Phone Hygiene values
    Sharath Prasanna   25 Jan 2017      CR 3560081 - Setting a default work calendar to PSA contact records.   
    Aditya Sonam        30-Oct-2017     ESESP-782- JIVE NQLB Changes, Setting Account Id on Contacts Created by Jive Integration User 
    Vamsee Surya        27-Nov-2017     ESESP-841 - Delete Authorized Contacts when the Account on the Contact is changed 
    Pinkesh Rathore		03-Mar-2018		ESESP2061 - Encrypt the passphrase coming from APIs(Mulesoft Integration Profile).
     

*/                 
trigger ContactTrigger_bi_bu on Contact (before insert, before update) 
{

	//SFDC-8128 Do not call Trigger logic for Copystorm profile
    if(userinfo.getProfileId() == GsmUtilClass.getGSMSettingValue('ValidContactIntegrationProfile')){
        return;
    }
    
    if(Trigger.isUpdate && userinfo.getProfileId() == GsmUtilClass.getGSMSettingValue('SystemAdminProfileId')){
       //when Updated_Date_For_CDP__c is changed in all records with admin profile, no need to execute contact trigger code
        boolean isCDPFieldUpdated = true;
        for(Contact con: Trigger.new){
            if(con.Updated_Date_For_CDP__c == Trigger.oldMap.get(con.Id).Updated_Date_For_CDP__c){
                isCDPFieldUpdated = false;
                break;
            }
        }
        System.debug('isCDPFieldUpdated = ' + isCDPFieldUpdated);
        if(isCDPFieldUpdated){
            System.debug('Only Updated_Date_For_CDP__c is changed. Contact Trigger BI_BU code is returned');
            return;
        }  
    }
    //bypass logic for S2S created records
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        //SFDC-1128 Double Byte character recognition
        ContactTriggerClass.checkDoubleBytesValues(trigger.new);
        
        /* Check Duplicates*/
        List<Contact> checkDuplicateList = new List<Contact>();
        List<Id> accountIdList=new List<Id>(); 
        Id devRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PSA Resource').getRecordTypeId();
        //Changes by sharath for CR: 3560081. Query for the US Full Time Work Calendar
        //Changes done by Kushal for JIRA# FFPSA-1655
        //List<pse__Work_Calendar__c> workCalendars = [select id from pse__Work_Calendar__c where name = 'US Full Time' limit 1];
        list<PSA_Common_Setting__mdt> workCalendars = [select Value__c, developername from PSA_Common_Setting__mdt where developername = 'US_Full_Time_WorkCalendarId' and type__c = 'WorkCalendar' limit 1];
        system.debug('workCalendars ***'+workCalendars);    
        id uSFullTimeWorkCalendar;
        if(workCalendars != null && workCalendars.size() > 0)
        {
            // changes by Sujay to avoid test failure in lower sandboxes
            uSFullTimeWorkCalendar = Test.isRunningTest() ? null : id.valueof(workCalendars.get(0).Value__c);
            //uSFullTimeWorkCalendar = id.valueof(workCalendars.get(0).Value__c);
            system.debug('uSFullTimeWorkCalendar ***'+uSFullTimeWorkCalendar);    
        }
        //End of changes by Sharath

        //Aditya's Changes
        List<SC_NQLB_ContactCreation_Acc_Usr_Info__mdt > nqlbMdt = new list<SC_NQLB_ContactCreation_Acc_Usr_Info__mdt>([Select userId__c,JIVECommunityAccount__c from SC_NQLB_ContactCreation_Acc_Usr_Info__mdt limit 1]);
        for(Contact eachCon: Trigger.new){
            if(Trigger.isUpdate){
                if(nqlbMdt.size() > 0 && eachCon.CreatedById == nqlbMdt[0].userId__c){
                    eachCon.AccountId = nqlbMdt[0].JIVECommunityAccount__c;
                }
            }
        }
        //End of Aditya's Changes

        //Vamsee's Changes Starts here - ESESP-841
        if(Trigger.isUpdate){
            List<Id> contactIdList = new List<Id>();
            for(Contact eachContact: Trigger.new){
                if(eachContact.AccountId != Trigger.oldMap.get(eachContact.id).AccountId)
                    contactIdList.add(eachContact.id);
            }
            if(contactIdList.size() > 0)
                SC_AddAuthorizedContactsCtrl.deleteAuthorizedContacts(contactIdList);
                
            //Pinkesh's changes starts here: ESESP-2061
            SC_AddAuthorizedContactsCtrl.encryptPassPhrase(Trigger.New, Trigger.OldMap);
        	//Pinkesh's changes ends here
        }
        //Vamsee's Changes Ends here
        
        //When Contact.HasOptedOutOfEmail field is unckecked, then add 4 picklist values to the Contact.Opt_In__c field
        Schema.DescribeFieldResult field = Contact.Opt_In__c.getDescribe();
        List<Schema.PicklistEntry> pickListValues = field.getPicklistValues();
        String selectedValues = '';
        for(Schema.PicklistEntry p: pickListValues)
            selectedValues=selectedValues+p.getValue()+';';
        
        for(Contact c: Trigger.New)
        {
            if(Trigger.isUpdate)
            {   
                if(!c.HasOptedOutOfEmail && Trigger.oldMap.get(c.Id).HasOptedOutOfEmail != c.HasOptedOutOfEmail)
                {
                    if(c.Opt_In__c == '' || c.Opt_In__c == null)
                        c.Opt_In__c = selectedValues;
                }
                        
                if(c.HasOptedOutOfEmail && Trigger.oldMap.get(c.Id).HasOptedOutOfEmail != c.HasOptedOutOfEmail)
                {
                    c.Opt_In__c = '';
                }
                //Start Of Changes By Samir to Update PSA Override Flag for PSA Resources CR : 2545914
                if(c.RecordTypeId == devRecordTypeId && c.PSA_Override__c == FALSE)
                  {
                    c.PSA_Override__c = TRUE;
                  }
                //Start of Changes by sharath for CR: 3560081.Setting a default work calendar to PSA contact records.
                if(c.RecordTypeId == devRecordTypeId && c.pse__Work_Calendar__c == null && uSFullTimeWorkCalendar != null)
                {
                    c.pse__Work_Calendar__c = uSFullTimeWorkCalendar;
                }
                //End of changes by Sharath

            }
            if(Trigger.isInsert)
            {
                if(!c.HasOptedOutOfEmail)
                {
                    if(c.Opt_In__c == '' || c.Opt_In__c == null)
                        c.Opt_In__c = selectedValues;
                }
                
                if(c.HasOptedOutOfEmail)
                {
                    c.Opt_In__c = '';
                }
                 //Start Of Changes By Samir to Update PSA Override Flag for PSA Resources CR : 2545914
                  if(c.RecordTypeId == devRecordTypeId)
                  {
                    c.PSA_Override__c = TRUE;
                  }
                //Start of Changes by sharath for CR: 3560081.Setting a default work calendar to PSA contact records.
                if(c.RecordTypeId == devRecordTypeId && c.pse__Work_Calendar__c == null && uSFullTimeWorkCalendar != null)
                {
                    c.pse__Work_Calendar__c = uSFullTimeWorkCalendar;
                }
                //End of changes by Sharath
                  
            }
        }
  
        if (Trigger.isbefore) 
        {
            ByPassAndLimitUtils.setAkamField(Trigger.isInsert,Trigger.isUpdate,Trigger.new);

        /*Code By Knagal: 
            Code to check if any of the fields which are synced  to Siebel are updated by any user other than CrmIntegration
        */

            SyncToSiebelFieldsClass.populateSyncToSiebelField('Contact');
        }

    }
}