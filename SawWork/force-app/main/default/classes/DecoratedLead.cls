/*

   Author - Anand Hegde Dec 2016
   */


public class DecoratedLead{
    public Lead lead;
    public boolean conversionSucceeded;
    public String convertedOpptyId;
    public String convertedOpptyAkamId;
    public Id oppLeaderId; 
    public Id enterpriseSalesRepId;
    public String enterpriseSalesRepEmail;
    public String opportunityFieldForSpecialist;



    public DecoratedLead(Lead tLead)
    {
        this.lead = tLead;
        this.conversionSucceeded=false;
    }


    public Opportunity buildConvertedOpportunity(Boolean isManual)
    {
        String accName =lead.Associated_Contact__r.Account.Name;
        //SFDC-4547
        String oppName = ' - Autoconvert - LEAD_PRODUCT_LINE';

        if(isManual)
            oppName = oppName.replace(' - Autoconvert', '');

        if(!String.isBlank(this.lead.Primary_Campaign__c) && !String.isBlank(this.lead.Primary_Campaign__r.Division__c))
            oppName = oppName.replace('CAMPAIGN_DIVISION', this.lead.Primary_Campaign__r.Division__c);
        else
            oppName = oppName.replace(' - CAMPAIGN_DIVISION', '');


        if(!String.isBlank(this.lead.Product_Line__c))
            oppName = oppName.replace('LEAD_PRODUCT_LINE', this.lead.Product_Line__c);
        else
            oppName = oppName.replace(' - LEAD_PRODUCT_LINE', '');

        //SFDC-4547
        if(accName != null){
            Integer endingPosition = Math.min(120 - oppName.length(), accName.length());
            oppName = accName.substring(0, endingPosition) + oppName;
        }

        Opportunity convertedOpportunity = new Opportunity();
        convertedOpportunity.Name = oppName;
        convertedOpportunity.RecordTypeId = GSMSettings.getValue('RecordTypeAkamaiOpportunity');
        convertedOpportunity.AccountId = lead.Associated_Account__r.Id;
        convertedOpportunity.Associated_Lead__c = lead.Id;
        //SFDC-2492 // SFDC-3540 @Nagaraj Desai - [Change Description to Qualification_Criteria__c]
        convertedOpportunity.Qualification_Criteria__c = getOpptyDescription(lead);//lead.Description;

        convertedOpportunity.LeadSource = lead.LeadSource;
        convertedOpportunity.CampaignId = this.lead.Primary_Campaign__c;
        convertedOpportunity.OwnerId = lead.Associated_Contact__r.Account.OwnerId;
        if(lead.Associated_Contact__r.Account.Account_Owner_Alias__c == 'ONA')
            convertedOpportunity.WAS_ONA__c = true ;

        convertedOpportunity.Validation_Override__c = true;
        convertedOpportunity.Competitor__c = lead.Competitor__c;

        //convertedOpportunity.Do_Not_Notify_MAE__c = lead.Do_Not_Notify_MAE__c; //MARIT-320

        convertedOpportunity.Competitor__c = lead.Competitor__c;
        convertedOpportunity.StageName = '1. Identify Need'; //SFDC-3539
        //SFDC-4547 MARIT-320
        //if(this.lead.Primary_Campaign__c != null)
            //convertedOpportunity.Associated_Lead_Campaign_Owner__c = this.lead.Primary_Campaign__r.OwnerId;

        // Contact. Mailing Country, Mailing State, Mailing City

        convertedOpportunity.Associated_Lead_Contact_Mailing_City__c = lead.Associated_Contact__r.MailingCity;
        convertedOpportunity.Associated_Lead_Contact_Mailing_State__c = lead.Associated_Contact__r.MailingState;
        convertedOpportunity.Associated_Lead_Contact_Mailing_Country__c = lead.Associated_Contact__r.MailingCountry;

        //SFDC-4547
        convertedOpportunity.adg_Buyer_Pain_Point__c = LeadUtilClass.getBuyerPainPoint(lead);

        //Account.Target Category, Account.DGRAT , Account. Vertical, Sub-vertical & Industry
        //convertedOpportunity.Geography__c = lead.Associated_Contact__r.Account.Parent_Division__c;

        //convertedOpportunity.Region__c = lead.Associated_Contact__r.Account.Division__c;
        //convertedOpportunity.Area__c = lead.Associated_Contact__r.Account.Region__c;
        //convertedOpportunity.Territory__c = lead.Associated_Contact__r.Account.Area__c;
        convertedOpportunity.Associated_Account_Industry__c = lead.Associated_Contact__r.Account.Industry__c;
        //SFDC-2127
        if(lead.Associated_Contact__r.Account.Target_Category__c != null && lead.Associated_Contact__r.Account.Target_Category__c != '')
            convertedOpportunity.Associated_Account_Target_Category__c = lead.Associated_Contact__r.Account.Target_Category__c;
        else
            convertedOpportunity.Associated_Account_Target_Category__c = GsmUtilClass.getGSMSettingValue('HistoricalCat_DefaultCatValue');
        //End of SFDC-2127

        convertedOpportunity.Opportunity_Leader__c = this.oppLeaderId;
        
        // SFDC 4413 - Added By Prabhanjan
        if(this.opportunityFieldForSpecialist != null && this.enterpriseSalesRepId != null)
            convertedOpportunity.put(this.opportunityFieldForSpecialist,this.enterpriseSalesRepId);

        convertedOpportunity.Associated_Lead_Type__c = lead.Lead_Type__c;
        convertedOpportunity.Associated_Lead_Score__c = lead.Akam_Lead_Score__c;


        if(lead.Partner_Involved__c!=null)
        {
            convertedOpportunity.Deal_Type__c='Indirect';
            convertedOpportunity.Partner_Involved__c=lead.Partner_Involved__c;
        }
        else
        {
            convertedOpportunity.Deal_Type__c='Direct';
        }

        //SFDC-3542
        String accountStatus = lead.Associated_Contact__r.Account.Account_Status__c;
        if(accountStatus != null) {
            if(accountStatus == 'Lead')
                convertedOpportunity.Opportunity_Type__c = 'New Logo';
            else if(accountStatus.containsIgnoreCase('active') ||
                    accountStatus.containsIgnoreCase('inactive')) 
                convertedOpportunity.Opportunity_Type__c = 'Non-Renewal: Add-On';  
            if(lead.Primary_Campaign__r.DDOS_Attack__c) { 
                convertedOpportunity.Security_Escalation__c = true;
            } else {
                convertedOpportunity.Security_Escalation__c = false;
            }
        }
        
        // End of SFDC-3542
        
        convertedOpportunity.CloseDate = Date.today().addMonths(7).toStartOfMonth().addDays(-1);
        convertedOpportunity.Business_Pain__c = lead.Business_Pain__c;
        convertedOpportunity.Project_Time_Frame__c= lead.Project_Timeframe__c;
        
        if(lead.QFA_Meeting_Date__c != null) { // SFDC-3443 @Nagaraj Desai
          convertedOpportunity.QFA_Meeting_Date__c = lead.QFA_Meeting_Date__c;
        }
        //MARIT-1276, assign lattice recommendation to opportunity from CTA during creation
        convertedOpportunity.Has_BIS__c = lead.Has_BIS__c;

        return convertedOpportunity;

    }

