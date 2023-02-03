@isTest
public class TrackGovLimitsTest 
{
    @isTest static void TestTrackGovLimitsClass()
    {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TrackGovLimitsHttpCalloutMock());
        List<NewCMP_Audit_Object__c> listAsParam1 = new List<NewCMP_Audit_Object__c>();
        List<NewCMP_Audit_Object__c> listAsParam2 = new List<NewCMP_Audit_Object__c>();
        
        NewCMP_Audit_Object__c newcmp1 = new NewCMP_Audit_Object__c();
        newcmp1.Component_Created_Date__c = datetime.newInstance(2014, 9, 15, 12, 30, 0);
        newcmp1.Component_Id__c = '00NA0000000tdUVMAZ';
        newcmp1.Component_Name__c = 'Associated_Lead';
        newcmp1.Component_Type__c = 'LookupFilter';
        newcmp1.Corresponding_Object__c = 'Opportunity';
        listAsParam1.add(newcmp1);
        insert listAsParam1;

        NewCMP_Audit_Object__c newcmp2 = new NewCMP_Audit_Object__c();
        newcmp2.Component_Created_Date__c = datetime.newInstance(2014, 9, 15, 12, 30, 0);
        newcmp2.Component_Id__c = '00NA0000000tdUVMAY';
        newcmp2.Component_Name__c = 'Associated_Lead';
        newcmp2.Component_Type__c = 'LookupFilter';
        newcmp2.Corresponding_Object__c = 'Opportunity';
        listAsParam2.add(newcmp2);
        TrackGovLimits tg = new TrackGovLimits();
        String returnStatus = tg.TrackGovLimits();
        Callable extension = (Callable)Type.forName('TrackGovLimits').newInstance();
        String output = (String) extension.call('TrackGovLimits',null);
        TrackGovLimitsChainClass.returnApprovalProcess('Opportunity', 8000, listAsParam2);
        TrackGovLimitsDMLChain.resolve(listAsParam2);
        Test.stopTest();
    }
}