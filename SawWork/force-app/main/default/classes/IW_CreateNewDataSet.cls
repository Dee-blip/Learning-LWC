/**
 * @description       : FFPSA-558
 * @author            : Sujay 
 * date               : October 2018
 * @last modified on  : 07-12-2021
**/

public class IW_CreateNewDataSet {
    
    @AuraEnabled
    public static String createRegionRecs(){
    
    String nextYear = string.valueof(Date.today().year() + 1);
    //Id geoSlotstypeId = Schema.SObjectType.Inv_Workbox_Region_Quarter_Mapping__c.getRecordTypeInfosByName().get('Security Slot').getRecordTypeId();
    //Id regSlotstypeId = Schema.SObjectType.Inv_Workbox_Region_Quarter_Mapping__c.getRecordTypeInfosByName().get('Discrete Slot').getRecordTypeId();
    Id servicesSlotstypeId = Schema.SObjectType.Inv_Workbox_Region_Quarter_Mapping__c.getRecordTypeInfosByName().get('Global Services').getRecordTypeId();


    String message = '';
    List<Inv_Workbox_Region_Quarter_Mapping__c> regMapList = new List<Inv_Workbox_Region_Quarter_Mapping__c>();
    //for creating Geos/Regions slots for present year
    List<Inv_Workbox_Region_Quarter_Mapping__c> regMapListPrestYear = new List<Inv_Workbox_Region_Quarter_Mapping__c>();
    List<pse__Region__c> allreg = [SELECT Id , Name 
                                    FROM pse__Region__c 
                                    WHERE psa_old__c = FALSE                                          
                                    AND (Name LIKE '% (Region)')
                                    //AND (NOT Name Like '% _Old%')
                                    AND (NOT Name Like '% _Old')
                                    AND (NOT Name Like '% _Old (%')];
        
        System.debug('allreg ::: '+ allreg.size());
        for(pse__Region__c reg : allreg ){
            Inv_Workbox_Region_Quarter_Mapping__c rqMap = new Inv_Workbox_Region_Quarter_Mapping__c();
            rqMap.Region__c = reg.Id;
            
            rqMap.UnPlanned_Hours__c 			= 0;
            rqMap.Product_Platform_Hours__c 	= 0;
			rqMap.Planned_Hours__c 				= 0;
            
            rqMap.Year__c = nextYear; 
            //rqMap.RecordTypeId = reg.Name.containsIgnoreCase('Geography') ?  geoSlotstypeId : regSlotstypeId ;
            rqMap.RecordTypeId = servicesSlotstypeId;
            rqMap.UniqueRegions__c = rqMap.Region__c +'&'+nextYear +'&'+ servicesSlotstypeId;
            regMapList.add(rqMap);

            //Create Object for present year
            Inv_Workbox_Region_Quarter_Mapping__c rqMap2 = new Inv_Workbox_Region_Quarter_Mapping__c();
            rqMap2.Region__c = reg.Id;
            rqMap2.UnPlanned_Hours__c 			= 0;
            rqMap2.Product_Platform_Hours__c 	= 0;
			rqMap2.Planned_Hours__c 			= 0;
            rqMap2.RecordTypeId = servicesSlotstypeId;
            //rqMap2.RecordTypeId = reg.Name.containsIgnoreCase('Geography') ?  geoSlotstypeId : regSlotstypeId ;
            rqMap2.Year__c = string.valueof(Date.today().year()); 
            rqMap2.UniqueRegions__c = rqMap2.Region__c +'&'+string.valueof(Date.today().year()) +'&'+ servicesSlotstypeId;
            regMapListPrestYear.add(rqMap2);
        }
        try{
            if(!regMapList.isEmpty()){
                Database.SaveResult[] lsr = Database.insert(regMapList, false);
                integer i = 0;
                for(Database.SaveResult ds : lsr){
                    if(ds.isSuccess()){
                        i++; 
                    }
                    System.debug('ds :::::::::::::::::::::::::: '+ ds + i);
                }
                message = i > 0 ? 'Success : Record Count is '+ i : 'Data Set already created';
                System.debug('message :: Data Set'+ message+ regMapList);

            }

            if(!regMapListPrestYear.isEmpty()){
                Database.insert(regMapListPrestYear, false);
            }
        }
        catch(Exception e){
            System.debug('Exception While creating new data set ::'+ e.getDmlMessage(0));
            message = 'Exception While creating new data set :: ' +e.getDmlMessage(0);
            
        }
        return message;
    }

}