public class GSM_Lite_ContactToLeadCreateController {

    /**
      @author: Hitesh Chawda
      SFDC-2328
     * History:
     * =========================
     * Developer        Date        Description

     Hitesh Chawda    19/02/2018  Added this class part of SFDC-2328
     **/



    @AuraEnabled
    public static List<String> loadPicklistValues(String sobjectName, String picklistFieldName)
    {
        List<String> options = GSMLite_UtilClass.populatePickList(sobjectName,picklistFieldName);
        return options;
    }

    @AuraEnabled
    public static List<String> loadSDRLeadTypePicklistValues()
    {
        list<string> options= new list<string>{'SDR Self-Generated','Inbound Call','Inbound Email'};
        //List<String> options = ('SDR Self-Generated','Inbound Call','Inbound Email');
        return options;
    }

    @AuraEnabled
    public static String getUIThemeDescription() 
    {
        String theme = UserInfo.getUiThemeDisplayed();
        system.debug('theme == '+theme);
        return theme;
    }

    @AuraEnabled
    public static Boolean isValidUserCheck()
    {
        return ProfileUtils.isSalesOrGSSUser();
    }

    @AuraEnabled
    public static Boolean isSDRUserCheck()
    {
        Boolean isBuyAkamai = GSMUtilClass.getGSMSettingValue('ContactConversion_Prof_BuyAkamai').contains(UserInfo.getProfileId());
        Boolean isSDRMarOps = GSMUtilClass.getGSMSettingValue('ContactConversion_Prof_SDR_1').contains(UserInfo.getProfileId());
                //GSM_Settings__mdt sdrProfileList = [select Id, Value__c,DeveloperName from GSM_Settings__mdt where DeveloperName = 'ContactConversion_Prof_SDR_1'];

        //Boolean isSDR = ProfileUtils.isSDR() ;
        if(isBuyAkamai || isSDRMarOps)
            return true;
        else
            return false;
    }



