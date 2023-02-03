/*
Initial Developer : shegade
Details: Auotomatic assignement of helpdesk tickets to the resources at defined interval of time
Related objects: OpsResource__c, ShitftSchedule__c, Threshold__c,HD_Round_Robin_error_log__c,OpsResource_Shift_Junction__c
Related classes: HD_AutomatedTicketAssignmentException,HD_BatchableAutomatedTicketAssignment,HD_ScheduledAutomatedTicketAssignment
Test class: HD_Test_AutomatedTicketAssignment
*/

/*
Change List
Developer Name           Date            Jira number
shegade                  01/10/2019      PRTORES-1455,PRTORES-1454,PRTORES-1453
aneesh budnar            04/08/2020      PRTORES-1810
Arihant Jain             15/12/2020      PRTORES-2023
Arihant Jain             18/12/2020      PRTORES-2026
*/

public class HD_AutomatedTicketAssignment {

    // variables for job Time deatils
    private static integer jobWeekNumber;
    private static string jobDayName;
    private static string dateString;
    private static string jobHour;
    private static string jobDate;
    
    //variables for queue
    private static list<string> queueNameList = new list<string>();
    private static map<string, Id> queueNameIdmap = new map<string, Id>();
    private static map<string, Threshold__c> queueThresholdMap = new map<string, Threshold__c>();
    private static list<Id> queueIdsList = new list<Id>();
    
    //variables for open incidents.
    private static map<Id,List<BMCServiceDesk__Incident__c>> queueIncidentMap = new map<Id,List<BMCServiceDesk__Incident__c>>();

    //variable for shifts
    private static set<Id> shiftsResourceIdSet = new set<Id>();
    private static set<Id> allShiftResourceIdSet = new set<Id>();
    
    //variables for the resource
    private static List<OpsResource__c> availableResourceList = new List<OpsResource__c>();
    private static Map<string,List<string>> outOfOfficeResourceMap = new Map<string,List<string>>();
    private static Map<String,List<OpsResource__c>> queueResourceMap = new map<String,List<OpsResource__c>>();

    //ticket allocation variables
    private static map<Id,Id> incidentOwnerMap = new map<Id,Id>();
    private static set<string> assignedResourceSet = new set<string>();

    //variable for incident keywors
    private static map<Id, string> incidentKeywordsMap = new map<Id,string>();

    //variable for resource specialization
    private static map<Id, string[]> resourceSpecializationMap = new map<Id,string[]>();

    //variables for email
    private static map<String,String> emailMap = new map<string,string>();

    //custom setting
    private static map<string, HD_Round_Robin_setting__c> customSetting = new map<string, HD_Round_Robin_setting__c>();
    private static string resetTime = '06';
    private static string resetDay = 'Monday';
 
    //BEGIN: This method resets the WeekTickets__c field at 06AM MONDAY
    private static void resetTicketsAssigned(){
        
        List<OpsResource__c> allResourceList = [SELECT id,WeekTickets__c,TicketsAssigned__c FROM OpsResource__c LIMIT 500];

        for(OpsResource__c resource: allResourceList ){

            if(jobHour == resetTime && jobDayName.containsIgnoreCase(resetDay)){
                resource.WeekTickets__c = 0;
                resource.TicketsAssigned__c = 0;
            }
            else if(jobHour == resetTime){
                resource.TicketsAssigned__c = 0;
            } 

            resource.JobTickets__c = 0;
        }
        update allResourceList;
        
    } 
    
    // get custom settings
    private static void getCustomSetting(){

        customSetting = HD_Round_Robin_setting__c.getall();

        if(customSetting.containsKey('resetTime')){
            resetTime = customSetting.get('resetTime').HD_Value__c;
        }
        if(customSetting.containsKey('resetDay')){
            resetDay =  customSetting.get('resetDay').HD_Value__c;
        }


    }
    
