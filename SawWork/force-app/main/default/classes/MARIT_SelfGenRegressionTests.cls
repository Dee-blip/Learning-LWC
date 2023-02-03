@isTest(seeAllData = false)
public class MARIT_SelfGenRegressionTests {
    public static Integer totalLeads = 6;
    public static User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
    public static User MARKETOINTEGRATION = [select id from user where profile.name='Marketo Integration' and isactive=true limit 1];
    
    @testSetup static void setup() {
        MarketingIT_Custom_Settings__c settings = new MarketingIT_Custom_Settings__c();
        settings.Name = 'LeadAsyncConversionFlagStatus';
        settings.Flag_Status__c = false;
        insert settings;
        Lead liveChatLead;
        List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
                    .eagerPopulate()
                    .put(Account.Vertical__c, 'Gaming')
                    .put(Account.Sub_Vertical__c, 'Gaming')
                    .put(Account.Type, 'Lead')
                    .count(1)
                    .create()
                    .getRecords();
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        List<Lead> mLeads = new List<Lead>();
        for(Integer i = 1; i <= totalLeads; i++){
            Lead l = new Lead();
            l.RecordTypeId = marketoRecordTypeId;
            l.Email = 'testLead'+String.valueOf(i)+'@akamai.com';
            l.Associated_Account__c = listOfTestAccounts[0].id;
            l.Status = 'New';
            l.Company = 'Test SFDC';
            l.FirstName = 'Self';
            l.LastName = 'Gen '+String.valueOf(i);
            l.Country = 'India';
            l.State = 'Karnataka';
            if(l.LastName == 'Gen 2'){
                l.Lead_Qualification_Stage__c = 'Prospect';
            }
            else if(l.LastName == 'Gen 3'){
                l.Lead_Qualification_Stage__c = 'Closed Won';
            }
            else if(l.LastName == 'Gen 6'){
                l.Lead_Qualification_Stage__c = 'Qualified Lead - Hot'; 
            }
            else if(l.LastName == 'Gen 5'){
                liveChatLead = l;
            }
            mleads.add(l);            
        }
        
        System.runAs(MARKETOINTEGRATION){
            insert mLeads;
        }
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorId = lcv.id;
        lct.leadId = liveChatLead.Id;
        insert lct;
        
        Lead leadToUpdate = (Lead)Database.query('Select Id,name,Lead_Qualification_Status__c from Lead where lead_record_type__c = \'Akamai Lead\' and name = \'Self Gen 6\'');
        leadToUpdate.Lead_Qualification_Status__c = 'Closed Not Valid Person';
        update leadToUpdate;

    }
    
