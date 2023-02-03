/*
 SFDC-1368 - Auto-Convert Leads- Opportunity
 Author - Hitesh Chawda
 Description - Covert Contact Button at Contact call this class to convert contact to a Lead and assoicates a Campaign Member for the selected Campaign as Lead

 SFDC-1912
 Author - Saket More
 Description - Adding new Lead Creation Functionality
*/


public class ConvertContactToLeadPageController {
    public ConvertContactToLeadPageController(){}
   
    
    /*public String campaignOption{get;set;}
    public String description{get;set;}
    public Boolean section1 {get; set;}
    //public Contact contact {get; set;}
    public Contact contactRecord{get; set;}
    private Id campaignId;
    private String selectOptionCall,selectOptionChat;
    public String selectProductLine{get; set;}
    //private Map<String, ContactToLeadConversionCampaign__mdt> contactConversionMetadataRecords;
    //private ContactToLeadConversionCampaign__mdt selectedMetadataRecord;
    private CampaignMember cMember = null ; 


        
public ConvertContactToLeadPageController(){
           
    section1 = false;
    

}
    
  public ConvertContactToLeadPageController(ApexPages.StandardController controller){
      
      this.contactRecord=(Contact)controller.getRecord();
      //contact = new Contact();
        
   }
    //Select options for Campaign Selection to add the Lead as Campaign member
    public List<SelectOption> getCampaignOptions() {

         
        contactConversionMetadataRecords = GSMUtilClass.getContactConversionMetadataRecords();
         //selectOptionChat = GSMUtilClass.getGSMSettingValue('ContactConversionCampaignInboundChat');
        system.debug('Campaign Details '+contactConversionMetadataRecords);

        List<SelectOption> options = new List<SelectOption>();
        for(String key:contactConversionMetadataRecords.keySet())
        {
            options.add(new SelectOption(contactConversionMetadataRecords.get(key).Campaign_Name__c,contactConversionMetadataRecords.get(key).Campaign_Name__c));
        }
        
        return options;
    }
    
    public String getCampaignOption() {
        return campaignOption;
    }
    public void setCampaignOption(String campaignOption) { 
        this.campaignOption = campaignOption; 
    }
    
    //Select Options for Product Line for the Lead
    public List<SelectOption> getProductLineOptions() {

        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Lead.Product_Line__c .getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        return options;
    }
    
    public String getProductLineOption() {
        return selectProductLine;
    }
    
    public void setProductLineOption(String selectProductLine) { 
        this.selectProductLine = selectProductLine; 
    }
    
    //Fetching Campaign Records to assoicate Campaign Member to respective selected Campaign
    public void getCampaign()
    {
        system.debug('Inside get Campaign');
        if(campaignOption.equals('Self-Generated')){
            section1 = true;
        }
        else{
            section1=false;
        }
        System.debug('section1:::'+section1);
        //System.debug('value::'+contactRecord.staccatoess001__Campaign__c);
        for(String key: contactConversionMetadataRecords.keySet())
        {
           system.debug('Inside get Campaign inside for'+campaignOption);

            if(contactConversionMetadataRecords.get(key).Campaign_Name__c == campaignOption)
            {
                system.debug('Inside get Campaign inside If '+key +' '+contactConversionMetadataRecords.get(key));
                campaignId = contactConversionMetadataRecords.get(key).CampaignId__c;
                selectedMetadataRecord = contactConversionMetadataRecords.get(key); 
            }
            
        }
            
        
            
    }
    
    //Create Lead 
    public pageReference convertContact()
    {
        //throw new CustomException('qwerty'+contactRecord.Campaign_Lookup__c);
        if(contactRecord.Campaign_Lookup__c != null){
            campaignId = contactRecord.Campaign_Lookup__c;
        }

        if(campaignOption == null || selectProductLine == null )
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select a Type and Product Line to proceed.'));
            return null;
        }  
        else
        {

            String leadStaus = GSMUtilClass.getGSMSettingValue('ContactConversionLeadStatus');
            String leadDisposition = GSMUtilClass.getGSMSettingValue('ContactConversionLeadDisposition');
            system.debug('CM Id '+campaignId +' Con Id '+contactRecord.Id);

            List<CampaignMember> cMemberList = [Select CampaignId,ContactId From CampaignMember Where CampaignId = :campaignId AND ContactId = :contactRecord.Id];
            system.debug('CM List '+cMemberList);
            if(!cMemberList.isEmpty()){
                cMember = cMemberList[0];
            }
                

            Contact con = [Select FirstName,LastName,MailingCountry,MailingState,MailingCity, MailingPostalCode ,AccountId,Account.OwnerId,Account.Vertical__c,Account.Sub_Vertical__c From Contact Where Id =: contactRecord.Id];
            Lead convertedLead = new Lead();
            system.debug(' Inside convert lead ');
            PageReference pageRef ;
            convertedLead.RecordTypeId =  Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Account Development - Inbound').getRecordTypeId();
            convertedLead.Associated_Contact__c = contactRecord.Id;
            convertedLead.Status = leadStaus;
            convertedLead.Disposition__c = leadDisposition;
            convertedLead.Associated_Account__c  = con.AccountId;
            convertedLead.Product_Line__c = selectProductLine;
            convertedLead.LeadSource = selectedMetadataRecord.Lead_Source__c;
            convertedLead.FirstName = con.FirstName;
            convertedLead.LastName = con.LastName;
            convertedLead.Country = con.MailingCountry;
            convertedLead.State = con.MailingState;
            convertedLead.City = con.MailingCity;
            convertedLead.PostalCode = con.MailingPostalCode;
            convertedLead.Akamai_Vertical__c  = con.Account.Vertical__c;
            convertedLead.Sub_Vertical__c = con.Account.Sub_Vertical__c;
            convertedLead.Description = description;
            
                    
            try{
              
                insert convertedLead;
                system.debug(' Inside insert convert lead '+convertedLead);
    
                if(convertedLead != null)
                {
                    system.debug(' Inside Campaign Member ');
                    Database.DMLOptions dmo = new Database.DMLOptions();
                    dmo.assignmentRuleHeader.useDefaultRule= true;
                    convertedLead.Validation_Override__c = true;
                    convertedLead.setOptions(dmo);
                    
                    update convertedLead;
                    createCampaignMember(convertedLead.Id,contactRecord.Id);
                    pageRef = new PageReference('/' + convertedLead.Id );        
                }
                
               return pageRef;
            }
            
            catch(DmlException e) {
    
                System.debug('DmlException caught: ' + e.getMessage());
                Error_log__c errorLog = new Error_log__c();
                             errorLog.Class__c = 'ConvertContactToLeadPageController';
                             errorLog.Error_Message__c = e.getMessage();
                             errorLog.RecordId__c = contactRecord.Id;
                insert errorLog;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
                }
            catch(Exception e) {
    
                System.debug('Exception caught: ' + e.getMessage());
                Error_log__c errorLog = new Error_log__c();
                             errorLog.Class__c = 'ConvertContactToLeadPageController';
                             errorLog.Error_Message__c = e.getMessage();
                             errorLog.RecordId__c = contactRecord.Id;
                insert errorLog;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
        }
    }
    
    //Create CampaignMember for the created Lead
    public void createCampaignMember(Id leadId,Id contactId) 
    {
        List<CampaignMember> cmList = new List<CampaignMember>();
        system.debug('Create Campiagn');
        if(leadId != null)
        {
            CampaignMember cmpgnMbrLead = new CampaignMember(CampaignId = campaignId, LeadId  = leadId,Status = 'Sent');
            cmList.add(cmpgnMbrLead);
        }
        system.debug('CM  '+cMember + 'Contact '+contactId);

        if(contactId != null && cMember == null)
        {
            CampaignMember cmpgnMbrContact = new CampaignMember(CampaignId = campaignId, ContactId  = contactId,Status = 'Sent');
            cmList.add(cmpgnMbrContact);
        }
        
        if(cmList.size() > 0)
        insert  cmList   ;
    }
        */

}