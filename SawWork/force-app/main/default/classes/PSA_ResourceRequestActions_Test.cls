/***
    PSA_ResourceRequestActions_Test
    @author Liz Ichihashi
    @Description : This Class contains methods to test PSA_ResourceRequestAction
                 
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class. 
    Sharath Prasanna      23 April 2018 Changed the class due to 101 SOQL error. Added the static method and test start and stop methods      
*/
@isTest(SeeAllData=false)
public with sharing class PSA_ResourceRequestActions_Test {

        //Static block to create test data
    static{
        PSA_ResourceRequestActions_Test.createTestData();
    } 

    public static PSA_TestUtility testUtil;
    public static pse__Region__c reg;
    public static User usr;
    public static Account acct;
    public static Contact resource;
    public static pse__Grp__c grp;
    public static pse__Practice__c pract;
    public static pse__Proj__c templateProj;
    public static User usr2;
    public static Contact resource2;
    public static pse__Permission_Control__c pc;

    public static void createTestData()
    {
        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(false);
        acct.Area__c ='Comm Central';   
        insert acct;
        usr = testUtil.newUserSysAdmin(true);      
        resource = testUtil.newResource(false, acct.Id, usr.Id);
        grp = testUtil.newGroupMaster(TRUE);
        resource.pse__Group__c = grp.Id;
        insert resource;

        pract = testUtil.newPracticeMaster(true);
        Id practId =  pract.ID;
        templateProj = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);   
        templateProj.pse__Is_Template__c = true;
        insert templateProj;        
        
        usr2 = testUtil.newUserSysAdmin(true);        

        pc = testUtil.newPermissionControl(true, usr2.Id, reg.Id);   
    }
    public static testMethod void testSetGroup() 
    {
        //Opportunity opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());
        //List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 4);
        test.startTest();
            resource2 = testUtil.newResource(false, acct.Id, usr2.Id);
            resource2.pse__Group__c = grp.Id;
            insert resource2;
           
            pse__Resource_Request__c projResReq;   
                    
            System.runAs(usr2) {       
                projResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(15), templateProj.Id, null,reg.Id);   
            }
            
            pse__Resource_Request__c resReq = [select Id, pse__Group__c from pse__Resource_Request__c where id = :projResReq.Id];
            System.assert(resReq.pse__Group__c == grp.Id);  
        test.stopTest();   
    }   
    
    public static testMethod void testSetGroupException() 
    {
        //Opportunity opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());
        //List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 4);
        test.startTest();
            resource2 = testUtil.newResource(true, acct.Id, null);
           
            pse__Resource_Request__c projResReq;   
            
            System.runAs(usr2) 
            {  
                boolean excThrown = false;
                try 
                {     
                    projResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(15), templateProj.Id, null,reg.Id);  
                } 
                catch (Exception e) 
                {
                    excThrown = true;
                }    
                System.assert(excThrown);
            }
        test.stopTest();    
    }   
}