    //BEGIN: This method sets the the timing details for the job
    private static void setJobTimeDetails(){
        try{
            datetime jobDateTime = datetime.now();
            String timeZoneName = [SELECT Label,instanceName__c FROM HD_Instance__mdt where Label = 'Time Zone Name' limit 1].instanceName__c;
            string jobDateTimeInIST = jobDateTime.format('dd/MM/yyyy HH:mm:ss EEEE W',timeZoneName); //E - day(e.g monday), W - week number in the month, HH - 24Hr format
            
            string[] dateTimeArray = jobDateTimeInIST.split(' ', 4);
            jobDayName = dateTimeArray[2];
            jobWeekNumber = integer.valueOf(dateTimeArray[3]);
            
            string timeString = dateTimeArray[1];
            string[] timeArray = timeString.split(':', 3);
            //jobRunHour = integer.valueOf(timeArray[0]);
            jobHour = timeArray[0];
            
            dateString = dateTimeArray[0];
            string[] dateArray = dateString.split('/',3);
            jobDate = dateArray[0];

            system.debug('job week number: ' + string.valueOf(jobWeekNumber) + ', job day name: ' + jobDayName + ', job run hour: ' + jobHour + ', jobDate: ' + jobDate);
        }
        catch(Exception e){
           system.debug(e.getMessage());
           throw new HD_AutomatedTicketAssignmentException('Error in setJobTimeDetails method',e);
        }
    }
    //END

