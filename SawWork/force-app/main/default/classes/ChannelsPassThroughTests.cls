/*
   Provides coverage to

 */

@isTest(seeAllData = false)
private class ChannelsPassThroughTests
{

    @testSetUp static void insertCustomSettingsAndCreateData()
        {
            System.runAs(utilTestClass.getTestRunUser())
                {
                    new SobjectBuilder(Environment_Setup__c.sObjectType)
                            .put(Environment_Setup__c.Environment_Type__c, 'Primary')
                            .put(Environment_Setup__c.Active_Org__c, true)
                            .put(Environment_Setup__c.Akam_Id_Start_String__c, 'F-')
                            .create();
                     Account acc=new account();
                                      acc.type='Lead';
                                      acc.website='www.locate.com';
                                      acc.name='LocateName';
                                      acc.Vertical__c = 'Unknown';
                                      acc.Sub_Vertical__c = 'Unknown';
                                      acc.Anaplan_Sub_Territory__c = 'Anaplan-Sub';
                                      acc.BillingCountry = 'India';
                                        acc.BillingState = 'DELHI';
                                        acc.Override_Visual_Compliance__c = True;
                                      insert acc;

                    Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', acc.ownerId, 'Worldwide');
                    rule.SubTerritory__c = 'Anaplan-Sub';
                    rule.Associated_User_RSM__c = acc.ownerId;
                    insert rule;

                    List<User> partnerUsers = SObjectFactory.createPartnerUsers(1);
                    Account partAccount = SobjectRepository.getPartnerAccount();
                    partAccount.Partner_Type__c='Associate Partner';
                    update partAccount;
                    Channel_Mapping__c channelMapping = SObjectFactory.createChannelMapping(partAccount.Id);
                    Opportunity oppty = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                            .eagerPopulate()
                            .put(Opportunity.AccountId, acc.Id)
                            .put(Opportunity.Deal_Type__c, 'Indirect')
                            .put(Opportunity.Partner_Involved__c, partAccount.Id)
                            .put(Opportunity.Channel_Manager__c, channelMapping.Id)
                            .put(Opportunity.Validation_Override__c,true)
                            .create()
                            .getRecord();

                    // add a carrier product
                    Product2 p1 = (Product2)new SobjectBuilder(Product2.sObjectType)
                            .put(Product2.Name, 'CarrierProduct1')
                            .put(Product2.Family, 'Carrier')
                            .put(Product2.IsActive, true)
                            .create()
                            .getRecord();

                    
                    PricebookEntry pbEntry= (PriceBookEntry)new SObjectBuilder(PriceBookEntry.sObjectType)
                            .put(PriceBookEntry.Pricebook2Id, Test.getStandardPricebookId())
                            .put(PriceBookEntry.Product2Id, p1.Id)
                            .put(PriceBookEntry.CurrencyIsoCode, 'USD')
                            .put(PriceBookEntry.IsActive, true)
                            .put(PriceBookEntry.UnitPrice, 1)
                            .create()
                            .getRecord();
                            
                    Test.startTest();
                    List<PriceBookEntry> pbEntries = [select id from PriceBookEntry limit 1];
                    new SobjectBuilder(OpportunityLineItem.sObjectType)
                            .eagerPopulate()
                            .put(OpportunityLineItem.PriceBookEntryId, pbEntry.id)
                            .put(OpportunityLineItem.OpportunityId, oppty.Id)
                            .create();

                    SobjectFactory.insertOpptyTeamMemberForPartner(partnerUsers, oppty.id);

                    Order_Approval__c oa = (Order_Approval__c)new SobjectBuilder(Order_Approval__c.sObjectType)
                            .eagerPopulate()
                            .put(Order_Approval__c.Associated_Opportunity__c, oppty.Id)
                            .create()
                            .getRecord();


                    Secret_Key__c sk1 = new Secret_Key__c(Name='DSignWebhookKeys1', Secret_Key__c='MIIEazCCA1OgAwIBAgIOAXwnqVCTAAAAAF');
                    Secret_Key__c sk2 = new Secret_Key__c(Name='DSignRequestIntegratorKey', Secret_Key__c='MIIEazCCA1OgAwIBAgIOAXwnqVCTAAAAAF');
                    Secret_Key__c sk3 = new Secret_Key__c(Name='DSignPvtKey1', Secret_Key__c='MIIEazCCA1OgAwIBAgIOAXwnqVCTAAAAAF');
                    List<Secret_Key__c> sks = new List<Secret_Key__c>();
                    sks.add(sk1);
                    sks.add(sk2);
                    sks.add(sk3);
                    insert sks;

                    ContentVersion cvv = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');
                    insert cvv;

                    ContentVersion cvv2 = [SELECT Id, ContentDocumentId,VersionData, PathOnClient FROM ContentVersion WHERE Id = :cvv.Id];
                    ContentDocumentLink att2 = L2Q_ContentDocumentUtilClass.setContentDocumentLink(cvv2.ContentDocumentId, oa.Id, 'I', 'AllUsers');
                    insert att2;

                    Partner_Order_Acceptance_Document__c poad = new Partner_Order_Acceptance_Document__c();
                    poad.opportunity__c = oppty.Id;
                    poad.Validation_Override__c = true;
                    poad.Attachment__c = cvv2.Id;
                    poad.Order_Acceptance_Status__c = 'Pending Acceptance';
        
        
                    insert poad;
        
                    Test.stopTest();
                }
        }


