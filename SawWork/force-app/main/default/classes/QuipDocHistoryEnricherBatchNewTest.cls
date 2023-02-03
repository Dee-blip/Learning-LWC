/**
* @description       : Test Class for QuipDocHistoryEnricherBatchNew Class
* @author            : apyati
* @group             : 
* @last modified on  : 07-05-2021
* @last modified by  : apyati
* Modifications Log 
* Ver   Date         Author   Modification
* 1.0   06-05-2021   apyati   Initial Version
**/


@isTest(SeeAllData=false)
private class QuipDocHistoryEnricherBatchNewTest {
    
        
    @isTest
    static  void testBatch(){
        
        //Account Creation
        Account acc = new Account();
        acc.Name = 'TestAccountPlan';
        acc.BillingCountry = 'India';
        acc.BillingState = 'DELHI';
        acc.website = 'www.AccountPlanWebsite.com';
        Database.SaveResult srAcc= Database.insert(acc);
        
        //Account Plan Template Mapping Creation
        Account_Plan_Template_Mapping__c  mapping = new Account_Plan_Template_Mapping__c ();
        mapping.Name = 'Media & Carrier';
        mapping.Template_URL__c = 'https://www.google.com';
        insert mapping;
        
        
        Account_Plan__c plan1 = new Account_Plan__c ();
        plan1.Name = 'TestAccountPlan Plan 1';
        plan1.Account__c = srAcc.getId();
        plan1.Plan_Type__c = 'Media & Carrier';
        plan1.Plan_Start_Date__c = System.today() - 30;
        plan1.Plan_End_Date__c = System.today() + 120;
        plan1.Quip_New_Document_URL__c = 'https://quip.com/e4V7AeaKCVmq';
        Database.SaveResult srPlan= Database.insert(plan1);
        
        Quip_Document_History__c qdh = new Quip_Document_History__c();
        qdh.Event__c = 'open-thread';
        qdh.Action__c = 'open';
        qdh.Quip_Thread_Id__c = 'GDGAAA6IlPa';
        qdh.Quip_User_Id__c = 'bAUAEADkFcz';
        qdh.Timestamp__c = Long.valueOf('1585756818148587');
        qdh.Quip_Event_Id__c = '1590a1fdae10896cb';
        insert qdh;
        
        
        CollabUserEngagementMetric newmetric = new CollabUserEngagementMetric();
        newmetric.MetricDate = system.today();
        newmetric.SalesforceUserId = userinfo.getUserId();
        newmetric.EditCount =10;
        newmetric.ViewCount =10;
        newmetric.QuipThreadType ='DOCUMENT';
        Database.SaveResult srMetric= Database.insert(newmetric);
        
        CollabUserEngmtRecordLink  newLink = new CollabUserEngmtRecordLink();
        newLink.UserEngagementMetricId  = srMetric.getId();
        newLink.ParentRecordId = srPlan.getId();
        Database.SaveResult srLink= Database.insert(newLink);
        
        
        QuipDocHistoryEnricherBatchNew bInstance = new QuipDocHistoryEnricherBatchNew();

        List<CollabUserEngagementMetric> lstEngMetric = new List<CollabUserEngagementMetric>();
        lstEngMetric.add(newmetric);
        bInstance.processEngagmentMetrics(lstEngMetric);
        
		Account_Plan_Tracker__c apt = bInstance.getTrackerInstance(srPlan.getId(),System.now(),10,userInfo.getUserId(),'Create');
        System.assert(apt!=null,'Activity Logs not created');

		DataBase.executeBatch(bInstance); 

    }
    
}