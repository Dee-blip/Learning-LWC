global class HD_Resolved_State_to_Closed implements Schedulable{

    global void execute(SchedulableContext ctx){
        try
        {
            DateTime myDateTime = DateTime.now();
			String dayOfWeek = myDateTime.format('E');
            system.debug(dayOfWeek);
            
            date statusstartdate = date.today() - 7;
            
            
            Integer numberofdaysforclose = 3;
            
            HD_Resolved_Status_Settings__c custom_settings = HD_Resolved_Status_Settings__c.getInstance('start_date');
            if(custom_settings != null)          
            statusstartdate= custom_settings.date__c;
           
            HD_Resolved_Status_Settings__c custom_settings1 = HD_Resolved_Status_Settings__c.getInstance('days_from_resolved_to_closed_status');
            if(custom_settings1 != null)          
            numberofdaysforclose= (Integer)custom_settings1.value__c;
            
            if(dayOfWeek == 'Sat' || dayOfWeek == 'Sun' || dayOfWeek == 'Mon' || dayOfWeek == 'Tue')
                numberofdaysforclose += 2;
                
            system.debug('custom settings' + statusstartdate + numberofdaysforclose);
            //numberofdaysforclose = -1;
            statusstartdate -= 3;
            
        date statuschangedate = (date.today() - numberofdaysforclose);
       
            
        /*List<BMCServiceDesk__Incident__c> incidentList = [select Id, BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where
                                                          BMCServiceDesk__FKStatus__r.Name = 'RESOLVED' and RecordType.Name != 'Service Incident' and HD_Incident_Group__c = 'Corp IT'
                                                         and BMCServiceDesk__StatusChangeDate__c >= :statusstartdate and BMCServiceDesk__StatusChangeDate__c < :statuschangedate 
                                                          order by BMCServiceDesk__StatusChangeDate__c desc];
		*/
        string ClosedStateId = [select Id from BMCServiceDesk__Status__c where Name='CLOSED'][0].Id;
        
        String StatusName = 'RESOLVED';
        String RecordType = 'Service Incident';
        String IncidentGroup = 'Corp IT';
            
        String q='select Id, BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where BMCServiceDesk__FKStatus__r.Name = \'RESOLVED\' and RecordType.Name != \'Service Incident\' and HD_Incident_Group__c = \'Corp IT\' and BMCServiceDesk__StatusChangeDate__c = LAST_N_DAYS:14 and BMCServiceDesk__StatusChangeDate__c < LAST_N_DAYS:'+numberofdaysforclose;
        
        HD_Batchable_Resolved_State_to_Closed batch=new HD_Batchable_Resolved_State_to_Closed(q, ClosedStateId); 
         System.debug('before batch');
				Database.executeBatch(batch, 1);
         System.debug('after batch');

            
        /*for(BMCServiceDesk__Incident__c incident :  incidentList)
        {            
            try
            {
               incident.Force_Change_Status__c = true;
            incident.BMCServiceDesk__FKStatus__c = ClosedStateId;
                
            //update incident;           
                //incident.Force_Change_Status__c = false;
                //update incident;
            }
            catch (Exception e)
            {
                System.debug(e.getMessage());
            }
        }*/
            //update incidentList;
            //System.debug('update incident list' + incidentList);
        }
        catch (Exception e)
        {
            System.debug(e.getMessage());
        }
        
    }
}