    //Added checkbox Run_On_Weekends__c on threshold for job to allocate on Weekends as per Story PRTORES-2026
    //BEGIN: To check if the queue is allowed to allocate ticket on weekends
    private static boolean jobRunCheckOnWeekends(Threshold__c thres){
        try{
            return !(((jobDayName.equalsIgnoreCase('Saturday') && Integer.valueOf(jobHour) > 5) || jobDayName.equalsIgnoreCase('Sunday') || (jobDayName.equalsIgnoreCase('Monday') && Integer.valueOf(jobHour) < 6)) && !thres.Run_On_Weekends__c);      //Correcting the run on weekend logic PRTORES-2311
        }
        catch(Exception e){
            system.debug(e.getMessage());
            throw new HD_AutomatedTicketAssignmentException('Error in jobRunCheckOnWeekends method',e);
        }
    }
    //END
    //BEGIN: retrive active queuename from the the threshold object which run in current job
    private static void getQueueDetails(){
        list<Threshold__c> thresholdList = new list<Threshold__c>();
        list<Group> queueGroupList = new list<Group>();
        try{
            
            thresholdList = [SELECT Is_Active__c, Max_tickets_per_job__c,Job_Run_Time__c, Max_tickets_per_resource__c, Queue_to_use__c, Max_tickets_per_week__c, Interval__c,Team_Email__c,Cutoff__c,Job_frequency__c,Assign_Service_Request__c,Run_On_Weekends__c FROM Threshold__c WHERE Is_Active__c = true LIMIT 50];
            for( Threshold__c threshold: thresholdList){
                string[] jobTimes = threshold.Job_Run_Time__c.split(',');
                if(jobTimes.contains(jobHour) && jobRunCheckOnWeekends(threshold)){ // checking whether the queue is set to run at current hour
                    system.debug(threshold.Queue_to_use__c);
                    queueNameList.add(threshold.Queue_to_use__c);
                    queueThresholdMap.put(threshold.Queue_to_use__c, threshold);
                }
            }
            if(queueNameList.isEmpty()){
                throw new HD_AutomatedTicketAssignmentException('NO AVAILABLE QUEUE');
            }
            queueGroupList = [SELECT Id, Name FROM Group WHERE Name IN :queueNameList AND Type = 'Queue' LIMIT 50];
            for(Group queueGroup: queueGroupList){
               	queueIdsList.add(queueGroup.Id);
                queueNameIdmap.put(queueGroup.Name,queueGroup.Id);
            }
            //debug message

            system.debug('queue names: ' + queueIdsList);
        }
        catch(Exception e){
            system.debug(e.getMessage());
            throw new HD_AutomatedTicketAssignmentException('Error in getQueueDetails method',e);
        }
    }
    //END
    //BEGIN: creates a string contaning the category and the parent tree of the incidnet
    private static void generateIncidentKeywords(BMCServiceDesk__Incident__c incident){

        string tempString = '';
        tempString += incident.BMCServiceDesk__Category_ID__c + ',' + incident.HD_Parent_Tree__c;
        incidentKeywordsMap.put(incident.Id,tempString);

    }
    //END
    //BEGIN: This method creates the open Incidents
    private static void getOpenIncidents(){
        try{

            List<string> ticketStatus = new List<string>{'REASSIGNED','UNASSIGNED','REOPENED'};
            List<BMCServiceDesk__Incident__c> opsIncidents = new List<BMCServiceDesk__Incident__c>();
            Id opsID;
            if(queueNameList.contains('EAE Ops')){
                Id ops = queueNameIdmap.get('EAE Ops');
                Integer opsIndex = queueIdsList.Indexof(ops);
                opsID = queueIdsList.remove(opsIndex);
                opsIncidents = [SELECT Id,Name,OwnerId,BMCServiceDesk__FKStatus__c,isAssingedByRoundRobin__c,BMCServiceDesk__Status_ID__c,BMCServiceDesk__state__c,BMCServiceDesk__FKPriority__c,BMCServiceDesk__Category_ID__c,HD_Parent_Category__c,HD_Parent_Tree__c,Launch_console__c,BMCServiceDesk__isServiceRequest__c,Owner.Name FROM BMCServiceDesk__Incident__c WHERE (BMCServiceDesk__Status_ID__c ='REASSIGNED' OR BMCServiceDesk__Status_ID__c ='UNASSIGNED') AND OwnerId = :opsID AND BMCServiceDesk__FKCategory__r.BMCServiceDesk__inactive__c = false AND BMCServiceDesk__FKCategory__r.RA_Category_Group__c <> 'RESTRICTED PARENT'  ORDER BY CreatedDate ASC LIMIT 500];
            }
        	List<BMCServiceDesk__Incident__c> openIncidentsList = [SELECT Id,Name,OwnerId,BMCServiceDesk__FKStatus__c,isAssingedByRoundRobin__c,BMCServiceDesk__Status_ID__c,BMCServiceDesk__state__c,BMCServiceDesk__FKPriority__c,BMCServiceDesk__Category_ID__c,HD_Parent_Category__c,HD_Parent_Tree__c,Launch_console__c,BMCServiceDesk__isServiceRequest__c,Owner.Name FROM BMCServiceDesk__Incident__c WHERE BMCServiceDesk__Status_ID__c IN :ticketStatus AND OwnerId IN :queueIdsList AND BMCServiceDesk__FKCategory__r.BMCServiceDesk__inactive__c = false AND BMCServiceDesk__FKCategory__r.RA_Category_Group__c <> 'RESTRICTED PARENT' ORDER BY CreatedDate ASC LIMIT 500];
            if( opsID != null){
                queueIdsList.add(opsID);
            }
            openIncidentsList.addAll(opsIncidents);
            system.debug(queueIdsList);
            system.debug(opsIncidents.size());

            if(openIncidentsList.isEmpty()){
                throw new HD_AutomatedTicketAssignmentException('NO OPEN INCIDENTS');
            }
            for (BMCServiceDesk__Incident__c openIncident : openIncidentsList){

                boolean AssignSR = true;
                boolean isSR = openIncident.BMCServiceDesk__isServiceRequest__c;

                if(openIncident.Owner.Name != null && queueThresholdMap.containsKey(openIncident.Owner.Name)){
                    AssignSR = queueThresholdMap.get(openIncident.Owner.Name).Assign_Service_Request__c;
                }

                generateIncidentKeywords(openIncident);
                if(queueIncidentMap.containsKey(openIncident.ownerId)){
                    if(!(isSR == true && AssignSR == false)){
                    queueIncidentMap.get(openIncident.ownerId).add(openIncident);
                    }//if the ownerId alredy exist in the map, add incident to list
                }
                else{
                    //create a new incident list, add it to map against its owner id
                    List<BMCServiceDesk__Incident__c> tempIncidentList = new List<BMCServiceDesk__Incident__c>(); 
                    if(!(isSR == true && AssignSR == false)){
                    tempIncidentList.add(openIncident); 
                    queueIncidentMap.put(openIncident.ownerId,tempIncidentList);
                    }
                }
            }
            system.debug(openIncidentsList.size());//debug message
            system.debug(queueIncidentMap.keySet());
    	}
        catch(Exception e){
            system.debug(e.getMessage());
            throw new HD_AutomatedTicketAssignmentException('Error in getOpenIncidents method',e);
        }
    }
    //END
    //BEGIN: select the the shift defined for the perticular job run time.
    /*private static void setTheShifts(){

        string weekNumberSearch = '%' + jobWeekNumber + '%';
        string weekDaySearch = '%' + jobDayName + '%';
        string assignmentTimeSearch = '%' + jobHour + '%';

        try{
            List<OpsResource_Shift_Junction__c> shiftsResourceList = [SELECT OpsResource__r.Id ,ShiftSchedule__r.Is_Available__c, ShiftSchedule__r.Login_time__c, ShiftSchedule__r.Logout_Time__c,ShiftSchedule__r.Assignment_time__c  FROM OpsResource_Shift_Junction__c WHERE ShiftSchedule__r.Week_Number__c LIKE :weekNumberSearch AND ShiftSchedule__r.Days__c LIKE :weekDaySearch AND ShiftSchedule__r.Assignment_time__c LIKE :assignmentTimeSearch AND ShiftSchedule__r.Is_Available__c = true];
            system.debug('shift count: ' + shiftsResourceList.size());
            for(OpsResource_Shift_Junction__c shiftResource: shiftsResourceList){
                shiftsResourceIdSet.add(shiftResource.OpsResource__r.Id);
            }
            system.debug(shiftsResourceIdSet);
        }
        catch(Exception e){
            system.debug(e.getMessage());
            throw new HD_AutomatedTicketAssignmentException('Error in setTheShifts method',e);
        }

    }*/
    //set the shift new approach
    private static void setTheShiftsNew(){

        try{
            List<OpsResource_Shift_Junction__c> shiftsResourceList = [SELECT OpsResource__r.Id ,ShiftSchedule__r.Is_Available__c, ShiftSchedule__r.Login_time__c, ShiftSchedule__r.Logout_Time__c,ShiftSchedule__r.Assignment_time__c,ShiftSchedule__r.Week_Number__c,ShiftSchedule__r.Days__c  FROM OpsResource_Shift_Junction__c WHERE ShiftSchedule__r.Is_Available__c = true];
            system.debug('shift count: ' + shiftsResourceList.size());
            for(OpsResource_Shift_Junction__c shiftResource: shiftsResourceList){
                allShiftResourceIdSet.add(shiftResource.OpsResource__r.Id);
                if(shiftResource.ShiftSchedule__r.Assignment_time__c.contains(jobHour)&&shiftResource.ShiftSchedule__r.Week_Number__c.contains(String.valueOf(jobWeekNumber))&&shiftResource.ShiftSchedule__r.Days__c.containsIgnoreCase(jobDayName)){
                    shiftsResourceIdSet.add(shiftResource.OpsResource__r.Id);
                }
            }
            system.debug(shiftsResourceIdSet);
        }
        catch(Exception e){
            system.debug(e.getMessage());
            throw new HD_AutomatedTicketAssignmentException('Error in setTheShifts method',e);
        }

    }
    //END
    //BEGIN: To check if the resource is availble or out of office
    private static boolean checkAvailability(OpsResource__c resource){

        string[] outOfOfficeDates;

        try{
            if(resource.Out_of_office_Date__c != null){
                outOfOfficeDates = resource.Out_of_office_Date__c.split(',');
                if(outOfOfficeDates.contains(jobDate)){
                    outOfOfficeResourceMap.get(resource.Team_Name__c).add(resource.ResourceName__c);
                    return false;
                }
            }
            if(resource.Is_Available__c == false){
                outOfOfficeResourceMap.get(resource.Team_Name__c).add(resource.ResourceName__c);
                return false;
            }
            if(resource.Assign_Always__c != true && !(allShiftResourceIdSet.contains(resource.Id))){
                createMailMap(resource.Team_Name__c,'Warning: Please assign an active shift or CHECK "Assign Always" flag for the resource ' + resource.ResourceName__c + '</br>');
                return false;
            }
            if (resource.Assign_Always__c != true  && !(shiftsResourceIdSet.contains(resource.Id))) {
                //createMailMap(resource.Team_Name__c,'Warning: Please assign a shift or CHECK "Assign Always" flag for the resource ' + resource.ResourceName__c + '</br>');
                return false;
            }
            if(!(resource.WeekTickets__c < queueThresholdMap.get(resource.Team_Name__c).Max_tickets_per_week__c)){
                return false;
            }
        }
        catch(Exception e){
            system.debug(e.getMessage());
            throw new HD_AutomatedTicketAssignmentException('Error in checkAvailability method',e);
        }
        return true;
    }
    //END
    //BEGIN: Creates the array of strings which contains the specialization of the resource.
    private static void generateSpecializationKeywords(OpsResource__c resource){

        if(resource.Specializations__c != null && resource.Specializations__c != ''){
        string[] tempString = resource.Specializations__c.split(',');
        resourceSpecializationMap.put(resource.Id,tempString);
    }
    }
    //END
    //BEGIN: select active resources at perticular job run time.
    private static void getActiveResources(){

        try{
            //Added a Order By Clause "TicketsAssigned__c ASC" in below query to enhance the Round Robin logic as per story PRTORES-2023
            List<OpsResource__c> allResourceList = [SELECT Id,ResourceName__c,ShiftTimeCode__c,JobTickets__c,WeekTickets__c,Is_Available__c,Assignee__c,Team_Name__c, TicketsAssigned__c, Specializations__c,ShiftTimeEnd_Code__c, Assign_Always__c,Out_of_office_Date__c  FROM OpsResource__c WHERE Team_Name__c IN :queueNameList ORDER BY TicketsAssigned__c ASC, WeekTickets__c ASC LIMIT 500]; // changed the order from jobtikets to week tickets
            for(string queue: queueNameList){
                List<string> tempList = new List<string>();
                outOfOfficeResourceMap.put(queue,tempList);
            }
            for(OpsResource__c resource: allResourceList){
                //resource.WeekTickets__c = resource.WeekTickets__c + resource.JobTickets__c;
                resource.JobTickets__c = 0;
                if(checkAvailability(resource)){   
                    availableResourceList.add(resource);
                }
            }
            if(availableResourceList.isEmpty()){
                throw new HD_AutomatedTicketAssignmentException('NO AVAILABLE RESOURCE');
            }
            for(OpsResource__c availableResource: availableResourceList){
                generateSpecializationKeywords(availableResource);
                if(queueResourceMap.containsKey(availableResource.Team_Name__c)){
                    queueResourceMap.get(availableResource.Team_Name__c).add(availableResource);
                }
                else{
                    List<OpsResource__c> tempResourceList = new List<OpsResource__c>();
                    tempResourceList.add(availableResource);
                    queueResourceMap.put(availableResource.Team_Name__c,tempResourceList);
                }
            }
            system.debug('availableResource: ' + availableResourceList.size());
            //update allResourceList; updateing the ticket counts
        }
        catch(Exception e){
            system.debug(e.getMessage());
            throw new HD_AutomatedTicketAssignmentException('Error in getActiveResources method',e);
        }
        
    }
    //END
    //BEGIN: compares the resource specialization with the keyword string of the incident
    private static boolean checkSpecialization(string[] resourceSpecialization, string incidentKeywords){

        if(resourceSpecialization == null || incidentKeywords == null){
            return false;
        }
        for(integer i = 0; i<resourceSpecialization.size(); i++){
            if(incidentKeywords.containsIgnoreCase(resourceSpecialization[i])){
                return true;
            }
        }
        return false;
    }

