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
 Author : Jayalakshmi A
 Dscription: This class contains test cases for the SoqlBuilder class
 */
@isTest
private class EB_SoqlBuilder_Test {

    static testMethod void myUnitTest() {
        
        ManagedPkgErrorClass.isFromManagedPackage=false;
		String query;
    
        List<String> searchFields = new List<String>();
        searchFields.add('Customer_Tier__c');
        searchFields.add('Support_Level__c');
        searchFields.add('Phone');
    
        List<String> searchOperators = new List<String>();
        searchOperators.add('=');
        searchOperators.add('%');
        searchOperators.add('=');
        
        List<String> searchValues = new List<String>();
        searchValues.add('A+');
        searchValues.add('Premium');
        searchValues.add('123');  
        
        List<String> logicalOperators = new List<String>();
        logicalOperators.add('AND');
        logicalOperators.add('OR');
        
        Integer i = 0;
        EB_SoqlBuilder searchParent = new EB_SoqlBuilder();
        searchParent.clearSearchCriteria();
        searchParent.setTableName('Account');
        String tableName = searchParent.getTableName();
        
        System.assertEquals(tableName,'Account');
        
        //while(i < searchFields.size())
        //{
            searchParent.addSearchCriteria(searchFields.get(0), searchOperators.get(0), searchValues.get(0), logicalOperators.get(0));
            searchParent.addSearchCriteria(searchFields.get(1), searchOperators.get(1), searchValues.get(1), logicalOperators.get(1));
            searchParent.addSearchCriteria(searchFields.get(2), searchOperators.get(2), searchValues.get(2), '');
            //i++;
        //}
        
        searchParent.removeSearchCriteria('Phone', '=', '123');
        
        String selectClause = searchParent.buildSelectClause();
        System.assertEquals('SELECT Id FROM Account where ',selectClause);
        String result = searchParent.buildWhereClause();
        System.assertEquals('Customer_Tier__c = \'A+\' AND Support_Level__c LIKE \'%Premium%\'', result);
        query = searchParent.buildSQL(result);
        //(Customer_Tier__c = 'A+' ) AND ( Support_Level__c LIKE '%Premium%' OR Phone = '123')
        //System.assertEquals('SELECT Id FROM Account where Customer_Tier__c = \'A+\' AND Support_Level__c LIKE \'%Premium%\'',query);

    }
}