    static testMethod void testEnvelopeCreation()
    {
        User partner = SobjectRepository.getPartnerUser();
      
            Order_Approval__c oa = SobjectRepository.getOrderApproval();
            Opportunity oppty = SobjectRepository.getOpportunity();
            Partner_Order_Acceptance_Document__c poad = [select id from Partner_Order_Acceptance_Document__c limit 1];
            Test.startTest();
            
            Test.setMock(HttpCalloutMock.class, new CalloutMock(new List<String>{
                'L2Q_DocusignAccessToken'
                ,'L2Q_DocusignCreateEnvelope'
                }));

            ContentVersion cvv2 = [select id from ContentVersion where islatest=true limit 1];
            System.assert(cvv2.Id!=null, 'No content versions found');
            ContentVersion requiredDocument = [SELECT Id  FROM ContentVersion WHERE Id = :cvv2.Id LIMIT 1];
            L2Q_DocusignForPartnerPassThrough.createRestEnvelop('Anand', 'anandghegde@gmail.com', poad.Id, cvv2.Id);

            L2Q_DocusignForPartnerPassThrough lpp = new L2Q_DocusignForPartnerPassThrough();
            //L2Q_DocusignForPartnerPassThrough.initCon(oa.Id);
            L2Q_DocusignForPartnerPassThrough.updateTags(cvv2.Id, poad.Id);


            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.addHeader('X-DocuSign-Signature-1', 'njfdah');
            req.requestURI = 'https://qa-myakamai.cs125.force.com/partners/services/apexrest/L2Q_DocuSignStatusListener';  
            req.httpMethod = 'POST';

            List<API_Responses__mdt> resp = [select Response_Body__c from API_Responses__mdt where DeveloperName=:'L2Q_DocusignStatusListenerCompleted'];
            req.requestBody = Blob.valueof(resp[0].Response_Body__c);
            RestContext.request = req;
            RestContext.response = res;
            L2Q_DocuSignStatusListener.handleDocusignStatus();


            Test.stopTest();


    }