    private static string generateMailContent(map<string,List<BMCServiceDesk__Incident__c>> resourceToIncidentList){

        Set<string> resourceNameList = resourceToIncidentList.keySet();
        string content = '';
        for(string resourceName: resourceNameList){
            List<BMCServiceDesk__Incident__c> incidentList = resourceToIncidentList.get(resourceName);
            content += resourceName + ': ' + incidentList.size() + '</br>';
            for( BMCServiceDesk__Incident__c incident: incidentList ){
                //system.debug(resource.ResourceName__c + ' is assigned to ticket  No' + string.valueof(incident.Id));
                string link = URL.getSalesforceBaseUrl().toExternalForm()+'/'+incident.Id;
                string urlHTML = '<a href= "' + link + '">' + incident.Name +'</a>' + ' : ' + incident.BMCServiceDesk__Category_ID__c +'</br>';
                content+=urlHTML;
            }

        }
        return (content);
    }

    private static void createMailMap(string queueName,string content){

        Threshold__c queue = queueThresholdMap.get(queueName);

        if(queue.Team_Email__c==null||queue.Team_Email__c==''){
            system.debug('No email required');
        }
        else if(emailMap.containsKey(queue.Team_Email__c)){
            string updatedContent = emailMap.get(queue.Team_Email__c);
            updatedContent += content;
            emailMap.put(queue.Team_Email__c,updatedContent);
        }
        else{
            emailMap.put(queue.Team_Email__c,content);
        }
    }


