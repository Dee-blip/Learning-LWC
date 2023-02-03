/* History:
* =========================
* @author Himanshu Verma,  1st June 2020
*/
@isTest
public class MarketingUtilTestClass 
{
    static User dmlUser = new User(id=UserInfo.getUserId());

    public static testmethod void Test_MarketingSettingVerbose() {
        String value = MarketingUtilClass.getMarketingSettingVerboseValue('HighestToLowestLeadQualificationStage');
        System.assert(value != null);
    }
    
    public static testmethod void Test_GetInt() {
        Integer value = MarketingUtilClass.getInt('HourSizeRelatedToFormulaUpdateCDP');
        System.assertEquals(-24, value);
    }
   
    public static testmethod void Test_LeanDataValuesForMultiples() {
        Map<String, LeanData__mdt> fetchRequiredMDTs = new Map<String, LeanData__mdt>();
        List<String> listOfMDT = new List<String>();
        listOfMDT.add('Automated_Lean_Data_Account_for_Lead');
        listOfMDT.add('WWWLeadGenAccountId');
        fetchRequiredMDTs = MarketingUtilClass.getLeanDataValueForMultiples(listOfMDT);
        System.assert(fetchRequiredMDTs != null);
    }
    
    public static testmethod void Test_parseObjectsForDynamicQuery() {
        List<Sobject> objList = new List<Sobject>();
        Account testAccount = utilTestClass.CreateAccount('Test Account2');
        insert testAccount;
        objList.add(testAccount);
        String query = MarketingUtilClass.parseObjectsForDynamicQuery(objList, 'Name');
        System.assert(query.contains('Test Account2'));
    }
    
    public static testmethod void Test_parseIdsForDynamicQuery() {
        List<Id> IdList = new List<Id>();
        Account testAccount = utilTestClass.CreateAccount('Test Account2');
        insert testAccount;
        IdList.add(testAccount.Id);
        String query = MarketingUtilClass.parseIdsForDynamicQuery(idList);
        System.assert(query.contains(testAccount.Id));
    }
    
    public static testmethod void Test_parseStringsForDynamicQuery() {
        List<String> strList = new List<String>();
        strList.add('Name');
        strList.add('Email');
        String query = MarketingUtilClass.parseStringsForDynamicQuery(strList);
        System.assert(query.contains('Name'));
        System.assert(query.contains('Email'));
    }
    
    public static testmethod void Test_getGSMSettingValueForMultiples() {
        Map<String, String> fetchRequiredMDTs = new Map<String, String>();
        List<String> listOfMDT = new List<String>();
        listOfMDT.add('BPPStatusFieldsForLead');
        listOfMDT.add('BPPStageFieldsForLead');
        fetchRequiredMDTs = MarketingUtilClass.getGSMSettingValueForMultiples(listOfMDT);
        System.assert(fetchRequiredMDTs != null);
    }
    
    public static testmethod void Test_getGSMSettingSetValuesForMultiples() {
        Map<String, Set<String>> fetchStringSetForRequiredMDTs = new Map<String, Set<String>>();
        List<String> fetchStringSetFromMDT = new List<String>();
        fetchStringSetFromMDT.add('BPPStageFieldsForLead');
        fetchStringSetFromMDT.add('BPPStatusFieldsForLead');
        fetchStringSetForRequiredMDTs = MarketingUtilClass.getGSMSettingSetValuesForMultiples(fetchStringSetFromMDT);
        System.assert(fetchStringSetForRequiredMDTs != null);
    }
    public static testMethod void testMergeUpdates()
    {
        System.runAs(dmlUser)
        {
            Account testAccount = utilTestClass.CreateAccount('Test Account2');
            insert testAccount;
            Lead ml = new Lead();
            ml.LastName='MarketoLead';
            ml.Company='Company';
            ml.Associated_Account__c = testAccount.Id;
            ml.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            insert ml;
            Lead l1 = new Lead();
            l1.LastName='Test1';
            l1.Company='Company';
            l1.Associated_Account__c = testAccount.Id;
            l1.Parent_Lead__c = ml.Id;
            Lead l2 = new Lead();
            l2.LastName = 'Test2';
            l2.Company = 'Company';
            l2.Associated_Account__c = testAccount.Id;
            l2.Parent_Lead__c = ml.Id;
            List<Lead> l = new List<Lead>();
            l.Add(l1);
            l.Add(l2);
            insert l;
            Lead l3 = l[0];
            l3.put('firstname','Merge this');
            l.Add(l3); 
            Map<String,Lead> m1 = new Map<String,Lead>();
            Test.startTest();
            Map<String,Lead> m = (Map<String,Lead>)MarketingUtilClass.mergeUpdates(m1,l);
            Test.stopTest(); 
            Lead actualLead = m.get(l3.Id);
            System.assertEquals('Merge this', actualLead.FirstName, 'First name should be merged');
        }
    }
}