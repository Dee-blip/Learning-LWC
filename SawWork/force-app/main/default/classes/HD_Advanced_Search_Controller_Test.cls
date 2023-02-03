/*
* File Name: HD_Advanced_Search_Controller_Test
* Description : Test class for 'HD_Advanced_Search_Controller'
* @author : Aneesh Budnar 
* Modification Log ===============================================================
* Date 				Author 				Modification
* Apr 22nd, 2021    Aneesh Budnar       PRTORES-2123 - HD Create Knowledge article Search and view Panel in LWC for Lighting UI for staff Part 2
*/
@isTest
public class HD_Advanced_Search_Controller_Test {
    @isTest
    public static void whenGetFieldsCalledExpectAllFieldsToBeReturned() {
        String serializedData = HD_Advanced_Search_Controller.getFields('BMCServiceDesk__Incident__c');
        List<HD_Advanced_Search_Controller.FieldMetadata> metadata = (List<HD_Advanced_Search_Controller.FieldMetadata>)JSON.deserialize(
            serializedData, List<HD_Advanced_Search_Controller.FieldMetadata>.class);
        System.assert(metadata.size() > 0, 'The field metadata was not retrieved as expected');
    }
    
    @isTest
    public static void whenSearchConditionsAreProvidedForANDExpectSOQLCriteriaToBeReturned() {
        List<HD_Advanced_Search_Controller.Condition> conditions = new List<HD_Advanced_Search_Controller.Condition> {
            getCondition('BMCServiceDesk__Article_Number__c','=','123',1,false,false,true,'number'),
            getCondition('BMCServiceDesk__FKCategory__c','=','testId',2,false,true,false,''),            
            getCondition('BMCServiceDesk__Status__c','=','Draft',3,true,false,false,'text'),
            getCondition('BMCServiceDesk__Closed_Date__c','<=','2021-04-27T08:26:00.000Z',4,false,false,true,'datetime')
        };
        String soqlCriteria = HD_Advanced_Search_Controller.getAdvancedSearchFilter(' AND ', '',JSON.serialize(conditions));
        System.assertEquals('BMCServiceDesk__Article_Number__c = 123 AND BMCServiceDesk__FKCategory__c = \'testId\' AND BMCServiceDesk__Status__c = \'Draft\' AND BMCServiceDesk__Closed_Date__c <= 2021-04-27T08:26:00.000Z', 
                            soqlCriteria, 'Mismatch in the actual and expected values');
    }
    
    @isTest
    public static void whenSearchConditionsAreProvidedForCustomExpectSOQLCriteriaToBeReturned() {
        List<HD_Advanced_Search_Controller.Condition> conditions = new List<HD_Advanced_Search_Controller.Condition> {
            getCondition('BMCServiceDesk__Article_Number__c','=','123',1,false,false,true,'number'),
            getCondition('BMCServiceDesk__FKCategory__c','=','testId',2,false,true,false,''),            
            getCondition('BMCServiceDesk__Status__c','=','Draft',3,true,false,false,'text'),
            getCondition('BMCServiceDesk__Closed_Date__c','<=','2021-04-27T08:26:00.000Z',4,false,false,true,'datetime')
        };
        String soqlCriteria = HD_Advanced_Search_Controller.getAdvancedSearchFilter(' CUSTOM ', '1 AND 2 AND (3 OR 4)',JSON.serialize(conditions));
        System.assertEquals('BMCServiceDesk__Article_Number__c = 123 AND BMCServiceDesk__FKCategory__c = \'testId\' AND (BMCServiceDesk__Status__c = \'Draft\' OR BMCServiceDesk__Closed_Date__c <= 2021-04-27T08:26:00.000Z)', 
                            soqlCriteria, 'Mismatch in the actual and expected values');
    }
    
    private static HD_Advanced_Search_Controller.Condition getCondition(
        String fieldApiName, String operator, String fieldValue, 
        Integer order, Boolean isPicklist, Boolean isLookup, Boolean isLWCInput, String type) {
           HD_Advanced_Search_Controller.Condition condition = new HD_Advanced_Search_Controller.Condition();
           condition.fieldApiName = fieldApiName;
           condition.operator = operator;
           condition.fieldValue = fieldValue;
           condition.order = order;
           condition.isPicklist = isPicklist;
           condition.isLookup = isLookup;
           condition.isLWCInput = isLWCInput;
           condition.type = type;
           return condition;
     }
}