    @AuraEnabled
    public static String insertNewLead(String ProductLine, String Notes,Id personRecordId,String LeadType) 
    {
        String returnMessage = 'Success';
        Lead convertedLead = new Lead();
        List<Lead> leadTempList = new List<Lead>();
        CampaignMember cMember = null;
        Id campaignId;
        String campaignMemberStatus = ''; //MARIT-688
        List<CampaignMember> cMemberList = new List<CampaignMember>();
        String personRecStr = personRecordId; //MARIT-787

        String selfGenleadType;
        String leadStaus = GSMUtilClass.getGSMSettingValue('ContactConversionLeadStatus');
        String leadDisposition = GSMUtilClass.getGSMSettingValue('ContactConversionLeadDisposition');
        List<GSM_Settings__mdt> profileListMDT = [select Id, Value__c,DeveloperName from GSM_Settings__mdt where DeveloperName Like 'ContactConversion_Prof_%'];
        GSM_Settings__mdt sdrProfileList = [select Id, Value__c,DeveloperName from GSM_Settings__mdt where DeveloperName = 'ContactConversion_Prof_SDR_1'];
        List<GSM_Settings__mdt> sdrCampaignList = [select Id, Value__c,DeveloperName,Status__c from GSM_Settings__mdt where DeveloperName like 'ContactConv_Campn_SDR_%'];
        String buyAkamaiProfileId = GSMUtilClass.getGSMSettingValue('ContactConversion_Prof_BuyAkamai');
        Map<String,Id> leadTypeToCampId = new Map<String,Id>();
        Map<Id,String> campaignIdToStatus = new Map<Id,String>();
        for(GSM_Settings__mdt record : sdrCampaignList)
        {
            if(record.DeveloperName.contains('Inbound_Email')){
                leadTypeToCampId.put('Inbound Email',record.Value__c);
                campaignIdToStatus.put(record.Value__c,record.Status__c);
            }
            else if(record.DeveloperName.contains('Inbound_Call')){
                leadTypeToCampId.put('Inbound Call',record.Value__c);
                campaignIdToStatus.put(record.Value__c,record.Status__c);
            }
            else if(record.DeveloperName.contains('Self_Generated')){
                leadTypeToCampId.put('SDR Self-Generated',record.Value__c);
                campaignIdToStatus.put(record.Value__c,record.Status__c);
            }         
            else if(record.DeveloperName.contains('Trial_Form')){
                leadTypeToCampId.put('Trial Form Followup',record.Value__c);
                campaignIdToStatus.put(record.Value__c,record.Status__c);
            }
        }

        GSM_Settings__mdt userSpecificMDT;
        system.debug(Logginglevel.ERROR,'personRecordId '+personRecordId);
        //User currentUser = [Select Profile.Name From User Where Id = :UserInfo.getUserId()];
        //String profileName = currentUser.Profile.Name;
        Id currentUserProfileId = UserInfo.getProfileId();

        if(sdrProfileList.value__c.contains(currentUserProfileId))
        {
            campaignId = leadTypeToCampId.get(LeadType);
            selfGenleadType = LeadType;
            campaignMemberStatus = campaignIdToStatus.get(campaignId);
        }
        else{


            for(GSM_Settings__mdt rec : profileListMDT)
            {
                if(rec.Value__c.contains(currentUserProfileId))
                    userSpecificMDT = rec;
                
                
            }
            

            for(ContactToLeadConversionCampaign__mdt  cmRec  :[Select CampaignId__c,Product_Line__c ,User_Type__c,Status__c  From ContactToLeadConversionCampaign__mdt where CampaignId__c != null])
            {
                        system.debug(Logginglevel.ERROR,'cmRec Lead '+cmRec );

                //for(GSM_Settings__mdt rec : profileListMDT)
                //{
                    system.debug(Logginglevel.ERROR,'cmRec Developer Name '+userSpecificMDT.DeveloperName +'User Type '+cmRec.User_Type__c +'Product line '+cmRec.Product_Line__c + ProductLine);
                                    system.debug(Logginglevel.ERROR,'Check 1 '+userSpecificMDT.DeveloperName.contains(cmRec.User_Type__c) + 'Check 2 ' +cmRec.Product_Line__c.equals(ProductLine) );
                    if(userSpecificMDT.DeveloperName.contains(cmRec.User_Type__c) &&  cmRec.Product_Line__c.equals(ProductLine))
                        {
                            campaignId = (Id)cmRec.CampaignId__c;
                            campaignMemberStatus = cmRec.Status__c;
                            if(cmRec.User_Type__c.contains('Sales'))
                                selfGenleadType = 'Sales Self-Generated';
                            else if(cmRec.User_Type__c.contains('GSS'))
                                selfGenleadType = 'GSS Self-Generated';
                            else if(cmRec.User_Type__c.contains('BuyAkamai'))
                                selfGenleadType = LeadType;
                        }
                    //if(profileName.contains(cmRec.User_Type__c) &&  cmRec.Product_Line__c.contains(ProductLine))

                //}
            }
        }
        //SFDC-5332
        System.debug('Campaign Details:'+campaignId+' '+campaignMemberStatus);
        if(campaignId != null)
            cMemberList = [Select CampaignId,ContactId, LeadId  From CampaignMember Where CampaignId =:campaignId AND (ContactId = :personRecordId OR LeadId= :personRecordId)];
        system.debug(Logginglevel.ERROR,'CM List '+cMemberList +'Cm Id '+campaignId);
        if(!cMemberList.isEmpty()){
            cMember = cMemberList[0];
        }
        if(personRecordId != null)
        {
            String accountId,lName,fName,country,street,state,city,postalCode,vert,subVert,company;
            String description;

            //MARIT-79 MARIT-91 Changes. Moved common fields like FirstName,LastName, Email, Phone to custom settings
            List<String> C2AfromContactOrLeadCommonFields = new List<String>();
            //System.debug(Logginglevel.ERROR,'Getting Fields');
            for(String fieldList:MarketingUtilClass.getMarketingSettingValuePartialMatch('C2ACreationFromContactOrLeadCommonField') ){
                C2AfromContactOrLeadCommonFields.addall(fieldList.replaceAll(' ','').split(','));
            }
            //System.debug(Logginglevel.ERROR,'Got Fields'+C2AfromContactOrLeadCommonFields);
            String commonFieldsList = String.join(C2AfromContactOrLeadCommonFields, ',');

            if(personRecordId.getSObjectType().getDescribe().getName() == 'Contact'){
                //MARIT-105 -- Added Account Name in order to populate Company field on converted lead.
                String contactQuery = 'Select id,'+commonFieldsList+',MailingCountry,MailingStreet,MailingState,MailingCity, MailingPostalCode ,AccountId,Account.Name,Account.OwnerId,Account.Vertical__c,Account.Sub_Vertical__c From Contact Where Id =\''+ personRecordId+'\'';
                //Contact con = [Select id,FirstName,LastName,MailingCountry,MailingState,MailingCity, MailingPostalCode ,AccountId,Account.OwnerId,Account.Vertical__c,Account.Sub_Vertical__c From Contact Where Id =: personRecordId];
                Contact con = Database.query(contactQuery);
                if (con.DoNotCall && con.HasOptedOutOfEmail){
                    return 'This person is both Email Opt Out and Do Not Call.';
                } else if(MARIT_ContactUtilClass.checkContactOpenOppt(new List<Id>{con.id}, 'Open_Opportunity_Stage_Name').contains(con.id)) { //MARIT-1513
                    //MARIT-714 - check for contact having open oppt. If present don't allow C2A creation
                    return 'New CTA cannot be created because Person has Open Opportunity';
                } else {
                    for(String field:C2AfromContactOrLeadCommonFields){
                        //MARIT-787
                        if(field == 'Lead_Qualification_Stage__c'){
                            convertedLead = LeadUtilClass.setLeadQualFieldsFromParent(con, convertedLead, LeadType);
                        } else if(field == 'Lead_Qualification_Status__c'){
                            continue;
                        }else{
                            convertedLead.put(field,con.get(field));
                        }
                    }   
                    accountId = con.AccountId;
                    lName = con.LastName;
                    //MARIT-105 Company populated with the account name incase the parent object is contact.
                    company = con.Account.Name;
                    //fName = con.FirstName;
                    country = con.MailingCountry;
                    street = con.MailingStreet;
                    state = con.MailingState;
                    city = con.MailingCity;
                    postalCode = con.MailingPostalCode;
                    description = con.Description;
                }              
            }
            else if(personRecordId.getSObjectType().getDescribe().getName() == 'Lead'){
                //MARIT-105 -- Adding Company field to the query
                String leadQuery = 'Select id,'+commonFieldsList+',Country,State,Street,City, PostalCode ,Company,Associated_Account__c,Associated_Account__r.OwnerId From Lead Where Id =\''+ personRecordId + '\'';
                //Lead personLd = [Select id,FirstName,LastName,Country,State,City, PostalCode ,Associated_Account__c,Associated_Account__r.OwnerId,Associated_Account__r.Vertical__c,Associated_Account__r.Sub_Vertical__c From Lead Where Id =: personRecordId];
                Lead personLd = Database.query(leadQuery);
                if (personLd.DoNotCall && personLd.HasOptedOutOfEmail){
                   return 'This person is both Email Opt Out and Do Not Call.';
                } else {
                    for(String field:C2AfromContactOrLeadCommonFields){
                        //MARIT-787
                        if(field == 'Lead_Qualification_Stage__c'){
                            convertedLead = LeadUtilClass.setLeadQualFieldsFromParent(personLd, convertedLead, LeadType);
                        } else if(field == 'Lead_Qualification_Status__c'){
                            continue;
                        }else{
                            convertedLead.put(field,personLd.get(field));
                        }
                    }
                    accountId = personLd.Associated_Account__c;
                    lName = personLd.LastName;
                    //MARIT-105 Company populated with the Company value in the Marketo Lead
                    company = personLd.Company;
                    //fName = personLd.FirstName;
                    country = personLd.Country;
                    street = personLd.Street;
                    state = personLd.State;
                    city = personLd.City;
                    postalCode = personLd.PostalCode;
                    description = personLd.Description;
                }              
            }
            
            convertedLead.RecordTypeId =  Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
            if(personRecordId.getSObjectType().getDescribe().getName() == 'Contact')
                convertedLead.Associated_Contact__c = personRecordId;
            else if(personRecordId.getSObjectType().getDescribe().getName() == 'Lead')
                convertedLead.Parent_lead__c = personRecordId;
            convertedLead.Status = leadStaus;
            convertedLead.Disposition__c = leadDisposition;
            convertedLead.Associated_Account__c  = accountId;
            convertedLead.Product_Line__c = ProductLine;
            //convertedLead.LeadSource = 'Other';
            //convertedLead.Parent_Contact__c = con.id;
            convertedLead.Company = company;
            //convertedLead.FirstName = fName;
            //convertedLead.LastName = lName;
            convertedLead.Country = country;
            convertedLead.Street = street;
            convertedLead.State = state;
            convertedLead.City = city;
            convertedLead.PostalCode = postalCode;
            convertedLead.adg_Self_Generated_Lead_Type__c = selfGenleadType;
             if(Notes != null){
                if(Description != null){
                    convertedLead.Description = description + ' ' + Notes;
                } else{
                    convertedLead.Description = Notes;
                }
            }else{
                convertedLead.Description = description;
            }
            if (campaignId != null) {
                convertedLead.Primary_Campaign__c = campaignId;
            }
            if(ProfileUtils.isSDR())
            {
             convertedLead.OwnerId =  UserInfo.getUserId();
             convertedLead.isC2ABySDR__c = true;
  
            }
                leadTempList.add(convertedLead);

                leadTempList = LeadToContactConversionClass.ProjectSDRForONALeads(leadTempList);


        }
        system.debug(Logginglevel.ERROR,'Converted Lead '+convertedLead);
        //AuraHandledException ex=null;
        
        try
        {
            
            if(leadTempList.size() > 0)
            {   
                insert leadTempList;
                if(!ProfileUtils.isSDR()){
                   LeadTriggerClass.runLeadReassignmentRules(leadTempList, null);
                }
                InnerContactToLeadController iConToLeadController=new InnerContactToLeadController();
                iConToLeadController.createCampaignMember(convertedLead.Id,personRecordId,campaignId,cMember,campaignMemberStatus);
                //MARIT-787 Update Parent Record with new Lead Qual Stage and Status
                iConToLeadController.updateParentRecord(convertedLead,personRecordId, personRecStr);

            }
            returnMessage = returnMessage + ':' + convertedLead.Id;
        }
        catch(DmlException e) {
            system.debug(Logginglevel.ERROR,'Error Message '+e.getMessage());

            String errorMessage = null;
            errorMessage = e.getMessage();
            Error_Log__c elc = new Error_Log__c(Name='', Class__c='GSM_Lite_ContactToLeadCreateController', Error_Message__c=e.getMessage());
            insert elc;
            //ex = new AuraHandledException(e.getMessage());
            //ex.setMessage(e.getMessage());
            return errorMessage;
        }
        catch (Exception e) {
            system.debug(Logginglevel.ERROR,'Error Message '+e.getMessage());

            String errorMessage = null;
            errorMessage = e.getMessage();
            Error_Log__c elc = new Error_Log__c(Name='', Class__c='GSM_Lite_ContactToLeadCreateController', Error_Message__c=e.getMessage());
            insert elc;
            
            return errorMessage;
        }
        return returnMessage;
    }

    