    /*private static void runAssignmentProcess(List<OpsResource__c> resourceList, List<BMCServiceDesk__Incident__c> incidentList, Threshold__c threshold){ 
        Integer interationCount = 0;
        Boolean assignFlag = false;
        try{
            while(incidentList.size()>0){
                BMCServiceDesk__Incident__c incident = incidentList.remove(0);
                interationCount = 0;
                assignFlag = false;
                while(resourceList.size()> 0 && interationCount < resourceList.size()){
                    OpsResource__c resource = resourceList.remove(0);
                    string incidentKeywords = incidentKeywordsMap.get(incident.Id);
                    string[] resourceSpecialization = resourceSpecializationMap.get(resource.Id);
                    if( checkSpecialization(resourceSpecialization,incidentKeywords)){
                        assignFlag = true;
                        incidentOwnerMap.put(incident.Id,resource.Assignee__c);
                        resource.JobTickets__c+= 1;
                        createMailMap(resource.Team_Name__c,generateMailContent(resource,incident));
                        break;
                    }
                    interationCount += 1;
                    if(resource.JobTickets__c < threshold.Max_tickets_per_resource__c){
                    resourceList.add(resource);
                }
                }
                if(assignFlag == false && resourceList.size()>0){
                   OpsResource__c resource = resourceList.remove(0);
                   incidentOwnerMap.put(incident.Id,resource.Assignee__c);
                   createMailMap(resource.Team_Name__c,generateMailContent(resource,incident));
                   resource.JobTickets__c+=1;
                        if(resource.JobTickets__c < threshold.Max_tickets_per_resource__c){
                            resourceList.add(resource);
                    }
                }

            }
        }
        catch(Exception e){
            system.debug(e.getMessage());
            throw new HD_AutomatedTicketAssignmentException('Error in runAssignmentProcess method',e);
        }
    }*/
    //new logic for above runAssignment process
    private static Integer runAssignmentProcessNew(List<OpsResource__c> resourceList, List<BMCServiceDesk__Incident__c> incidentList, Threshold__c threshold, map<string,List<BMCServiceDesk__Incident__c>> resourceToIncidentList){ 
        Integer assignedTicketCount = 0;
        map<id,integer> ticketCountMap = new map<id,integer>();
        List<OpsResource__c> removedResourceList = new List<OpsResource__c>();

        for(OpsResource__c resource: resourceList){
            ticketCountMap.put(resource.id,0);
            resource.JobTickets__c = 0;
        }

        try{
            for(BMCServiceDesk__Incident__c incident: incidentList){
                //OpsResource__c assignedResource = null;
                Integer resourceIndex = -1;
                for(OpsResource__c resource: resourceList ){
                    string incidentKeywords = incidentKeywordsMap.get(incident.Id);
                    string[] resourceSpecialization = resourceSpecializationMap.get(resource.Id);
                    if(checkSpecialization(resourceSpecialization,incidentKeywords)){
                        //assignedResource = resource;
                        resourceIndex = resourceList.indexOf(resource);
                        break;
                    }
                }
                // check for the category name in the specialization PRTORES-1454
                if(incident.BMCServiceDesk__Category_ID__c != null){
                for(OpsResource__c resource: resourceList ){
                    system.debug(incident.BMCServiceDesk__Category_ID__c);
                    if(resource.Specializations__c.containsIgnoreCase(incident.BMCServiceDesk__Category_ID__c)){
                        //assignedResource = resource;
                        resourceIndex = resourceList.indexOf(resource);
                        break;
                    }
                }
                }
                if(resourceIndex == -1 ){
                    //Integer index = -1;
                    for(OpsResource__c resource: resourceList){
                        if(resource.Specializations__c == null || resource.Specializations__c == '' || resource.Specializations__c.containsIgnoreCase('default')){
                            resourceIndex = resourceList.indexOf(resource);
                            break;
                        }
                    }
                    /*if(index != -1){
                        assignedResource = resourceList.remove(index);  // if there is no specialization assigning to the pop the first resource and assign.
                        resourceList.add(assignedResource); //add it back to the list
                    }*/
                }
                if(resourceIndex != -1){
                    assignedTicketCount+=1;
                    OpsResource__c assignedResource = resourceList.remove(resourceIndex);
                    incidentOwnerMap.put(incident.Id,assignedResource.Assignee__c);
                    ticketCountMap.put(assignedResource.id,ticketCountMap.get(assignedResource.id)+1);

                    assignedResource.WeekTickets__c = assignedResource.WeekTickets__c + 1; // update assigned ticket count PRTORES-1453
                    assignedResource.TicketsAssigned__c = assignedResource.TicketsAssigned__c + 1;

                    resourceToIncidentList.get(assignedResource.ResourceName__c).add(incident);
                    assignedResourceSet.add(assignedResource.ResourceName__c);
                    if((ticketCountMap.get(assignedResource.Id) < threshold.Max_tickets_per_resource__c) && (assignedResource.WeekTickets__c < threshold.Max_tickets_per_week__c)){
                        //Integer index = resourceList.indexOf(assignedResource);
                        assignedResource.JobTickets__c = ticketCountMap.get(assignedResource.Id);
                        resourceList.add(assignedResource);  
                    }
                    else {
                        assignedResource.JobTickets__c = threshold.Max_tickets_per_resource__c;
                        removedResourceList.add(assignedResource);
                        //update assignedResource;
                    }
                }
                if(resourceList.isEmpty() && !(removedResourceList.isEmpty())){ // if all resource are have reached the limit. 
                    createMailMap(threshold.Queue_to_use__c,'</br>All available resources at this job time have reached the maximum limit on the ticket assignment per resource per job or no assignable resource; Current limit: ' + threshold.Max_tickets_per_resource__c + '</br>');
                    //update removedResourceList;
                    //return assignedTicketCount;
                    break;
                }
            }
        }
        catch(Exception e){
            system.debug(e.getMessage());
            throw new HD_AutomatedTicketAssignmentException('Error in runAssignmentProcess method',e);
        }

        //update the resource list
        resourceList.addAll(removedResourceList);
        update resourceList;

        return assignedTicketCount;
    }

