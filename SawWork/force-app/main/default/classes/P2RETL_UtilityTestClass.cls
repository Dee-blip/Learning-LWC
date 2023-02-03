/*=====================================================================================================+
    Class name          :   P2RETL_Mapping_TC 
    Author              :   Supreeth
    Created             :   5-May-18
    Purpose             :   This is a Test class for the Salesforce ETL Tool.
							1. P2RETL_GenerateOracleTableScript_Cls
							2. P2RETL_Mapping_cls
                            
                            
    Last Modified Developer     			Purpose            
    ============= ========================  =======
    2-MAY-18     Supreeth 					Initial Development(Jira Ticket# )
+=====================================================================================================*/
@isTest 
public class P2RETL_UtilityTestClass {
    
     // Test Method-1 : For P2RETL_GenerateOracleTableScript_Cls
    static testMethod void GenerateOracleTableScript_testMethod(){
        
        Test.startTest();
        
            P2RETL_GenerateOracleTableScript_Cls TableScriptInstance = new P2RETL_GenerateOracleTableScript_Cls();
            TableScriptInstance.getObjAPIName='Account';  
            TableScriptInstance.mainMethod();
        
        Test.stopTest();
          
    }
    
    // Test Method-2 : For P2RETL_Mapping_cls
    public static testmethod void sfdcObj_Tablemapping_testMethod(){
    
        Test.startTest();
    		P2RETL_Mapping_cls.getSFDCObject();
    		P2RETL_Mapping_cls.getDetails('BMCServiceDesk__Incident__c');
    		P2RETL_Mapping_cls.getOracleSFDCMapping('BMCServiceDesk__Incident__c') ;
         	P2RETL_Mapping_cls.getAllOracleSFDCMapping();
        Test.stopTest();
    }

}