    @isTest static void testSelfGenCreation(){
        //SDR Self-Generated //Media //Inbound Email
        Test.startTest();
        System.runAs(MARIT_SelfGenRegressionTests.SDR){
            List<Lead> leads = (List<Lead>)Database.query('Select Id,name,email,Lead_Qualification_Stage__c,Lead_Qualification_Status__c,Product_Line__c,adg_Self_Generated_Lead_Type__c from Lead where lead_record_type__c = \'Marketo Lead\' LIMIT '+String.valueOf(totalLeads));
            LiveChatTranscript lct = [Select Id,leadId from LiveChatTranscript LIMIT 1];
            String resp;
            //Test - prospect value set
            for(Integer i = 0; i < totalLeads; i++){
                Lead l = leads.get(i);
                if(l.name == 'Self Gen 1'){
                    resp = GSM_Lite_ContactToLeadCreateController.insertNewLead('Media','Test',l.Id,'SDR Self-Generated');
                }
                else if(l.name == 'Self Gen 2'){
                    resp = GSM_Lite_ContactToLeadCreateController.insertNewLead('Media','Test',l.Id,'SDR Self-Generated');
                }
                else if(l.name == 'Self Gen 3'){
                    resp = GSM_Lite_ContactToLeadCreateController.insertNewLead('Media','Test',l.Id,'SDR Self-Generated');
                }
                else if(l.name == 'Self Gen 4'){
                    resp = GSM_Lite_ContactToLeadCreateController.insertNewLead('Media','Test',l.Id,'Inbound Email');
                }
                else if(l.name == 'Self Gen 5'){
                    resp = GSM_Controller_LA_LeadFromContact.createLeadFromContact(lct.Id);
                }
                else if(l.name == 'Self Gen 6'){
                    //when c2a is not in 'new/in progress'
                    resp = GSM_Lite_ContactToLeadCreateController.insertNewLead('Media','Test',l.Id,'SDR Self-Generated');
                }
                System.debug(logginglevel.DEBUG,'Name::'+l.name+' '+resp);
            }
            leads = (List<Lead>)Database.query('Select Id,Parent_Lead__c,Parent_Lead__r.Lead_Qualification_Stage__c,Parent_Lead__r.Lead_Qualification_Status__c,name,email,Lead_Qualification_Stage__c,Lead_Qualification_Status__c,Product_Line__c,adg_Self_Generated_Lead_Type__c,ANUM_Description__c,Authority__c,Need__c,Urgency__c,Money__c,QFA_Meeting_Date__c from Lead where lead_record_type__c = \'Akamai Lead\' LIMIT '+String.valueOf(totalLeads));
            Map<Id,String> cmStatusMap = new Map<Id,String>();
            for(CampaignMember cm : [Select id,leadId,status from CampaignMember LIMIT :totalLeads]){
                cmStatusMap.put(cm.leadId,cm.status);
            }
            for(Integer i = 0; i < totalLeads; i++){
                Lead l = leads.get(i);
                if(l.name == 'Self Gen 1'){
                    System.assert(l.Lead_Qualification_Stage__c == 'Prospect', 'Lead stage not set to Prospect. Lead:'+l.name+' '+l.Lead_Qualification_Stage__c);
                    System.assert(l.Lead_Qualification_Status__c == 'New', 'Lead status not set to New. Lead:'+l.name+' '+l.Lead_Qualification_Status__c);
                }
                else if(l.name == 'Self Gen 3' || l.name == 'Self Gen 6'){
                    System.assert(l.Lead_Qualification_Stage__c == 'Turnback', 'Lead stage not set to Turnback. Lead:'+l.name+' '+l.Lead_Qualification_Stage__c);
                    System.assert(l.Lead_Qualification_Status__c == 'Turnback Future Opportunity', 'Lead status not set to Turnback Future Opportunity.Lead:'+l.name+' '+l.Lead_Qualification_Status__c);
                }
                else if(l.name == 'Self Gen 4' || l.name == 'Self Gen 5'){
                    System.assert(l.Lead_Qualification_Stage__c == 'Qualified Lead - Hot', 'Lead stage not set to Qualified Lead - Hot. Lead:'+l.name+' '+l.Lead_Qualification_Stage__c);
                    System.assert(l.Lead_Qualification_Status__c == 'New', 'Lead status not set to New. Lead:'+l.name+' '+l.Lead_Qualification_Status__c);
                }
                System.assert(l.Parent_Lead__r.Lead_Qualification_Stage__c == l.Lead_Qualification_Stage__c, 'Stage value not copied to parent lead. Lead:'+l.name+' '+l.Parent_Lead__r.Lead_Qualification_Stage__c+' '+l.Lead_Qualification_Stage__c);
                System.assert(l.Parent_Lead__r.Lead_Qualification_Status__c == l.Lead_Qualification_Status__c, 'Status value not copied to parent lead. Lead:'+l.name+' '+l.Parent_Lead__r.Lead_Qualification_Status__c+' '+l.Lead_Qualification_Status__c);
                System.assert(cmStatusMap.get(l.Parent_Lead__c) == 'Follow-Up Requested', 'Campaign Member status not set to Follow-Up Requested. Lead:'+l.name+' '+cmStatusMap.get(l.Parent_Lead__c));
                resp = GSM_CallToAction_CreateLeadController.callToActionLeadExists(l.Parent_Lead__c,false);
                System.assert(resp.split(':').get(0) != '0', 'C2A getting created when open C2A exits'+l.name);
            } 
        }
        Test.stopTest();
    }