    //MARIT-543
    public Opportunity buildOpportunityForAsyncLead(Boolean isManual)
    {
        System.debug('In buildOpportunityForAsyncLead Class');
        String accName =lead.Associated_Account__r.Name;
        //SFDC-4547
        String oppName = ' - Autoconvert - LEAD_PRODUCT_LINE';

        if(isManual)
            oppName = oppName.replace(' - Autoconvert', '');

        if(!String.isBlank(this.lead.Primary_Campaign__c) && !String.isBlank(this.lead.Primary_Campaign__r.Division__c))
            oppName = oppName.replace('CAMPAIGN_DIVISION', this.lead.Primary_Campaign__r.Division__c);
        else
            oppName = oppName.replace(' - CAMPAIGN_DIVISION', '');


        if(!String.isBlank(this.lead.Product_Line__c))
            oppName = oppName.replace('LEAD_PRODUCT_LINE', this.lead.Product_Line__c);
        else
            oppName = oppName.replace(' - LEAD_PRODUCT_LINE', '');

        //SFDC-4547
        if(accName != null){
            Integer endingPosition = Math.min(120 - oppName.length(), accName.length());
            oppName = accName.substring(0, endingPosition) + oppName;
        }

        Opportunity convertedOpportunity = new Opportunity();
        convertedOpportunity.Name = oppName;
        convertedOpportunity.RecordTypeId = GSMSettings.getValue('RecordTypeAkamaiOpportunity');
        convertedOpportunity.AccountId = lead.Associated_Account__r.Id;
        convertedOpportunity.Associated_Lead__c = lead.Id;
        //SFDC-2492 // SFDC-3540 @Nagaraj Desai - [Change Description to Qualification_Criteria__c]
        convertedOpportunity.Qualification_Criteria__c = getOpptyDescription(lead);//lead.Description;

        convertedOpportunity.LeadSource = lead.LeadSource;
        convertedOpportunity.CampaignId = this.lead.Primary_Campaign__c;
        convertedOpportunity.OwnerId = lead.Associated_Account__r.OwnerId;
        if(lead.Associated_Account__r.Account_Owner_Alias__c == 'ONA')
            convertedOpportunity.WAS_ONA__c = true ;

        convertedOpportunity.Validation_Override__c = true;
        convertedOpportunity.Competitor__c = lead.Competitor__c;

        //convertedOpportunity.Do_Not_Notify_MAE__c = lead.Do_Not_Notify_MAE__c; //MARIT-320

        convertedOpportunity.Competitor__c = lead.Competitor__c;
        convertedOpportunity.StageName = '1. Identify Need'; //SFDC-3539
        //SFDC-4547 MARIT-320
        //if(this.lead.Primary_Campaign__c != null)
            //convertedOpportunity.Associated_Lead_Campaign_Owner__c = this.lead.Primary_Campaign__r.OwnerId;

        // Contact. Mailing Country, Mailing State, Mailing City

        convertedOpportunity.Associated_Lead_Contact_Mailing_City__c = lead.Associated_Account__r.BillingCity;
        convertedOpportunity.Associated_Lead_Contact_Mailing_State__c = lead.Associated_Account__r.BillingState;
        convertedOpportunity.Associated_Lead_Contact_Mailing_Country__c = lead.Associated_Account__r.BillingCountry;

        //SFDC-4547
        convertedOpportunity.adg_Buyer_Pain_Point__c = LeadUtilClass.getBuyerPainPoint(lead);

        //Account.Target Category, Account.DGRAT , Account. Vertical, Sub-vertical & Industry
        //convertedOpportunity.Geography__c = lead.Associated_Account__r.Parent_Division__c;

        //convertedOpportunity.Region__c = lead.Associated_Account__r.Division__c;
        //convertedOpportunity.Area__c = lead.Associated_Account__r.Region__c;
        //convertedOpportunity.Territory__c = lead.Associated_Account__r.Area__c;
        convertedOpportunity.Associated_Account_Industry__c = lead.Associated_Account__r.Industry__c;
        //SFDC-2127
        if(lead.Associated_Account__r.Target_Category__c != null && lead.Associated_Account__r.Target_Category__c != '')
            convertedOpportunity.Associated_Account_Target_Category__c = lead.Associated_Account__r.Target_Category__c;
        else
            convertedOpportunity.Associated_Account_Target_Category__c = GsmUtilClass.getGSMSettingValue('HistoricalCat_DefaultCatValue');
        //End of SFDC-2127

        convertedOpportunity.Opportunity_Leader__c = this.oppLeaderId;
        
        // SFDC 4413 - Added By Prabhanjan
        if(this.opportunityFieldForSpecialist != null && this.enterpriseSalesRepId != null)
            convertedOpportunity.put(this.opportunityFieldForSpecialist,this.enterpriseSalesRepId);

        convertedOpportunity.Associated_Lead_Type__c = lead.Lead_Type__c;
        convertedOpportunity.Associated_Lead_Score__c = lead.Akam_Lead_Score__c;


        if(lead.Partner_Involved__c!=null)
        {
            convertedOpportunity.Deal_Type__c='Indirect';
            convertedOpportunity.Partner_Involved__c=lead.Partner_Involved__c;
        }
        else
        {
            convertedOpportunity.Deal_Type__c='Direct';
        }

        //SFDC-3542
        String accountStatus = lead.Associated_Account__r.Account_Status__c;
        if(accountStatus != null) {
            if(accountStatus == 'Lead')
                convertedOpportunity.Opportunity_Type__c = 'New Logo';
            else if(accountStatus.containsIgnoreCase('active') ||
                    accountStatus.containsIgnoreCase('inactive')) 
                convertedOpportunity.Opportunity_Type__c = 'Non-Renewal: Add-On';  
            if(lead.Primary_Campaign__r.DDOS_Attack__c) { 
                convertedOpportunity.Security_Escalation__c = true;
            } else {
                convertedOpportunity.Security_Escalation__c = false;
            }
        }
        
        // End of SFDC-3542
        
        convertedOpportunity.CloseDate = Date.today().addMonths(7).toStartOfMonth().addDays(-1);
        convertedOpportunity.Business_Pain__c = lead.Business_Pain__c;
        convertedOpportunity.Project_Time_Frame__c= lead.Project_Timeframe__c;
        
        if(lead.QFA_Meeting_Date__c != null) { // SFDC-3443 @Nagaraj Desai
          convertedOpportunity.QFA_Meeting_Date__c = lead.QFA_Meeting_Date__c;
        }

        //MARIT-1276, assign lattice recommendation to opportunity from CTA during creation
        convertedOpportunity.Has_BIS__c = lead.Has_BIS__c;
        System.debug('Mayank, convertedOpportunity: '+convertedOpportunity);
        return convertedOpportunity;

    }

