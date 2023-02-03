/*
* File Name: HD_Test_UnifiedHisotry
* Description : Test class for HDUnifiedHistoryLightningEdition
* @author : 
* Modification Log ===============================================================
* Date 				Author 				Modification
* Nov 29th, 2021    Aneesh Budnar       PRTORES-2358 - HD Code Scanner 1 fixes
*/
@isTest(seeAllData = false)
public class HD_Test_UnifiedHisotry {
    
    static BMCServiceDesk__Category__c category;
    static User u;
    static{
        HD_Test_Data_Factory.init();
        BMCServiceDesk__CategoryTypes__c categoryType = 
            new BMCServiceDesk__CategoryTypes__c(Name='Q_ITOC');
        insert categoryType;
        category = new BMCServiceDesk__Category__c(
            BMCServiceDesk__FKCategoryType__c = categoryType.Id, 
            BMCServiceDesk__AvailableForServiceCatalog__c = true,
            BMCServiceDesk__Display_In_SelfService__c = true,
            BMCServiceDesk__AvailableForIncidents__c = true,
            Name='Hardware Issues');
        insert category;
        u = [select id from User where isactive=true Order By name limit 1];
    }
    
    static testmethod void testApprovalHistory(){
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Test.startTest();
            
        User user = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();
        System.runAs(user) {
            BMCserviceDesk__Incident__c  inc = new BMCServiceDesk__Incident__c();
            inc.Approver__c = u.id;
            inc.Approver__c =System.UserInfo.getUserId();
            inc.HD_Ticket_Priority__c = '4';
            inc.BMCServiceDesk__FKClient__c = UserInfo.getUserId();
            inc.BMCServiceDesk__FKCategory__c = category.Id;
            insert inc; 
            Test.stopTest();
            inc.OwnerId = System.UserInfo.getUserId();
            update inc;
        
            //Test.startTest();        
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('comment');
            req1.setObjectId(inc.id);
            req1.setSubmitterId(System.UserInfo.getUserId());
            
            Approval.ProcessResult result =  Approval.process(req1);
            Map<String,Map<String,List<unifiedHistoryClass>>> history = HDUnifiedHistoryLightningEdition.getGroupedUnifiedHistoryByDate(inc.id,'100');
        }
    }
    
    static testmethod void testActionHistory(){
        BMCServiceDesk__Action__c action = [SELECT Id, Name FROM BMCServiceDesk__Action__c WHERE Name='Email Received' LIMIT 1];
        BMCserviceDesk__Incident__c  inc = new IncidentTestHelper.IncidentBuilder().buildAndSave();
        BMCServiceDesk__IncidentHistory__c newHistory = new BMCServiceDesk__IncidentHistory__c(BMCServiceDesk__FKIncident__c = inc.id,BMCServiceDesk__FKAction__c = action.Id);
        newHistory.BMCServiceDesk__note__c = 'From: '+UserInfo.getUserEmail()+'Sent: Fri, Feb 12, 2016 14:01 PMTo: eis-tools-dev@akamai.com; Cc: Subject: Re: [Eis-tools-dev] Sandbox: Akamai Ticketing Incident ticket #(Ref:IN:00252480) has been created and assigned to EAE OpsTest isFrom: Akamai ticketing testDate: Friday, February 12, 2016 at 1:59 PMTo: Pranav PrashantCc: Akamai ticketing testSubject: Sandbox: Akamai Ticketing Incident ticket #(Ref:IN:00252480) has been created and assigned to EAE OpsIncident # 00252480 has been assigned to EAE Ops. This incident has the following details:      Incident Short Description: dasd      Incident Description: dasd      Resolution:      Client Name: Pranav Prashant      Client Title : Software Engineer..      Client Manager : Sachin Siddaveerappa      Category: Crm.akamai.com      Category Tree: Enterprise Application      Open Date: 2/12/2016 8:29 AM      Priority: 2      View ticket 00252480<https://urldefense.proofpoint.com/v2/url?u=https-3A__akamai-2D-2DP2RDev.cs43.my.salesforce.com_-3FstartURL-3D_apex_bmcservicedesk-5F-5Fssredirect-3Finc-3Da5U6300000000hl&d=CwMCaQ&c=96ZbZZcaMF4w0F4jpN6LZg&r=BCTH9VJ0q72k9lrtcBvW1h7TJhSrF-FbWhlgBfSoTb0&m=XHt8uPe5u_nUeHjL6sLjjeYuce4iwO5z8yiiihtOS0Q&s=EOmCOv0wSTeSiNtE0fvIrg1iSLwAkqecnYG3PCb-oQY&e=>';
        insert newHistory;
        BMCServiceDesk__IncidentHistory__c incHist = [Select Id, BMCServiceDesk__FKIncident__c from BMCServiceDesk__IncidentHistory__c limit 1];
        Test.startTest();
        Map<String,Map<String,List<unifiedHistoryClass>>> history = HDUnifiedHistoryLightningEdition.getGroupedUnifiedHistoryByDate(incHist.BMCServiceDesk__FKIncident__c,'100');
        System.assert(history.size() > 0);
        Test.stopTest();
    }
    
    static testmethod void testDeleteFeild(){ 
        ManagedPkgErrorClass.isFromManagedPackage = false;
        BMCserviceDesk__Incident__c  inc = new IncidentTestHelper.IncidentBuilder().buildAndSave();
        inc.HD_Routing_Settings__c = null;
        Test.startTest();
        update inc;
        Map<String,Map<String,List<unifiedHistoryClass>>> history = HDUnifiedHistoryLightningEdition.getGroupedUnifiedHistoryByDate(inc.id,'1000');
        Test.stopTest();  
    }
    
    static testmethod void functionTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        HDUnifiedHistoryLightningEdition histClass = new HDUnifiedHistoryLightningEdition();
        histClass.getStatusPicklist();
    }
    
    static testmethod void testSparkIntegration()
    {
        BMCServiceDesk__Incident__c inc = new IncidentTestHelper.IncidentBuilder().buildAndSave();
        //creating ContentNote   
        ContentNote cn = new ContentNote();
        string s = 'Testing';
        cn.Title = s;
        cn.Content = EncodingUtil.base64Decode(s);
        insert cn;
        Test.startTest();   
        //making Links to ContentNotes
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cn.id;
        cdl.LinkedEntityId =inc.id;
        cdl.ShareType = 'v';
        cdl.Visibility = 'AllUsers';
        
        cdlList.add(cdl);
        
        Database.SaveResult[] srList = Database.insert(cdlList, false);
        for(Database.SaveResult sr: srList)
        {
            if (sr.isSuccess()) {
                system.debug('Successfully Inserted-->'+sr.getId());
                HDUnifiedHistoryLightningEdition.getAttachedNotesDocument(inc.id,10);
            }
            else{
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('affected error: ' + err.getFields());
                }
                
            }
            
        }//for
        
        
        //Map<String,Map<String,List<unifiedHistoryClass>>> history = HDUnifiedHistoryLightningEdition.getGroupedUnifiedHistoryByDate(incHist.id,'1000');
        Test.stopTest();   
    }//
   
}