    public  without sharing class InnerContactToLeadController{
       //Create CampaignMember for the created Lead
        public  void createCampaignMember(Id leadId,Id personId,Id campaignId,CampaignMember cMember,String status) 
        {
            List<CampaignMember> cmList = new List<CampaignMember>();
            system.debug(Logginglevel.ERROR,'Create Campiagn');
            
            // MARIT-356, do not create campaign member entry for C2A record
            /*if(leadId != null)
            {
                CampaignMember cmpgnMbrLead = new CampaignMember(CampaignId = campaignId, LeadId  = leadId,Status = 'Sent');
                cmList.add(cmpgnMbrLead);
            }*/
            system.debug('CM  '+cMember + 'Contact '+personId);

            if(personId != null && cMember == null)
            {
                CampaignMember cmpgnMbrContact;
                if(personId.getSObjectType().getDescribe().getName() == 'Contact')
                    cmpgnMbrContact = new CampaignMember(CampaignId = campaignId, ContactId  = personId,Status = status);
                else if(personId.getSObjectType().getDescribe().getName() == 'Lead')
                    cmpgnMbrContact = new CampaignMember(CampaignId = campaignId, leadId  = personId,Status = status);
                cmList.add(cmpgnMbrContact);
            }

            if(cmList != null && !cmList.isEmpty()){
                insert cmList;
            }
        } 
        
        public void updateParentRecord(Lead convertedLead, Id personRecordId, String personRecStr){
            if(personRecStr.startsWithIgnoreCase('003')){
                Contact con = new Contact();
                con.id = personRecordId;
                con.Lead_Qualification_Stage__c = convertedLead.Lead_Qualification_Stage__c;
                con.Lead_Qualification_Status__c = convertedLead.Lead_Qualification_Status__c;
                //con.Do_Not_Copy_Over__c = true;
                update con;

            }else if(personRecStr.startsWithIgnoreCase('00Q')){
                Lead l1 = new Lead();
                l1.id = personRecordId;
                l1.Lead_Qualification_Stage__c = convertedLead.Lead_Qualification_Stage__c;
                l1.Lead_Qualification_Status__c = convertedLead.Lead_Qualification_Status__c;
                //l1.Do_Not_Copy_Over__c = true;
                update l1;
            }
        }
    }

}