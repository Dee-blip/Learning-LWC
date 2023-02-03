/**
 @author: Shubham Richhariya
 MOB-156 : Test Class for GsmLite_AuraInputLookupController

 * History:
 * =========================
 * Developer        Date        Description

   Shubham      05/June/17      Test Class for GsmLite_AuraInputLookupController
**/
@isTest(seeAllData=false)
private class GsmLite_AuraInputLookupControllerTest {

    private static List<Opportunity> oppList = new List<Opportunity>();
    private static boolean fRunflag = false;

    public static void dataSetup() {
        if(fRunflag)
            return;
        Account acc = utilTestClass.CreateAccount('TestGSMLiteACC');
        insert acc;
        Opportunity opp1,opp2,opp3;

        opp1 = utilTestClass.CreateOpportunity('TestGSMLiteOpp1', '3-Develop');
        opp1.AccountId = acc.Id;
        opp1.CloseDate = Date.today();
        opp1.Deal_Type__c = 'Direct';


        opp2 = utilTestClass.CreateOpportunity('TestGSMLiteOpp2', '3-Develop');
        opp2.AccountId = acc.Id;
        opp2.CloseDate = Date.today();
        opp2.Deal_Type__c = 'Direct';

        opp3 = utilTestClass.CreateOpportunity('TestGSMLiteOpp3', '3-Develop');
        opp3.AccountId = acc.Id;
        opp3.CloseDate = Date.today();
        opp3.Deal_Type__c = 'Direct';


        oppList.add(opp1);
        oppList.add(opp2);
        oppList.add(opp3);
        insert oppList;
    }

    private static testmethod void test_get_name(){
        Test.startTest();
        dataSetup();
        System.debug('oppList :'+JSON.serialize(oppList));


        String ret = GsmLite_AuraInputLookupController.getCurrentValue(null, null);
        System.assert(String.isBlank(ret), 'Should return null string ['+ret+']');

        ret = GsmLite_AuraInputLookupController.getCurrentValue('INVALID_OBJECT', 'INVALID_ID');
        System.assert(String.isBlank(ret), 'Should return null string ['+ret+']');

        ret = GsmLite_AuraInputLookupController.getCurrentValue('INVALID_OBJECT', '000000000000000');
        System.assert(String.isBlank(ret), 'Should return null string ['+ret+']');

        ret = GsmLite_AuraInputLookupController.getCurrentValue('Opportunity', '000000000000000');
        System.assert(String.isBlank(ret), 'Should return null string ['+ret+']');

        ret = GsmLite_AuraInputLookupController.getCurrentValue('Opportunity', oppList[0].Id);
        System.assert(ret == oppList[0].Name, 'Should return '+oppList[0].Name+ ' ['+ret+']');

        Test.stopTest();
    }

    private static testmethod void test_search(){
        Test.startTest();
        dataSetup();

        String ret = GsmLite_AuraInputLookupController.searchSObject(null, null,'','');
        System.assert(String.isBlank(ret), 'Should return null string ['+ret+']');

        ret = GsmLite_AuraInputLookupController.searchSObject('INVALID_OBJECT', 'NO_RESULT_SEARCH_STRING','','');
        System.assert(String.isBlank(ret), 'Should return null string ['+ret+']');

        ret = GsmLite_AuraInputLookupController.searchSObject('Opportunity', 'NO_RESULT_SEARCH_STRING','','');
        System.assert(String.isNotBlank(ret), 'Should return non null string ['+ret+']');
        List<GsmLite_AuraInputLookupController.SearchResult> sResList = (List<GsmLite_AuraInputLookupController.SearchResult>)JSON.deserialize(ret,
                                                                                                                                               List<GsmLite_AuraInputLookupController.SearchResult>.class);
        System.assert(sResList.isEmpty(), 'Why not empty list? ['+sResList.size()+' instead]');

        Test.setFixedSearchResults(new List<String>{oppList[0].Id,oppList[1].Id,oppList[2].Id});
        ret = GsmLite_AuraInputLookupController.searchSObject('Opportunity', 'Test','','');
        System.assert(String.isNotBlank(ret), 'Should return a serialized list string ['+ret+']');
        sResList = (List<GsmLite_AuraInputLookupController.SearchResult>)JSON.deserialize(ret,
                                                                                          List<GsmLite_AuraInputLookupController.SearchResult>.class);
        System.assert(sResList.size() == 3, 'Why not 3 items found? ['+sResList.size()+' instead]');
        Test.stopTest();
    }
}