         //SFDC-2492
    public String getOpptyDescription(Lead lead){
        String descript = lead.description!= null ? lead.description:'';
        String auth = lead.Authority__c!=null?lead.Authority__c:'';
        String need = lead.Need__c!=null?lead.Need__c:'';
        String urgency = lead.Urgency__c!=null?lead.Urgency__c:'';
        String money = lead.Money__c!=null?lead.Money__c:'';
        String anumDesc = lead.ANUM_Description__c!=null?lead.ANUM_Description__c:' ';
         
        String description = 'Authority:\n'+auth+'\n\nNeed:\n'+need+'\n\nUrgency:\n'+urgency+'\n\nMoney:\n'+money+'\n-----------------\nANUM Description:\n'+anumDesc+'\n-----------------\nLead Description:\n'+descript;
        //As we have 7 new lines, we can just have 31993 characters?
        if(description.length()>32000){
            description = description.substring(0, 31935);
            description+='... (Please see Lead for complete Description field)';
        }

        system.debug(LoggingLevel.ERROR,'description:::: '+description);
        return description;
    }

    public String getAutoConversionReason () {
        String autoConvertReason = '';
        if (lead.Primary_Campaign__c != null && lead.Primary_Campaign__r.Auto_Convert_Lead__c) {
             autoConvertReason = 'Campaign Auto Convert flag';
        }
        if (lead.Convert_to_Opportunity__c) {
             autoConvertReason = 'Lead Auto Convert flag';
        }
        if (lead.Auto_Convert_Source__c=='Lead Auto Convert rule') {
             autoConvertReason  = 'Lead Auto Convert rule';
        }
        return autoConvertReason;
    }