    private static void createOutofOfficeMessage(String queue){
        String messageString = '</br>Unavailable Resources: ';
        List<string> outOfOfficeResourceList = outOfOfficeResourceMap.get(queue);
        system.debug(outOfOfficeResourceList);
        messageString+= String.valueOf(outOfOfficeResourceList.size()) + '</br>';
        for (Integer i=0; i < outOfOfficeResourceList.size(); i++){
            messageString+= String.valueOf(i+1) + '.' + outOfOfficeResourceList[i] + '</br>';
        }
        createMailMap(queue,messageString);
    }

    
    private static void assignTicketoResource(){

        for( string queue: queueNameList){
            assignedResourceSet.clear();
            map<string,List<BMCServiceDesk__Incident__c>> resourceToIncidentList = new map<string,List<BMCServiceDesk__Incident__c>>();

            try{
                system.debug(' queue name '+ queue );
                List<OpsResource__c> resourceList = queueResourceMap.get(queue);
                List<OpsResource__c> resourceListCopy = new List<OpsResource__c>(resourceList); // generating a copy because the resource list will reduce in the size in future operations.
                Id queueId = queueNameIdmap.get(queue);
                List<BMCServiceDesk__Incident__c> incidentList = queueIncidentMap.get(queueId);
                Threshold__c threshold = queueThresholdMap.get(queue);
                if(resourceList == null || resourceList.isEmpty()){
                    system.debug('no available resources for the queue : ' + queue);
                    createMailMap(queue,'</br>Assignment Status: No available resource for the queue ' + queue + ' at ' + jobHour + 'hour' + ' on ' + dateString + '</br>');
                    continue;
                    //error
                }
                if(incidentList == null || incidentList.isEmpty()){
                    system.debug('no open incidents for the queue: ' + queue);
                    createMailMap(queue,'</br>Assignment Status: No open Incidnets in the queue ' + queue + ' at ' + jobHour + 'hour' + ' on ' + dateString + '</br>');
                    continue;
                    //error
                }
                for(OpsResource__c resource: resourceList){
                    List<BMCServiceDesk__Incident__c> tempList = new List<BMCServiceDesk__Incident__c>();
                    resourceToIncidentList.put(resource.ResourceName__c,tempList);
                }
                createMailMap(queue, '</br>Ticket allotment details for the queue ' + queue + ' at ' + jobHour + 'hour' + ' on ' + dateString + '</br></br>');
                integer assignedTicketCount = runAssignmentProcessNew(resourceList,incidentList,threshold,resourceToIncidentList);
                createMailMap(threshold.Queue_to_use__c,generateMailContent(resourceToIncidentList));
                createMailMap(queue,'</br>Assignement Summary:</br> Queue: ' + queue + '; ' + 'Incidents: ' + incidentList.size() + '; ' + 'Available Resource: ' + resourceListCopy.size() + '; ' + 'Assigned Resources: ' + assignedResourceSet.size() + '; ' + 'Assignments: ' + assignedTicketCount + '</br>');
                // out of office message generation
                createOutofOfficeMessage(queue);
            }
            catch(Exception e){
                system.debug(e.getMessage());
                throw new HD_AutomatedTicketAssignmentException('Error in assignTicketoResource method',e);
            }
        }

    }
    
