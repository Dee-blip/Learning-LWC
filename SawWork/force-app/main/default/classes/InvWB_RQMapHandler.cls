/**
 * @description       : FFPSA-558
 * @author            : Sujay
 * date               : October 2018
 * @last modified on  : 07-12-2021
**/

public without sharing class InvWB_RQMapHandler {

    public Static Boolean firstRun = true;
    Id servicesSlotstypeId = Schema.SObjectType.Inv_Workbox_Region_Quarter_Mapping__c.getRecordTypeInfosByName().get('Global Services').getRecordTypeId();
    //increase/decrease the Available slots if there is change in Allocated slots
    public void rQMapRecordsBeforeInsert(List<Inv_Workbox_Region_Quarter_Mapping__c> rqMapList){
        
        for(Inv_Workbox_Region_Quarter_Mapping__c rqMap : rqMapList){
            if(rqMap.Year__c != NULL && (integer.valueof(rqMap.Year__c) < Date.today().year())){
            	rqMap.addError('You can not create Slot values for the past');
            }
            
            rqMap.UniqueRegions__c = rqMap.Region__c +'&'+ rqMap.Year__c +'&'+ servicesSlotstypeId;   

            if(rqMap.Planned_Hours__c != NULL && rqMap.Planned_Hours__c > 0.0){
                rqMap.Remaining_Planned_Hours__c =  rqMap.Planned_Hours__c; 
            }
            if(rqMap.UnPlanned_Hours__c != NULL && rqMap.UnPlanned_Hours__c > 0.0){
                rqMap.Remaining_Unplanned_Hours__c =  rqMap.UnPlanned_Hours__c; 
            }
            if(rqMap.Product_Platform_Hours__c != NULL && rqMap.Product_Platform_Hours__c > 0.0){
                rqMap.Remaining_Product_Platform_Hours__c =  rqMap.Product_Platform_Hours__c; 
            }
            // if(rqMap.Allocated_for_Quarter_4__c != NULL && rqMap.Allocated_for_Quarter_4__c > 0.0){
            //     rqMap.Quarter_4__c =  rqMap.Allocated_for_Quarter_4__c; 
            // }
            
        }
    }
    
    
    //increase/decrease the Available slots if there is change in Allocated slots
    public void rQMapRecordsBeforeUpdate(Map<Id, Inv_Workbox_Region_Quarter_Mapping__c> newRQMap, Map<Id, Inv_Workbox_Region_Quarter_Mapping__c> oldRQMap){
        if(firstRun){
            firstRun = false;
            for(Id rqId : newRQMap.keySet())
            {
                Decimal diffhours = 0.0;
                
                if(newRQMap.get(rqId).Region__c !=NULL && newRQMap.get(rqId).Region__c != oldRQMap.get(rqId).Region__c)
                {
                    newRQMap.get(rqId).UniqueRegions__c = newRQMap.get(rqId).Region__c +'&'+ newRQMap.get(rqId).Year__c +'&'+ servicesSlotstypeId;
                }            
                
                if(newRQMap.get(rqId).year__c != NULL && (newRQMap.get(rqId).year__c != oldRQMap.get(rqId).year__c  || 
                                    newRQMap.get(rqId).Region__c != oldRQMap.get(rqId).Region__c ||
                                    newRQMap.get(rqId).Planned_Hours__c != oldRQMap.get(rqId).Planned_Hours__c ||
                                        newRQMap.get(rqId).UnPlanned_Hours__c != oldRQMap.get(rqId).UnPlanned_Hours__c || 
                                         newRQMap.get(rqId).Product_Platform_Hours__c != oldRQMap.get(rqId).Product_Platform_Hours__c )  && integer.valueof(oldRQMap.get(rqId).year__c) < (Date.today().year()) ){
                    newRQMap.get(rqId).addError('Past Slot values can not be editable');
                }
                else 
                {
                    if(newRQMap.get(rqId).Planned_Hours__c != NULL && newRQMap.get(rqId).Planned_Hours__c != oldRQMap.get(rqId).Planned_Hours__c){                    
                        diffhours = newRQMap.get(rqId).Planned_Hours__c - (oldRQMap.get(rqId).Planned_Hours__c == NULL ? 0.0 : oldRQMap.get(rqId).Planned_Hours__c);
                        newRQMap.get(rqId).Remaining_Planned_Hours__c = (newRQMap.get(rqId).Remaining_Planned_Hours__c == NULL ? 0.0 : newRQMap.get(rqId).Remaining_Planned_Hours__c) + diffhours;
                    }
                    if(newRQMap.get(rqId).UnPlanned_Hours__c != NULL && newRQMap.get(rqId).UnPlanned_Hours__c != oldRQMap.get(rqId).UnPlanned_Hours__c){
                        diffhours = newRQMap.get(rqId).UnPlanned_Hours__c - (oldRQMap.get(rqId).UnPlanned_Hours__c == NULL ? 0.0 : oldRQMap.get(rqId).UnPlanned_Hours__c);
                        newRQMap.get(rqId).Remaining_Unplanned_Hours__c = (newRQMap.get(rqId).Remaining_Unplanned_Hours__c == NULL ? 0.0 : newRQMap.get(rqId).Remaining_Unplanned_Hours__c) + diffhours;
                    }
                    if(newRQMap.get(rqId).Product_Platform_Hours__c != NULL && newRQMap.get(rqId).Product_Platform_Hours__c != oldRQMap.get(rqId).Product_Platform_Hours__c){
                        diffhours = newRQMap.get(rqId).Product_Platform_Hours__c - (oldRQMap.get(rqId).Product_Platform_Hours__c == NULL ? 0.0 : oldRQMap.get(rqId).Product_Platform_Hours__c);
                        newRQMap.get(rqId).Remaining_Product_Platform_Hours__c = (newRQMap.get(rqId).Remaining_Product_Platform_Hours__c == NULL ? 0.0 : newRQMap.get(rqId).Remaining_Product_Platform_Hours__c) + diffhours;
                    }
                    // if(newRQMap.get(rqId).Allocated_for_Quarter_4__c != NULL && newRQMap.get(rqId).Allocated_for_Quarter_4__c != oldRQMap.get(rqId).Allocated_for_Quarter_4__c){
                    //     diffhours = newRQMap.get(rqId).Allocated_for_Quarter_4__c - (oldRQMap.get(rqId).Allocated_for_Quarter_4__c == NULL ? 0.0 : oldRQMap.get(rqId).Allocated_for_Quarter_4__c);
                    //     newRQMap.get(rqId).Quarter_4__c = (newRQMap.get(rqId).Quarter_4__c == NULL ? 0.0 : newRQMap.get(rqId).Quarter_4__c) + diffhours;
                    // }
                }
        	}
        }
        
    }
}