public class DeliveryVendorTriggerClass{

public static void UpdateTrafficList(set<id> TrafficIDs){

    list<Traffic_Share__c> TrafficShareRecords = new list<Traffic_Share__c>();
    
    TrafficShareRecords = [SELECT id,P_B_Month_Modified_Date__c FROM Traffic_Share__c WHERE ID IN : TrafficIDs];
     for(Traffic_Share__c trafficRec: TrafficShareRecords){
             
                  trafficRec.P_B_Month_Modified_Date__c = date.today();
                   
    }
    if(TrafficShareRecords.size()>0)
    {
           GsmUtilClass.doDatabaseUpdate(TrafficShareRecords,'DeliveryVendorTriggerClass','UpdateTrafficList');
    }
}


}