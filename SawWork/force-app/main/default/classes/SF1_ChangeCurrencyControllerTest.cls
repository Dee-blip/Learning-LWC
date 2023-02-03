/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 08-19-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   08-19-2021   apyati   Initial Version
**/
@isTest(seeAllData=false)
public class SF1_ChangeCurrencyControllerTest {
    static testmethod void changecurrencyTest(){
        String Message;
        OpportunityLineItem oppLineObj = new OpportunityLineItem();
        Opportunity oppRecord = new Opportunity();
        Map<String,String> prodNamesMap = new Map<String,String>();
        Map<String,List<String>> dependentPickListValues = new Map<String,List<String>>();
        Boolean negativeValueCheck = false;
        Profile prof = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
        User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =prof.Id);
        u.isActive=true;
        insert u;
        
        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.OwnerId =u.Id;
        acc.Website='https://TestOrg.co.in';
        insert acc;
        
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty curr','1. Identify Need');
        oppty.AccountId =acc.Id;
        oppty.OwnerId = u.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        
        oppty.Pricebook2Id = Test.getStandardPricebookId();
        insert oppty;
        
        Product2 p = new Product2();
        p.Name     = 'TESTManageProd';
        p.Family = 'Mobile';
        Database.insert(p);
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.Product2Id   = p.id;
        pbe.IsActive     = true;
        pbe.UnitPrice    = 1;
        pbe.CurrencyIsoCode = 'USD';
        Database.insert(pbe);

        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = Test.getStandardPricebookId();
        pbe1.Product2Id   = p.id;
        pbe1.IsActive     = true;
        pbe1.UnitPrice    = 70;
        pbe1.CurrencyIsoCode = 'INR';
        Database.insert(pbe1);
        
        OpportunityLineItem i = new OpportunityLineItem();
        i.opportunityId       = oppty.id;
        i.pricebookentryid    = pbe.id;
        i.quantity            = 1;
        i.unitprice           = 1;
        i.Projected_Monthly_commit_fees__c = 0;
        i.Projected_Avg_Rev_Non_Commit__c = 0;
        Database.insert(i);
        
        oppRecord = SF1_ChangeCurrencyController.fetchOpportunity(oppty.id);
        
        system.assert(oppRecord!= null, 'fetchOpportunity failed');
        List<String> picklistValues = SF1_ChangeCurrencyController.loadCurrencyPicklist('Opportunity','CurrencyISOCode');
        system.assert(picklistValues!= null, 'loadCurrencyPicklist failed');
        Message = SF1_ChangeCurrencyController.checkErrors(oppty);
        system.assert(Message== 'success', 'checkErrors failed');
        oppty.CurrencyISOCode = 'INR';
        Message = SF1_ChangeCurrencyController.convertCurrency(oppty);
        system.assert(Message== 'success', 'convertCurrency failed');
        
        OA_EmailBlast_AttachmentWrapper emailWrap= new OA_EmailBlast_AttachmentWrapper();
        emailWrap.parentType = 'Opportunity';
        OA_EmailBlast_AttachmentWrapper emailErapper = new OA_EmailBlast_AttachmentWrapper(emailWrap);
        system.assert(emailErapper!= null, 'emailErapper  failed');
        ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'textfile.txt', 'textfile.txt', 'my attachment text PO');
        system.assert(conVer!= null, 'setContentVersion failed');
        insert conVer;
        system.assert(conVer.Id!= null, 'conVer Insert  failed');
        ContentVersion conVer2 = [SELECT ContentDocumentId, Id FROM ContentVersion WHERE Id = :conVer.Id];
        ContentDocumentLink attach = L2Q_ContentDocumentUtilClass.setContentDocumentLink(conVer2.ContentDocumentId, oppty.Id, 'I', 'AllUsers');
        system.assert(attach!= null, 'attach failed');
        OA_EmailBlast_AttachmentWrapper emailErapperAttch = new OA_EmailBlast_AttachmentWrapper(attach);
        system.assert(emailErapperAttch!= null, 'emailErapperAttch failed');
        
    }
    
    static testmethod void oa_esignIntermediateTest() {
        OA_ESignIntermediateController oac = new OA_ESignIntermediateController();
    }
}