    private static void updateAssignedTickets(){
        try{
            List<Id> updatedIncidentsList = new List<Id>(incidentOwnerMap.keySet());
            system.debug(updatedIncidentsList);
            string query = 'SELECT Id,OwnerId,isAssingedByRoundRobin__c FROM BMCServiceDesk__Incident__c WHERE Id IN :updatedIncidentsList';
            HD_BatchableAutomatedTicketAssignment newBatch = new HD_BatchableAutomatedTicketAssignment(query,updatedIncidentsList,incidentOwnerMap,emailMap);
            Database.executeBatch(newBatch,1);
        }
        catch(Exception e){
            system.debug(e.getMessage());
            throw new HD_AutomatedTicketAssignmentException('Error in updateAssignedTickets method',e);
        }
    }
    @AuraEnabled
    Public static string assignOpenTickets(){
        try{
            setJobTimeDetails();
            getCustomSetting();
            resetTicketsAssigned(); 
            getQueueDetails();
            getOpenIncidents();
            setTheShiftsNew();
            getActiveResources();
            assignTicketoResource();
            updateAssignedTickets();
            system.debug(emailMap);
        }
        catch( HD_AutomatedTicketAssignmentException ce){
            system.debug(ce.getMessage());
            ce.updateErrorLog();
            return 'failure';
        }
        return 'success';
    }

}