    public Lead getConvertedLead()
    {   //SFDC-4547
        return new Lead(Id=lead.Id, Validation_Override__c=true, Status='Converted', Disposition__c='Sent to MAE', RecordTypeId=GSMSettings.getValue('ConvertedLeadRecordTypeId'), Associated_Opportunity__c=this.convertedOpptyId, Converted_Date__c=Date.today(), Converted_By__c=UserInfo.getUserId(),Auto_Convert_Source__c = this.getAutoConversionReason(),Reasons_of_Conversion_Fail__c=null);
    }

    public Contact getContactWithPopulatedAssociatedOppty()
    {   
        if(!String.isBlank(this.convertedOpptyId))
            return new Contact(Id=lead.Associated_Contact__c, Associated_Opportunity__c=this.convertedOpptyId);
        else
            return null;
    }

    public OpportunityContactRole generateOpportunityContactRole()
    {
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.Role = 'Lead';
        ocr.opportunityId = this.convertedOpptyId;
        ocr.contactId = this.lead.Associated_Contact__c;
        return ocr;
    }

    public void updateConvertedOpportunityInfo(Opportunity opp)
    {
        this.convertedOpptyId = opp.Id;
        this.convertedOpptyAkamId = opp.AKAM_Opportunity_ID__c;
        this.conversionSucceeded=true;
    }

     public void setOppLeader(Id oppLeaderId)
    {
        this.oppLeaderId = oppLeaderId;
    }

      public void setEnterpriseSalesRep(Id enterpriseSalesRepId)
    {
        this.enterpriseSalesRepId = enterpriseSalesRepId;
    }

    // SFDC 3933 - Added By Prabhanjan

    public void setEnterpriseSalesRepEmail(String enterpriseSalesRepEmail)
    {
        this.enterpriseSalesRepEmail = enterpriseSalesRepEmail;
    }

    public void generateOpptyLeaderMailingList(List<Messaging.SingleEmailMessage> mailingList)
    {
            if(this.enterpriseSalesRepEmail != null)
            {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(GSMSettings.getValue('LeadConversion_ESR_TemplateId'));
                mail.setSaveAsActivity(false);
                mail.setTargetObjectId(this.oppLeaderId);
                mail.setTreatTargetObjectAsRecipient(false);
                mail.setToAddresses(new List<String>{this.enterpriseSalesRepEmail});
                mail.setWhatId(this.convertedOpptyId);
                mailingList.add(mail);
            }
    }

    // SFDC 4413 - Added By Prabhanjan

    public void setOpportunityFieldForSpecialist(String fieldName){
        this.opportunityFieldForSpecialist = fieldName;
    }

}