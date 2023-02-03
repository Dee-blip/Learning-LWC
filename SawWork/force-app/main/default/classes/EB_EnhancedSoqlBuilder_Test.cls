/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
 /*
 Author: Sharath K
 Description: Contains test cases for EnhancedSoqlBuilder
 */
 
@isTest
private class EB_EnhancedSoqlBuilder_Test {

    static testMethod void myUnitTest() {
		
		ManagedPkgErrorClass.isFromManagedPackage=false;	
        String query;
        String xml;
        
        List<String> searchFields = new List<String>();
        searchFields.add('Customer_Tier__c');
        searchFields.add('Support_Level__c');
        searchFields.add('Phone');
        searchFields.add('DUNS_Revenue__c');

        List<String> searchOperators = new List<String>();
        searchOperators.add('=');
        searchOperators.add('%');
        searchOperators.add('=');
        searchOperators.add('=');

        List<String> searchValues = new List<String>();
        searchValues.add('A+');
        searchValues.add('Premium');
        searchValues.add('123');  
        searchValues.add('200');

        List<String> logicalOperators = new List<String>();
        logicalOperators.add('AND');
        logicalOperators.add('OR');
        logicalOperators.add('OR');

        List<String> dataTypes = new List<String>();
        dataTypes.add('String');
        dataTypes.add('String');
        dataTypes.add('String');
        dataTypes.add('Numeric');
            
        Integer i = 0;
        EB_EnhancedSoqlBuilder searchParent = new EB_EnhancedSoqlBuilder();
        searchParent.clearSearchCriteria();
        searchParent.setTableName('Account');
        String tableName = searchParent.getTableName();

        System.assertEquals(tableName,'Account');


        searchParent.addSearchCriteria(searchFields.get(0), searchOperators.get(0), searchValues.get(0), logicalOperators.get(0),dataTypes.get(0));
        searchParent.addSearchCriteria(searchFields.get(1), searchOperators.get(1), searchValues.get(1), logicalOperators.get(1),dataTypes.get(1));
        searchParent.addSearchCriteria(searchFields.get(2), searchOperators.get(2), searchValues.get(2), logicalOperators.get(2),dataTypes.get(2));
        searchParent.addSearchCriteria(searchFields.get(3), searchOperators.get(3), searchValues.get(3),'',dataTypes.get(3));


        searchParent.removeSearchCriteria('Phone', '=', '123');

        String selectClause = searchParent.buildSelectClause();
        System.assertNotEquals(selectClause,null);
        String result = searchParent.buildWhereClause();
        System.assertEquals('Customer_Tier__c = \'A+\' AND Support_Level__c LIKE \'%Premium%\' OR DUNS_Revenue__c = 200', result);
        query = searchParent.buildSQL(result);
        xml = searchParent.Createxml();
        //System.assertEquals('Select Id FROM Account where Customer_Tier__c = \'A+\' AND Support_Level__c LIKE \'%Premium%\' OR DUNS_Revenue__c = 200',query);

    }
}