    static testMethod void verifyPassthroughDocsAreMandatoryForPassthroughPartners()
    {
        User partner = SobjectRepository.getPartnerUser();
            Order_Approval__c oa = SobjectRepository.getOrderApproval();
            Opportunity oppty = SobjectRepository.getOpportunity();
            Partner_Order_Acceptance_Document__c poad = [select id from Partner_Order_Acceptance_Document__c limit 1];
            Test.startTest();

            Contact partnerContact = SobjectRepository.getPartnerContact();
            System.assert(partnerContact.Partner_User__c!=null, 'Partner User lookup not populated:'+partnerContact);
           // TestUtils.attachFile(oa.Id);

            PageReference pageRef1 = Page.CFA_SendEmail;
            Test.setCurrentPageReference(pageRef1);
            pageRef1.getParameters().put('id', oa.id);
            ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');
            insert conVer;

            ContentVersion conVer2 = [SELECT Id, ContentDocumentId,VersionData, PathOnClient FROM ContentVersion WHERE Id = :conVer.Id];
            ContentDocumentLink att3 = L2Q_ContentDocumentUtilClass.setContentDocumentLink(conVer2.ContentDocumentId, oa.Id, 'I', 'AllUsers');
            insert att3;
            

            CFA_SendEmailController fruc1 = new CFA_SendEmailController();
            
            TestUtils.verifyPageMessageDisplayed('please upload');

        

            L2Q_DocusignForPartnerPassThrough lpp = new L2Q_DocusignForPartnerPassThrough();
            //L2Q_DocusignForPartnerPassThrough.initCon(oa.Id);
            L2Q_DocusignForPartnerPassThrough.initCon(poad.Id);
            L2Q_DocusignForPartnerPassThrough.updateTags(conVer2.Id, oa.Id);


            PageReference pageRef = Page.CFA_SendEmail;
                            Test.setCurrentPageReference(pageRef);
                            pageRef.getParameters().put('id', oa.Id);
                            CFA_SendEmailController fruc = new CFA_SendEmailController();
                            fruc.preview();

                            fruc.PartnerEmail = 'fdjakld@akamaipartner.com';
                            fruc.preview();
                            fruc.SendEmail();
            

            Test.stopTest();


    }

    static testMethod void verifyDocumentRejectedScenario()
    {
        User partner = SobjectRepository.getPartnerUser();
        ContentDocumentLink att;
       
            L2Q_DocusignForPartnerPassThrough.isCommunity();

            Order_Approval__c oa = SobjectRepository.getOrderApproval();
            Opportunity oppty = SobjectRepository.getOpportunity();
            Partner_Order_Acceptance_Document__c poad = [select id from Partner_Order_Acceptance_Document__c limit 1];
            Test.startTest();
           
            Test.setMock(HttpCalloutMock.class, new CalloutMock(new List<String>{
                'L2Q_DocusignAccessToken'
                ,'L2Q_DocusignCreateEnvelope'
                }));

            ContentVersion cvv2 = [select id from ContentVersion where islatest=true limit 1];
            System.assert(cvv2.Id!=null, 'No content versions found');
            ContentVersion requiredDocument = [SELECT Id  FROM ContentVersion WHERE Id = :cvv2.Id LIMIT 1];
            L2Q_DocusignForPartnerPassThrough.createRestEnvelop('Anand', 'anandghegde@gmail.com', poad.Id, cvv2.Id);

            L2Q_DocusignForPartnerPassThrough lpp = new L2Q_DocusignForPartnerPassThrough();
            //L2Q_DocusignForPartnerPassThrough.initCon(oa.Id);
            L2Q_DocusignForPartnerPassThrough.updateTags(cvv2.Id, poad.Id);




           

            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.addHeader('X-DocuSign-Signature-1', 'njfdah');
            req.requestURI = 'https://qa-myakamai.cs125.force.com/partners/services/apexrest/L2Q_DocuSignStatusListener';  
            req.httpMethod = 'POST';

            List<API_Responses__mdt> resp = [select Response_Body__c from API_Responses__mdt where DeveloperName=:'L2Q_DocusignStatusListenerRejected'];
            req.requestBody = Blob.valueof(resp[0].Response_Body__c);
            RestContext.request = req;
            RestContext.response = res;
            L2Q_DocuSignStatusListener.handleDocusignStatus();
            L2Q_DocuSignStatusListener.DocuSignEnvelopHook l =  new L2Q_DocuSignStatusListener.DocuSignEnvelopHook();

            Test.stopTest();


    }