    @isTest static void testSelfGenConversionValidation(){
        Test.startTest();
        System.runAs(MARIT_SelfGenRegressionTests.SDR){
            List<Lead> leads = (List<Lead>)Database.query('Select Id,name,email,Lead_Qualification_Stage__c,Lead_Qualification_Status__c,Product_Line__c,adg_Self_Generated_Lead_Type__c from Lead LIMIT '+String.valueOf(totalLeads));
            Lead l = leads.get(0);
            Id parentId = l.Id;
            String resp = GSM_Lite_ContactToLeadCreateController.insertNewLead('Media','Test',l.Id,'SDR Self-Generated');
            System.debug(logginglevel.DEBUG,'Resp='+resp);
            l = (Lead)Database.query('Select Id,Parent_Lead__c,Parent_Lead__r.Lead_Qualification_Stage__c,Parent_Lead__r.Lead_Qualification_Status__c,name,email,Lead_Qualification_Stage__c,Lead_Qualification_Status__c,Product_Line__c,adg_Self_Generated_Lead_Type__c,ANUM_Description__c,Authority__c,Need__c,Urgency__c,Money__c,QFA_Meeting_Date__c from lead where parent_lead__c = \''+l.Id+'\'');
            l.Lead_Qualification_Status__c = 'Converted';
            try{
                l.Product_Line__c = 'Media';
                update l;
            }
            catch(Exception ex){
                System.assert(ex.getMessage().contains('ANUM'), 'ANUM Validation not shown.Lead='+l.name);
            }
            try{
                l.Product_Line__c = null;
                l.ANUM_Description__c = 'NA';
                l.Authority__c = 'NA';
                l.Need__c = 'NA';
                l.Urgency__c = 'NA';
                l.Money__c = 'NA';
                l.QFA_Meeting_Date__c = date.today();
                update l; 
            }
            catch(Exception ex){
                System.assert(ex.getMessage().contains('Product line'), 'Product Line Validation not shown.Lead='+l.name);
            }
            
            leads = (List<Lead>)Database.query('Select Id,name,Associated_Opportunity__c,Associated_Contact__c,Status from lead where parent_lead__c = \''+parentId+'\'');
            l = leads.get(0);
            System.debug(logginglevel.DEBUG,'Oppt ID:'+l.Associated_Opportunity__c);
            System.debug(logginglevel.DEBUG,'Contact ID:'+l.Associated_Contact__c);
            System.assert(l.Associated_Opportunity__c == null, 'Opportunity was created.Lead='+l.name+' '+l.Associated_Opportunity__c);
            System.assert(l.Associated_Contact__c == null, 'Contact was created.Lead='+l.name+' '+l.Associated_Contact__c);
            System.assert(l.Status != 'Converted', 'C2A status changed to converted.Lead='+l.name+' '+l.Status);
        }
        Test.stopTest();         
    }
    @isTest static void testSelfGenConversion(){
        Test.startTest();
        System.runAs(MARIT_SelfGenRegressionTests.SDR){
            List<Lead> leads = (List<Lead>)Database.query('Select Id,name,email,Lead_Qualification_Stage__c,Lead_Qualification_Status__c,Product_Line__c,adg_Self_Generated_Lead_Type__c from Lead LIMIT '+String.valueOf(totalLeads));
            Lead l = leads.get(0);
            Id parentId = l.Id;
            String resp = GSM_Lite_ContactToLeadCreateController.insertNewLead('Media','Test',l.Id,'SDR Self-Generated');
            System.debug(logginglevel.DEBUG,'Resp='+resp);
            l = (Lead)Database.query('Select Id,Parent_Lead__c,Parent_Lead__r.Lead_Qualification_Stage__c,Parent_Lead__r.Lead_Qualification_Status__c,name,email,Lead_Qualification_Stage__c,Lead_Qualification_Status__c,Product_Line__c,adg_Self_Generated_Lead_Type__c,ANUM_Description__c,Authority__c,Need__c,Urgency__c,Money__c,QFA_Meeting_Date__c from lead where parent_lead__c = \''+l.Id+'\'');
            l.Product_Line__c = 'Media';
            l.ANUM_Description__c = 'NA';
            l.Authority__c = 'NA';
            l.Need__c = 'NA';
            l.Urgency__c = 'NA';
            l.Money__c = 'NA';
            l.QFA_Meeting_Date__c = date.today();
            l.Lead_Qualification_Status__c = 'Converted';
            update l;
            leads = (List<Lead>)Database.query('Select Id,name,Associated_Opportunity__c,Associated_Contact__c,Status from lead where parent_lead__c = \''+parentId+'\'');
            l = leads.get(0);
            System.debug(logginglevel.DEBUG,'Oppt ID:'+l.Associated_Opportunity__c);
            System.debug(logginglevel.DEBUG,'Contact ID:'+l.Associated_Contact__c);
            System.assert(l.Associated_Opportunity__c != null, 'Opportunity was not created.Lead='+l.name+' '+l.Associated_Opportunity__c);
            System.assert(l.Associated_Contact__c != null, 'Contact was not created.Lead='+l.name+' '+l.Associated_Contact__c);
            System.assert(l.Status == 'Converted', 'C2A status not changed to converted.Lead='+l.name+' '+l.Status);
            resp = GSM_Lite_ContactToLeadCreateController.insertNewLead('Media','Test',l.Associated_Contact__c,'SDR Self-Generated');
            System.assert(resp.contains('Open Opportunity'),'Creating C2A when contact has Open Oppt.Lead='+l.name);
        }
        Test.stopTest();         
    }
}