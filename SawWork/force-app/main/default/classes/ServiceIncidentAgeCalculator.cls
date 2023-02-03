/* Author : Jay
 * date : 19-feb-2015
 * Purpose: CR 2627751 and CR  2824410 */
public class ServiceIncidentAgeCalculator {

    public ServiceIncidentAgeCalculator(){
    }
    
    public static void calculateServiceIncidentAge(Map<id,BMCServiceDesk__Incident__c> oldServiceIncidentMap,
                                                   Map<id,BMCServiceDesk__Incident__c> newServiceIncidentMap){
    	set<Id> serviceIncidentStatusChangeIdList = new set<Id>();
        Id serviceIncidentRecordId =  getServiceIncidentRecordType();                                              
        for(Id incidentId :oldServiceIncidentMap.keySet()){
            BMCServiceDesk__Incident__c oldIncident = oldServiceIncidentMap.get(incidentId);
            BMCServiceDesk__Incident__c newIncident = newServiceIncidentMap.get(incidentId);
        	/* intention of this class is to know how long service incident was with particuar status or
        	 * with particular owner. owner might keep service incident with them for long time and after some time
        	 * they will just owner. so its necessary to track how long it was with owner even though status was not changed.
        	 * If status change happens ,we also need to track which owner kept that status for how long.
        	 * we need to calculate this logic for SERVICE INCIDENT record type only
        	 */
            if (oldIncident.recordtypeid == serviceIncidentRecordId){
                //process logic only when status changes
                if (oldIncident.BMCServiceDesk__FKStatus__c <> newIncident.BMCServiceDesk__FKStatus__c){
                    serviceIncidentStatusChangeIdList.add(oldIncident.id);
                }
                //change of owner. to know how much duration it was with owner
                else if(oldincident.OwnerId <> newincident.ownerId){
                    serviceIncidentStatusChangeIdList.add(oldIncident.id);
                }
            }
        }
        if (serviceIncidentStatusChangeIdList.size() > 0){ 
        	insertServiceDurationObject(serviceIncidentStatusChangeIdList,oldServiceIncidentMap,newServiceIncidentMap);                                                  
        }                                                
    }
    
    private static Id getServiceIncidentRecordType(){
        Schema.DescribeSObjectResult R = BMCServiceDesk__Incident__c.SObjectType.getDescribe();
		List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
		for(schema.RecordTypeInfo r1:rt){
            if (r1.getname() == 'Service Incident'){
                return r1.getRecordTypeId();
            }
    	}
        return null;
    }
    
    public static void startCapturingStatusAge(Map<id,BMCServiceDesk__Incident__c> newIncidentMap){
    	List<Service_Incident_age_by_status__c> serviceIncidentAgeList = new List<Service_Incident_age_by_status__c>();
        Id serviceIncidentRecordId =  getServiceIncidentRecordType();  
        for(Id incidentId :newIncidentMap.keySet()){
        	BMCServiceDesk__Incident__c newIncident = newIncidentMap.get(incidentId);
            if (newIncident.recordtypeid == serviceIncidentRecordId) {
            	Service_Incident_age_by_status__c c = new Service_Incident_age_by_status__c();
            	c.fromStatus__c = newincident.BMCServiceDesk__FKStatus__c;
            	c.User__c = newincident.ownerId;
            	c.incident__c = newIncident.id;
            	c.openRecord__c  = newincident.id;
            	serviceIncidentAgeList.add(c);
            }
        }
        if(serviceIncidentAgeList.size() > 0){
             upsert serviceIncidentAgeList openrecord__c;                                             
        }                                              
   }

    public static void insertServiceDurationObject(set<id> toProcessIncidentIdList,
                                                  map<id,BMCServiceDesk__Incident__c> oldIncidentMap,
                                                  map<id,BMCServiceDesk__Incident__c> newIncidentMap) {
   		map<id,datetime> lastStatusCreatedDate = new map<id,datetime>();
        List<Service_Incident_age_by_status__c> openRecordServiceList = new List<Service_Incident_age_by_status__c>();
        //openRecord__c
        /* when status changes , we need to calculate time difference previous status change
         * and current change. even when owner changes , difference between previous update
         * and current date will give duration of service incident holded.
         * OWNER and STATUS fields are tracked and tracking is in standard HISTORY object.
         */ 
   		List<BMCServiceDesk__Incident__History> incidentHistoryList = [SELECT parentId,
                                                                       		  createdDate,
                                                                       		  field		
                                                                       FROM BMCServiceDesk__Incident__History 
                                                                       WHERE parentId in :toProcessIncidentIdList
                                                                       AND field in ('Owner','BMCServiceDesk__FKStatus__c')
                                                                       ORDER BY createddate DESC ];
        for(BMCServiceDesk__Incident__History bmcHist:incidentHistoryList){
            if (!lastStatusCreatedDate.containsKey(bmcHist.parentId)){
                lastStatusCreatedDate.put(bmcHist.parentId,bmcHist.CreatedDate);
            }
        }
        //loop through , calcualate time difference between current date and past date
   		List<Service_Incident_age_by_status__c> serviceIncidentAgeList = new List<Service_Incident_age_by_status__c>();
        for(Id incidentId :oldIncidentMap.keySet()){
            //only if status changed or owner changed , process this
            if(toProcessIncidentIdList.contains(incidentId)){
                BMCServiceDesk__Incident__c oldIncident = oldIncidentMap.get(incidentId);
                BMCServiceDesk__Incident__c newIncident = newIncidentMap.get(incidentId);
                Service_Incident_age_by_status__c c = new Service_Incident_age_by_status__c();
                if (lastStatusCreatedDate.get(incidentId) != null){
                    datetime lastStatusUpdatedDate = lastStatusCreatedDate.get(incidentId);
                    c.durationInSeconds__c = datetime.now().gettime() - lastStatusUpdatedDate.gettime();
                }
                else {
                    c.durationInSeconds__c = datetime.now().gettime() - oldIncident.CreatedDate.gettime();
                }
                c.fromStatus__c = oldincident.BMCServiceDesk__FKStatus__c;
                c.toStatus__c = newincident.BMCServiceDesk__FKStatus__c;
                c.User__c = oldincident.ownerId;
                c.incident__c = oldIncident.id;
                serviceIncidentAgeList.add(c);
                Service_Incident_age_by_status__c v = new Service_Incident_age_by_status__c();
                v.fromstatus__c = newIncident.BMCServiceDesk__FKStatus__c;
                v.toStatus__c = null;
                v.user__c = newIncident.ownerid;
                v.incident__c = oldincident.id;
                v.openRecord__c  = oldincident.id;
                openRecordServiceList.add(v); 
            }
        }
        if(serviceIncidentAgeList.size() > 0){
             insert serviceIncidentAgeList;                                             
        }
        if(openRecordServiceList.size() > 0){
            upsert openRecordServiceList openrecord__C;                                               
        }
   }
    
}