    static testmethod void CFA_ConfirmAttachmentControllerTest2() {
        User testRunUser = utilTestClass.getTestRunUser();
        System.runAs(testRunUser) {
            Opportunity oppty = SobjectRepository.getOpportunity();
            User partner = SobjectRepository.getPartnerUser();
            ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');
            Test.startTest();
            
            insert conVer;
            Partner_Order_Acceptance_Document__c poad = new Partner_Order_Acceptance_Document__c();
            poad.opportunity__c = oppty.Id;
            poad.Validation_Override__c = true;
            poad.Attachment__c = conVer.Id;
            poad.Order_Acceptance_Status__c = 'Pending Acceptance';

            Map<String, String> initialDataMap;
            System.runAs(partner) {
                initialDataMap = CFA_ConfirmAttachmentController.getInitialDataMap(conVer.Id);
            }

            insert poad;
            
            System.runAs(partner) {
                initialDataMap = CFA_ConfirmAttachmentController.getInitialDataMap('');
                initialDataMap = CFA_ConfirmAttachmentController.getInitialDataMap(conVer.Id);
            }

            poad = [SELECT Id,
            Opportunity__c,
            Opportunity__r.Name,
            Opportunity__r.Account.Id,
            Opportunity__r.Account.Name,
            Opportunity__r.Account.AKAM_Account_ID__c,
            Opportunity__r.Owner.Email, // SFDC-5907
            Opportunity__r.Partner_Involved__c,
            Opportunity__r.Partner_Involved__r.Name,
            Opportunity__r.Partner_Involved__r.Partner_PO_Required__c,
            Opportunity__r.Partner_Involved__r.Parent.Id,
            Partner_Account_ID__c,
            Partner_Involved_Name__c,
            Opportunity__r.Partner_Involved__r.POA_Email_List__c,
            Opportunity__r.Id,
            Opportunity__r.CloseDate,
            Opportunity__r.StageName,
            Notification__c,
            Notification_email_list__c,
            Partner_Notes__c,
            Customer_Unique_Id__c,
            Order_Acceptance_Status__c,
            Customer_Name__c,
            Accepted_At__c,
            Accepted_By__r.Name,
            Accepted_By__c,
            Rejection_Comments__c,
            URL_for_Partners__c,
            CreatedById,
            Attachment__c,
            PO_Number__c,passthroughDocumentSigned__c            FROM Partner_Order_Acceptance_Document__c WHERE Id = :poad.Id];

            
            poad.passthroughDocumentSigned__c=true;
            
            poad.Validation_Override__c = true;
            update poad;
            System.runAs(partner) {
                initialDataMap = CFA_ConfirmAttachmentController.getInitialDataMap(conVer.Id);
            }
            
            Test.stopTest();
        }
    }

    static testMethod void verifyDocumentCompletedScenario()
    {
        User partner = SobjectRepository.getPartnerUser();
        ContentDocumentLink att;
       

            Order_Approval__c oa = SobjectRepository.getOrderApproval();
            Opportunity oppty = SobjectRepository.getOpportunity();
            Partner_Order_Acceptance_Document__c poad = [select id from Partner_Order_Acceptance_Document__c limit 1];
            Test.startTest();
           
            Test.setMock(HttpCalloutMock.class, new CalloutMock(new List<String>{
                'L2Q_DocusignAccessToken'
                ,'L2Q_DocusignCreateEnvelope'
                }));

            ContentVersion cvv2 = [select id from ContentVersion where islatest=true limit 1];
            System.assert(cvv2.Id!=null, 'No content versions found');
            ContentVersion requiredDocument = [SELECT Id  FROM ContentVersion WHERE Id = :cvv2.Id LIMIT 1];
            L2Q_DocusignForPartnerPassThrough.createRestEnvelop('Anand', 'anandghegde@gmail.com', poad.Id, cvv2.Id);

            L2Q_DocusignForPartnerPassThrough lpp = new L2Q_DocusignForPartnerPassThrough();
            //L2Q_DocusignForPartnerPassThrough.initCon(oa.Id);
            L2Q_DocusignForPartnerPassThrough.updateTags(cvv2.Id, poad.Id);




           

            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.addHeader('X-DocuSign-Signature-1', 'njfdah');
            req.requestURI = 'https://qa-myakamai.cs125.force.com/partners/services/apexrest/L2Q_DocuSignStatusListener';  
            req.httpMethod = 'POST';

            List<API_Responses__mdt> resp = [select Response_Body__c from API_Responses__mdt where DeveloperName=:'L2Q_DocusignStatusListenerCompleted'];
            req.requestBody = Blob.valueof(resp[0].Response_Body__c);
            RestContext.request = req;
            RestContext.response = res;
            L2Q_DocuSignStatusListener.handleDocusignStatus();
            L2Q_DocuSignStatusListener.DocuSignEnvelopHook l =  new L2Q_DocuSignStatusListener.DocuSignEnvelopHook();

            Test.stopTest();


    }
    /*
    static testMethod void testWebhookListener()
    {

    }
*/


}