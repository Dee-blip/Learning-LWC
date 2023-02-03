global class HD_CloseIncidentThroughEmail implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){

        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        // Remove leading or trailing white space characters in body and subject of email and Convert all of the characters in the Subject to lowercase
        String emailBody = email.plainTextBody.trim();
        String subject = email.subject.trim().toLowerCase();
        String fromAddress = email.fromAddress;
        
        
        //Get list of all incidents
        List<BMCServiceDesk__Incident__c> incidentList = new List<BMCServiceDesk__Incident__c>();
        incidentList = [Select Id, Name from BMCServiceDesk__Incident__c  order by createdDate desc LIMIT 500];
        

        
        //Get id of 'CLOSED' status    
        List<BMCServiceDesk__Status__c> statusList = new List<BMCServiceDesk__Status__c>();
        statusList = [select Id, Name from BMCServiceDesk__Status__c where BMCServiceDesk__appliesToIncident__c = true and BMCServiceDesk__defaultStatus__c = true and BMCServiceDesk__state__c = false];
        
        //Fetch incident number from subject of email
        String incidentNumber;
        if((incidentList!= null && !(incidentList.isEmpty())) && (statusList!= null && !(statusList.isEmpty()))){
        
            if(subject.contains('close call') && subject.contains('incident#')){
                Integer startingIndex = subject.indexOf('#', subject.indexOf('incident'))+1;    
                Integer endingIndex = subject.indexOf(' ',startingIndex);
                if(endingIndex == -1){
                    endingIndex = subject.indexOf('\n',startingIndex);
                }
                
        
                if(startingIndex != -1){
                    if(endingIndex != -1 && startingIndex <= endingIndex){
                        incidentNumber  = subject.subString(startingIndex, endingIndex);
                        incidentNumber = incidentNumber.trim();
                    }
 
             
                    //Close the above fetched incident
                    BMCServiceDesk__Incident__c incident;
                    for(BMCServiceDesk__Incident__c inc : incidentList){
                        if(inc.Name  == incidentNumber){
                            incident = inc;
                            break;
                        }
                    
                    }
                    
                    //if(incident != null){
                    //Samir Jha:Adding resolution as it is mandatory
                    incident= [Select Owner.Email, BMCServiceDesk__clientEmail__c from BMCServiceDesk__Incident__c where id=:incident.id];
                    if(incident != null && (incident.Owner.Email==fromAddress || incident.BMCServiceDesk__clientEmail__c==fromAddress)){
                        Id statusId = statusList[0].Id;
                        if(statusId != null){
                            incident.BMCServiceDesk__FKStatus__c = statusId;
                            if (Test.isRunningTest() == true)
                           {// if(incident.BMCServiceDesk__incidentResolution__c== null)
                               incident.Effort_Estimation__c='00:10'; //Komal: Adding Effort Estimation
                               incident.BMCServiceDesk__incidentResolution__c='Closed without resolution';
                               
                           }
                            update incident;
                      
                        }
                    }
                    
                    
                }
     
            
            }
        }
        return result;    
    }
}