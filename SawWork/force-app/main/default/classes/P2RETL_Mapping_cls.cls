/*=====================================================================================================+
    Class name          :   P2RETL_Mapping_cls 
    Author              :   Supreeth
    Created             :   13-Mar-18 
    Purpose             :   This is a one of the classes for Salesforce ETL Tool. It is referenced in 
                            1. P2RETLDisplayMappingSCFF - Lightning Bundle
							2. P2RETLApp - Lightning App
                            3. P2RETL_Mapping_Test_Cls - Test Class 
							4.P2RETLDisplayObjectToTable
                            
    Last Modified Developer     			Purpose            
    ============= =========     			=======
    21-May-18      Supreeth       Added getAllOracleSFDCMapping method for class
+=====================================================================================================*/



public with sharing class P2RETL_Mapping_cls {
 
    //This returns the list of SFDC object to be displayed in the dropdown  
    @AuraEnabled
    public static List<String> getSFDCObject() { 
    List<String> FinalSFDCObjectList = new List<String>();
        Set<String> SFDCObjectSet=new  Set<String>();
        for(P2RETL_SFDC_Object_to_EDWTableMapping__mdt SFDCObjectListIterator:[SELECT SFDCObject__c FROM P2RETL_SFDC_Object_to_EDWTableMapping__mdt ORDER BY SFDCObject__c])
        {
         SFDCObjectSet.add(SFDCObjectListIterator.SFDCObject__c);   
        }
       
        FinalSFDCObjectList.addall(SFDCObjectSet);
        return FinalSFDCObjectList;

    }
    //This returns the corresponding List of rows for a particular SFDC object  
    @AuraEnabled
    public static List<P2RETL_SFDC_EDW_Mapping__c> getDetails(String SelectedSFDCObject)
    {
        
        
         String FinalQuery='SELECT SFDC_Field_Name__c,Sfdc_Data_type__c,EDW_Field_Name__c,EDW_Field_DataType__c FROM P2RETL_SFDC_EDW_Mapping__c';
        

         FinalQuery= FinalQuery+' WHERE SFDC_Object_Name__c=\''+SelectedSFDCObject+'\''+' ORDER BY SFDC_Field_Name__c';
     

       return  Database.query(FinalQuery);

    }
    
    
    //This returns the corresponding EDW Table Name for a particular SFDC object  
 	@AuraEnabled
    public static List<String> getOracleSFDCMapping(String SelectedSFDCObject){
        List<P2RETL_SFDC_Object_to_EDWTableMapping__mdt> TemperoryList = new List <P2RETL_SFDC_Object_to_EDWTableMapping__mdt>();
        String FinalQuery='SELECT EDWTable__c,SFDCObject__c FROM P2RETL_SFDC_Object_to_EDWTableMapping__mdt';      
		FinalQuery= FinalQuery+' WHERE SFDCObject__c=\''+SelectedSFDCObject+'\''+'LIMIT 1';
  	   	temperoryList=Database.query(FinalQuery);
        List<String> Sfdc_EDW_List=new List<String>();
        Sfdc_EDW_List.add(temperoryList[0].SFDCObject__c);
        Sfdc_EDW_List.add(temperoryList[0].EDWTable__c);
        return Sfdc_EDW_List;  
    }  
    
    
    
    
     //This returns the corresponding EDW Table Name for a particular SFDC object  
 	@AuraEnabled
    public static List<P2RETL_SFDC_Object_to_EDWTableMapping__mdt> getAllOracleSFDCMapping(){
        List<P2RETL_SFDC_Object_to_EDWTableMapping__mdt> Sfdc_EDW_List = new List <P2RETL_SFDC_Object_to_EDWTableMapping__mdt>();
        String FinalQuery='SELECT EDWTable__c,SFDCObject__c,Application_Type__c FROM P2RETL_SFDC_Object_to_EDWTableMapping__mdt';      
		Sfdc_EDW_List=Database.query(FinalQuery);
        return Sfdc_EDW_List;  
    }  
    
                  
 
                    

}