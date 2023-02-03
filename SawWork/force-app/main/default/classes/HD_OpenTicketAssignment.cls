/*
 *Template           : Apex Class
 *Version            : 1.0
 *@author            : Komal Narsinghani @ Akamai Technologies Ltd.
 *Purpose            : Automation of ticket assignment to queue members
 *Dependent Classes  : HD_BatchableOpenTicketAssignment, HD_Schedulable_OpenTicketAssignment
 *Test Class         : HD_Test_OpenTicketAssignmentTest
 *Last modification  : Shashank Hegade @ Akamai Technologies Ltd.
 * Modification Log ===============================================================
 * Date 		     Author 			 Modification
 * Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
 */

global with sharing class HD_OpenTicketAssignment{

    //defining global variables
    public static Integer job_time{get;set;}
    public static String job_day {get;set;}
    public static String updatedIncidentMessage{get;set;}
    public static String usedResourceMessage{get;set;}
    public static String messageIncidentIds {get;set;}
    public static Integer INTERVAL=4;
    //public static Integer INTERVAL{get;set;}
    public static Integer HOUR_UPPER_LIMIT=24;
    public static Integer upperLimit{get;set;}
    public static Integer lowerLimit{get;set;}
    public static Map<String,Integer> intrvlMap = new Map<String,Integer>();
    public static Map<String,Integer> cutOffMap = new Map<String,Integer>();

    public static String weekDay{get;set;}
    public static String weekNumber{get;set;}
    public static String jobHour{get;set;}


    //BEGIN: This is the method to get the time and date in the indian standard time format; added by: @shashankhegade
    private static void DatetimeGMTToIST(){       

        DateTime datetimeToConvert = Datetime.now();
        String timeZoneName = [SELECT Label,instanceName__c FROM HD_Instance__mdt where Label = 'Time Zone Name' limit 1].instanceName__c;
        system.debug('timeZoneName ' + timeZoneName);
        string convertedDateTime = datetimeToConvert.format('dd/MM/yyyy HH:mm:ss EEEE W', timeZoneName );// E - day(e.g monday), W - week number in the month
        
        string[] dateTimeArray = convertedDateTime.split(' ',4);
        job_day = dateTimeArray[2];
        weekDay = dateTimeArray[2];
        weekNumber = dateTimeArray[3];

        string timeString = DateTimeArray[1];
        string[] timeArray = timeString.split(':',3);
        job_time = integer.valueOf(timeArray[0]);
        jobHour = timeArray[0];

    }
    //END

    //Method to get list of queue Ids based on list of queue names
    public static List<Id> getQueueIds(List<String> qName){
        try{
            List<Group> queueGroup= [Select Id from Group where Name in :qName and Type = 'Queue' limit 50];
            if(queueGroup.size()==0)
                return new List<Id>();
            List<Id> queueId=new List<Id>();
            for(Group g:queueGroup){
                queueId.add(g.Id);
            }
            System.debug('Queue Id: '+queueId);
            return queueId;
        }//try
        catch(Exception e){
            System.debug('An exception occurred in getQueueIds');
            return new List<Id>();
        }//catch
    }//getQueueIds


    //Method to construct a map of queue names with their Ids
    public static Map<String,Id> getQueueIdMap(List<String> teamNames){
        try{
            List<Group> queueGroup= [Select Id,Name from Group where Name in :teamNames and Type = 'Queue' limit 50];
            Map<String,Id> mapIdName=new Map<String,Id>();
            for(Group g:queueGroup){
                mapIdName.put(g.Name, g.Id);
            }
            System.debug('QueueIdMap: '+mapIdName);
            return mapIdName;
        }//try
        catch(Exception e){
            System.debug('An exception occurred in getQueueIdMap');
            return new Map<String,Id>();
        }//catch
    }//getQueueIdMap


    //Method to get all the incidents in Unassigned status depending on the queue names   
    public static List<BMCServiceDesk__Incident__c> getOpenIncidents(List<String> queueNames){ 
        List<BMCServiceDesk__Incident__c> openIncidents= new List<BMCServiceDesk__Incident__c>();
        List<Id> queueIds=getQueueIds(queueNames);
        if(queueIds==null){
            return openIncidents;
        }
        if(test.isRunningTest()){
            System.debug('Running Test');
            openIncidents=[Select Id,Name,OwnerId,BMCServiceDesk__FKStatus__c,isAssingedByRoundRobin__c,BMCServiceDesk__Status_ID__c,BMCServiceDesk__state__c,BMCServiceDesk__FKPriority__c,BMCServiceDesk__Category_ID__c,HD_Parent_Category__c,HD_Parent_Tree__c from BMCServiceDesk__Incident__c where (BMCServiceDesk__Status_ID__c ='UNASSIGNED' OR BMCServiceDesk__Status_ID__c ='REASSIGNED') AND OwnerId in :queueIds AND BMCServiceDesk__FKCategory__r.BMCServiceDesk__inactive__c = false AND BMCServiceDesk__FKCategory__r.RA_Category_Group__c <> 'RESTRICTED PARENT'  ORDER By CreatedDate DESC limit 1];
            //adding restricted parent check

        }
        else{
            openIncidents=[Select Id,Name,OwnerId,BMCServiceDesk__FKStatus__c,isAssingedByRoundRobin__c,BMCServiceDesk__Status_ID__c,BMCServiceDesk__state__c,BMCServiceDesk__FKPriority__c,BMCServiceDesk__Category_ID__c,HD_Parent_Category__c,HD_Parent_Tree__c from BMCServiceDesk__Incident__c where (BMCServiceDesk__Status_ID__c ='REASSIGNED' OR BMCServiceDesk__Status_ID__c ='UNASSIGNED') AND OwnerId in :queueIds AND BMCServiceDesk__FKCategory__r.BMCServiceDesk__inactive__c = false AND BMCServiceDesk__FKCategory__r.RA_Category_Group__c <> 'RESTRICTED PARENT' limit 500];
        } 
        System.debug('No. of open incidents: '+openIncidents.size());
        System.debug('Initial list of open incidents: '+openIncidents);
        return openIncidents;
    }//getOpenIncidents

    //simplify this
    //Method to set upper limit and lower limit
    public static void setLimits(Integer intrvl){
        System.debug('In setLimits, interval= '+intrvl);
        if(intrvl==24){
            upperLimit=23;
            lowerLimit=0;
        }
        else{
            upperLimit=job_time+intrvl;
            System.debug('Job time = '+job_time);
            if(upperLimit>23){
                upperLimit=upperLimit-HOUR_UPPER_LIMIT;
            }
            if(job_time<intrvl){
                //lowerLimit=job_time+20;
                lowerLimit = job_time + (24-intrvl);
            }
            else{
                lowerLimit=job_time-intrvl;
            }
            //to add
            //if(lowerLimit>23){
            //  lowerLimit=lowerLimit-HOUR_UPPER_LIMIT;
            //}
        }//else
        System.debug('Upper limit is: '+upperLimit);
        System.debug('Lower limit is: '+lowerLimit);
    }

    //Method to populate isAvailable and ShiftTimeCode based on junction object
    public static List<OpsResource__c> populateAvailabilityAndShift(List<OpsResource__c> resources){
        System.debug('Entered populateAvailabilityAndShift');
        System.debug('week day and number in populateAvailabilityAndShift: '+weekDay+':'+weekNumber);
        String weekNumberSearch = '%'+weekNumber+'%';
        String weekDaySearch = '%'+weekDay+'%';
        OpsResource_Shift_Junction__c finalShift;
        List<OpsResource__c> updatedResourceList = new List<OpsResource__c>();
        for(OpsResource__c resource : resources){
            System.debug('populateAvailabilityAndShift resource: '+resource);
            /*
            if(resource.Assign_Always__c == true){
                //resource.ShiftTimeCode__c = job_time;
                //updatedResourceList.add(resource);
                System.debug('Resource to not be considered');
            }
            else{
             */
            Boolean resourcePresent = true;
            List<OpsResource_Shift_Junction__c> availableShifts = [Select ShiftSchedule__r.Is_Available__c, ShiftSchedule__r.Login_time__c, ShiftSchedule__r.Logout_Time__c  from OpsResource_Shift_Junction__c where OpsResource__r.Id=:resource.Id and ShiftSchedule__r.Week_Number__c like :weekNumberSearch and ShiftSchedule__r.Days__c like :weekDaySearch];
            if(availableShifts.size()==0){
                System.debug('No shifts defined');
                /*
                 * uncomment this if resource has to be considered as not available if no shifts are defined
                resourcePresent = false;
                resource.Is_Available__c = false;
                updatedResourceList.add(resource);
                 */
            }//if

            else{
                System.debug('Shifts are defined');
                for(OpsResource_Shift_Junction__c shift:availableShifts) {
                    System.debug('Got OpsResource_Shift_Junction__c: '+shift);
                    if(shift.ShiftSchedule__r.Is_Available__c == false){
                        System.debug('isAvailable is false');
                        resourcePresent = false;
                        resource.Is_Available__c = false;
                        updatedResourceList.add(resource);
                    }//if
                }//for 

                if(resourcePresent == true){
                    System.debug('flag resourcePresent is true');
                    finalShift = availableShifts[0];
                    resource.Is_Available__c = finalShift.ShiftSchedule__r.Is_Available__c;
                    //added new if else condition to handle midday and midnight times @shashank hegade
                    if(finalShift.ShiftSchedule__r.Login_time__c.containsIgnoreCase('12') && finalShift.ShiftSchedule__r.Login_time__c.containsIgnoreCase('PM')){
                        resource.ShiftTimeCode__c = 12;
                    }
                    else if(finalShift.ShiftSchedule__r.Login_time__c.containsIgnoreCase('12') && finalShift.ShiftSchedule__r.Login_time__c.containsIgnoreCase('AM')){
                        resource.ShiftTimeCode__c = 00;
                    }                  
                    else if(finalShift.ShiftSchedule__r.Login_time__c.containsIgnoreCase('PM')){
                        System.debug('Login time is in PM');
                        String loginTimeString = finalShift.ShiftSchedule__r.Login_time__c.split(' ')[0];
                        Integer loginTimeNumeric = Integer.valueOf(loginTimeString);
                        resource.ShiftTimeCode__c = loginTimeNumeric+12;
                        System.debug('updated shiftTimeCode: '+resource.ShiftTimeCode__c);
                    }//if PM
                    else{
                        System.debug('Login time is in AM');
                        String loginTimeString = finalShift.ShiftSchedule__r.Login_time__c.split(' ')[0];
                        Integer loginTimeNumeric = Integer.valueOf(loginTimeString);
                        resource.ShiftTimeCode__c = loginTimeNumeric;
                        System.debug('updated shiftTimeCode: '+resource.ShiftTimeCode__c);
                    }//else

                    if(finalShift.ShiftSchedule__r.Logout_time__c.containsIgnoreCase('12') && finalShift.ShiftSchedule__r.Logout_time__c.containsIgnoreCase('PM')){
                        resource.ShiftTimeEnd_Code__c  = 12;
                    }
                    else if(finalShift.ShiftSchedule__r.Logout_time__c.containsIgnoreCase('12') && finalShift.ShiftSchedule__r.Logout_time__c.containsIgnoreCase('AM')){
                        resource.ShiftTimeEnd_Code__c = 00;
                    }
                    else if(finalShift.ShiftSchedule__r.Logout_time__c.containsIgnoreCase('PM')){
                        System.debug('Logout time is in PM');
                        String logoutTimeString = finalShift.ShiftSchedule__r.Logout_time__c.split(' ')[0];
                        Integer logoutTimeNumeric = Integer.valueOf(logoutTimeString);
                        resource.ShiftTimeEnd_Code__c  = logoutTimeNumeric+12;
                        System.debug('updated shiftTimeEnd Code: '+resource.ShiftTimeEnd_Code__c );
                    }//if PM

                    else{
                        System.debug('Logout time is in AM');
                        String logoutTimeString = finalShift.ShiftSchedule__r.Logout_time__c.split(' ')[0];
                        Integer logoutTimeNumeric = Integer.valueOf(logoutTimeString);
                        resource.ShiftTimeEnd_Code__c = logoutTimeNumeric;
                        System.debug('updated shiftTimeEnd Code: '+resource.ShiftTimeEnd_Code__c);
                    }//else

                    updatedResourceList.add(resource);
                }
            } //else
            //}//else
        }//for
        System.debug('updatedResourceList: '+updatedResourceList);
        return updatedResourceList;
    }
    //Method to get a list of all available resources
    public static List<OpsResource__c> getAvaiableResources(List<String> qnames){
        System.debug('In getAvailableResources');
        System.debug('Interval map: '+intrvlMap);
        System.debug('CutOff map: '+cutOffMap);
        List<OpsResource__c> allResources= new List<OpsResource__c>();
        List<OpsResource__c> availableResources= new List<OpsResource__c>();

        System.debug('Upper limit is: '+upperLimit);
        System.debug('Lower limit is: '+lowerLimit);
        allResources=[Select OpsResource__c.Id,ResourceName__c,ShiftTimeCode__c,JobTickets__c,TicketsAssigned__c,Is_Available__c,Assignee__c,Team_Name__c, WeekTickets__c, Specializations__c,ShiftTimeEnd_Code__c, Assign_Always__c  from OpsResource__c where Team_Name__c in :qnames AND Is_Available__c = true order by WeekTickets__c asc limit 500]; //added new condition @shashank hegade
        System.debug('Got resources');
        List<OpsResource__c> updatedResources = populateAvailabilityAndShift(allResources);
        update updatedResources;
        for(OpsResource__c res: allResources){
            if(res.Assign_Always__c==true && res.Is_Available__c==true){
                res.JobTickets__c=0;
                availableResources.add(res);
            }
            else{
                if(res.Is_Available__c==true){
                    Integer intrvl = intrvlMap.get(res.Team_Name__c);
                    //Integer cutOffHours = 1; //check this
                    Integer cutOffHours = cutOffMap.get(res.Team_Name__c);
                    System.debug('CutOff Hours: '+cutoffHours);
                    //default value for Cutoff field is 0
                    //if(cutOffHours == null){
                    //cutOffHours = 0;
                    //}
                    Integer endTimeCode = (Integer)res.ShiftTimeEnd_Code__c;
                    Integer timeCode = (Integer)res.ShiftTimeCode__c;
                    if(endTimeCode==null){
                        System.debug('End time code is null');
                        //endTimeCode = timeCode + 9;
                    }
                    System.debug('Interval for this resource with team: '+res.Team_Name__c+' is: '+intrvl);
                    System.debug('CutOff for this resource is: '+cutOffHours);
                    System.debug('endTimeCode:'+endTimeCode);
                    setLimits(intrvl);
                    System.debug('Upper limit new is: '+upperLimit);
                    System.debug('Lower limit new is: '+lowerLimit);
                    if(lowerLimit<upperLimit){
                        // moved up now
                        //Integer timeCode = (Integer)res.ShiftTimeCode__c;
                        /*
                    if(job_day=='Monday'){
                        timeCode=(Integer)res.ShiftTimeCode_Monday__c;
                    }
                  else if(job_day=='Tuesday'){
                        timeCode=(Integer)res.ShiftTimeCode_Tuesday__c;
                    }
                  else if(job_day=='Wednesday'){
                        timeCode=(Integer)res.ShiftTimeCode_Wednesday__c;
                  }
                  else if(job_day=='Thursday'){
                      timeCode=(Integer)res.ShiftTimeCode_Thursday__c;
                  }
                  else if(job_day=='Friday'){
                      timeCode=(Integer)res.ShiftTimeCode_Friday__c;
                  }
                         */
                        System.debug('timeCode: '+timeCode);

                        //if(timeCode<upperLimit && timeCode>=lowerLimit){
                        if(timeCode<upperLimit-cutOffHours && timeCode>=lowerLimit){ // modified the condition @shashankhegade
                            //if(endTimeCode==null || endTimeCode>=job_time-cutOffHours){
                                res.JobTickets__c=0;
                                availableResources.add(res);
                            //}
                        }
                    }  //if(lowerLimit<upperLimit) 
                    else if(lowerLimit>=upperLimit){
                        //if(res.ShiftTimeCode__c<upperLimit || res.ShiftTimeCode__c>=lowerLimit){
                        if((res.ShiftTimeCode__c<upperLimit-cutOffHours|| res.ShiftTimeCode__c>=lowerLimit)){ //modified the condition @shashankhegade
                            //if(endTimeCode==null || endTimeCode>=job_time-cutOffHours){
                                res.JobTickets__c=0;
                                availableResources.add(res);
                            //}
                        }
                    }//if lowerLimit>upperLimit

                }//if available = true
            }//else
        }//for
        return availableResources;
    }//getAvailableResources

    //Method to remove the first incident from the list
    public static BMCServiceDesk__Incident__c dequeueIncident(List<BMCServiceDesk__Incident__c> openIncidents){
        BMCServiceDesk__Incident__c firstIncident=(BMCServiceDesk__Incident__c)openIncidents.remove(0);
        return firstIncident;
    }//dequeueIncident

    //Method to remove the first resource from the list
    public static OpsResource__c dequeueResource(String resId, List<OpsResource__c> availableResources){
        OpsResource__c usedResource=availableResources.remove(0);
        return usedResource;
    }//dequeueResource

    //Method to remove the specified resource from the list
    public static OpsResource__c dequeueResource(OpsResource__c resource, List<OpsResource__c> availableResources){
        Integer index = availableResources.indexOf(resource);
        OpsResource__c usedResource = availableResources.remove(index);
        return usedResource;
    }//dequeueResource

    //Method to insert a resource at the end of the list
    public static void enqueueResource(OpsResource__c resource, List<OpsResource__c> availableResources){
        availableResources.add(resource);
        System.debug('Added resource');
        System.debug('New list of availableResources with the added resource: '+availableResources);
    }//enqueueResource

    //Method to assign tickets to resources
    public static Integer assignTicketsToResources(List<OpsResource__c> availableResources, List<BMCServiceDesk__Incident__c> openIncidents, Map<String,Threshold__c> thresholdMap, Map<String,Id> queueMap){
        try{ 
            //added now
            Map<String,List<String>> teamMailContent = new Map<String,List<String>>();

            List<OpsResource__c> tmpList=new List<OpsResource__c>();
            List<BMCServiceDesk__Incident__c> updatedIncidents=new List<BMCServiceDesk__Incident__c>();
            List<String> assignedMsg=new List<String>();//Content for mail, indicates which resource has been assigned which incident
            Map<Id,Id> incOwner=new Map<Id,Id>();//Map for batch update, will be passed to the batchable class
            List<Id> updatedIncidentIds=new List<Id>();//List of updated incident ids
            messageIncidentIds='Details of incidents updated in this job: <br/>';

            //Beginning of Assignment code
            while(availableResources.size()>0 && openIncidents.size()>0){
                System.debug('Getting incident');
                BMCServiceDesk__Incident__c incident=dequeueIncident(openIncidents);
                Integer iterations=0;
                Boolean ticketNotAssignedToResource = false;
                Integer start = 0;
                //counting the number of iterations for each incident, should not be greater than size of list of resources
                //if it is greater, it implies that there is no resource available for this incident
                while(iterations<availableResources.size()){
                    //If the previous resource was not assigned ticket, it is not dequeued 
                    //and hence we want to consider next resource in queue
                    //else set start to 0 i.e. take the resource at front of queue

                    System.debug('Getting first resource');
                    //OpsResource__c resource=availableResources.get(0);
                    OpsResource__c resource=availableResources.get(start);
                    System.debug('Resource: '+resource);
                    String teamName=resource.Team_Name__c;
                    System.debug('Team Name: '+teamName);
                    Threshold__c threshold=thresholdMap.get(teamName);
                    System.debug('Threshold: '+threshold);
                    String queueId=queueMap.get(teamName);
                    System.debug('Shift Time Code for resource: '+resource.ShiftTimeCode__c);
                    System.debug('Queue Id for resource: '+queueId);   
                    System.debug('resource.TicketsAssigned__c: '+resource.TicketsAssigned__c);
                    System.debug('resource.JobTickets__c: '+resource.JobTickets__c);
                    System.debug('threshold.Max_tickets_per_job__c: '+threshold.Max_tickets_per_job__c);
                    System.debug('threshold.Max_tickets_per_resource__c: '+threshold.Max_tickets_per_resource__c);

                    //condition to check if none of the thresholds is violated
                    if((resource.JobTickets__c<threshold.Max_tickets_per_job__c) && (resource.WeekTickets__c < threshold.Max_tickets_per_week__c )){
                        System.debug('Got valid resource');
                        //String specialization = 'default';
                        List<String> specialization = new List<String>();
                        if(resource.Specializations__c!=null&&resource.Specializations__c!=''){
                            //specialization = resource.Specializations__c;
                            specialization = resource.Specializations__c.split(',');
                        }
                        else{
                            specialization.add('default');
                        }
                        String parentCategory = 'none';
                        if(incident.HD_Parent_Category__c!=null&&incident.HD_Parent_Category__c!=''){
                            parentCategory = incident.HD_Parent_Category__c;
                        }
                        String parentTree = 'none';
                        String firstLevelCategory = 'none';
                        String topLevelCategory = 'none';
                        if(incident.HD_Parent_Tree__c!=null&&incident.HD_Parent_Tree__c!=''){
                            parentTree = incident.HD_Parent_Tree__c;
                            firstLevelCategory = parentTree;
                            topLevelCategory = parentTree;   
                            if(parentTree.contains('-->')){  
                                List<String> parentCategories = parentTree.split('-->');
                                topLevelCategory = parentCategories[parentCategories.size()-1];
                                firstLevelCategory = parentCategories[parentCategories.size()-2];
                            }   
                        }
                        //String firstLevelCategory = parentTree;//by default assign it to parent tree. change if parent tree contains'-->'

                        System.debug('Specializations: '+specialization);
                        System.debug('specialization.contains(incident.BMCServiceDesk__Category_ID__c):'+specialization.contains(incident.BMCServiceDesk__Category_ID__c));
                        //System.debug('specialization.contains(incident.HD_Parent_Category__c):'+specialization.contains(incident.HD_Parent_Category__c));
                        System.debug('specialization.contains(incident.HD_Parent_Category__c):'+specialization.contains(parentCategory));
                        //if((queueId==incident.OwnerId)&&(specialization.containsIgnoreCase(incident.BMCServiceDesk__Category_ID__c)||specialization.containsIgnoreCase(parentCategory)||specialization.containsIgnoreCase('default')||specialization.containsIgnoreCase(firstLevelCategory)||specialization.containsIgnoreCase(topLevelCategory))){
                        if((queueId==incident.OwnerId)&&(specialization.contains(incident.BMCServiceDesk__Category_ID__c)||specialization.contains(parentCategory)||specialization.contains('default')||specialization.contains(firstLevelCategory)||specialization.contains(topLevelCategory))){
                            //if(queueId==incident.OwnerId){
                            System.debug('Matching queue ids');
                            System.debug('State of incident before update: '+incident.BMCServiceDesk__state__c);
                            System.debug('Assignee: '+resource.Assignee__c);
                            incident.OwnerId=resource.Assignee__c;
                            //As per jira PRTORES-1146 Metrics for round robin tickets, adding isAssingedByRoundRobin__c flag to true if incident is assinged by round robin
                            incident.isAssingedByRoundRobin__c=true;
                            updatedIncidents.add(incident);
                            incOwner.put(incident.Id, resource.Assignee__c);
                            updatedIncidentIds.add(incident.Id);
                            System.debug('State of incident after update: '+incident.BMCServiceDesk__state__c);
                            //OpsResource__c usedResource=dequeueResource(resource.Id,availableResources);
                            OpsResource__c usedResource=dequeueResource(resource,availableResources);
                            System.debug('Tickets assigned before update: '+usedResource.TicketsAssigned__c);
                            usedResource.TicketsAssigned__c=usedResource.TicketsAssigned__c+1;
                            usedResource.JobTickets__c=usedResource.JobTickets__c+1;
                            usedResource.WeekTickets__c= usedResource.WeekTickets__c+1;
                            System.debug('Tickets Assigned for the resource in this job: '+usedResource.JobTickets__c);
                            tmpList.add(usedResource);
                            System.debug('Tickets assigned after update: '+usedResource.TicketsAssigned__c);
                            enqueueResource(usedResource,availableResources);
                            System.debug('Incident: '+incident.Id+' has been assigned to: '+usedResource.Id);
                            String link=URL.getSalesforceBaseUrl().toExternalForm()+'/'+incident.Id;
                            System.debug('Link = '+link);
                            String urlVar='<a href="'+link+'">'+incident.Name+'</a>';
                            System.debug('URL= '+urlVar);
                            assignedMsg.add('Resource: '+usedResource.ResourceName__c+ ' has been assigned the incident: '+urlVar);
                            //added now
                            if(threshold.Team_Email__c==null||threshold.Team_Email__c==''){
                                System.debug('Email not required');
                                break;
                            }
                            if(teamMailContent.containsKey(threshold.Team_Email__c)){
                                List<String> tmpContent = teamMailContent.get(threshold.Team_Email__c);
                                tmpContent.add('Resource: '+usedResource.ResourceName__c+ ' has been assigned the incident: '+urlVar);
                            }
                            else{
                                List<String> msg = new List<String>();
                                msg.add('Resource: '+usedResource.ResourceName__c+ ' has been assigned the incident: '+urlVar);
                                teamMailContent.put(threshold.Team_Email__c, msg);
                            }
                            //end of added now 
                            break;//If a valid resource was found, break from the second while loop
                        }//if-2
                        else{
                            //the resource does not violate the threshold but is not capable of handling the ticket in question
                            //hence, keeping it at front of queue itself to consider for next incident by setting the flag
                            //incrementing start to consider the next resource
                            ticketNotAssignedToResource = true;
                            iterations++;
                            start++;
                            System.debug('Iterations= '+iterations);
                            //dequeueResource(resource.Id,availableResources);
                            //enqueueResource(resource,availableResources);
                        }//else
                    }//if-1
                    else{
                        //if the resource violates thresholds, dequeue it from the list of available resources
                        //dequeueResource(resource.Id,availableResources);
                        dequeueResource(resource,availableResources);
                    }
                }//while
            }//while
            //End of Assignment code     

            //added now
            System.debug('Team Mail Content:'+teamMailContent);
            Map<String,String> emailMap = new Map<String,String>();
            for(String team:teamMailContent.keySet()) {
                System.debug('Team: '+team);
                List<String> content = teamMailContent.get(team);
                content.sort();
                String finalContent = 'Details of incidents updated in this job: <br/>';
                for(String str:content){
                    finalContent +=str+'</br>';
                }
                System.debug('final content: '+finalContent);
                emailMap.put(team, finalContent);
            } 
            System.debug('Email Map: '+emailMap);
            //end of added now
            //Sort the assignedMsg list and add all the strings to incidentIds to display in mail
            assignedMsg.sort();  
            for(String s: assignedMsg){
                messageIncidentIds +=s+'</br>';//Content for mail
            }

            System.debug('List of updated incidents: '+updatedIncidents);
            System.debug('Number of updated incidents: '+updatedIncidents.size());
            updatedIncidentMessage='Total number of incidents that were assigned in this job = '+updatedIncidents.size();

            //Remove duplicates from tmpList
            Set<OpsResource__c> tmpSet=new Set<OpsResource__c>();
            tmpSet.addAll(tmpList);
            usedResourceMessage='Total number of resources used in this job= '+tmpSet.size();
            //Update the resources by adding them to a new list
            List<OpsResource__c> newList=new List<OpsResource__c>();
            newList.addAll(tmpSet);
            update newList;
            System.debug('List of updated resources: '+newList);
            System.debug('Size of list of updated resources: '+newList.size());
            if(newList.size()==0){
                return 1;
            }   
            //update updatedIncidents;
            //Using Batchable to Update
            String q='Select Id, OwnerId from BMCServiceDesk__Incident__c where Id in :updatedIncidentIds';
            String f='OwnerId';   
            HD_BatchableOpenTicketAssignment batch=new HD_BatchableOpenTicketAssignment(q,f,updatedIncidentIds,incOwner,messageIncidentIds,updatedIncidentMessage,usedResourceMessage,emailMap); 
            if(test.isRunningTest())  {
                Database.executeBatch(batch, 10);
            } 
            else{
                Database.executeBatch(batch, 1);
            }

            return 0;
        }//try

        catch(Exception e){
            System.debug('An exception occurred while assigning tickets');
            return 2;
        }//catch

    }//assignTicketsToResources

    //Method to update the tickets assigned to resources 
    public static boolean updateTicketsAssigned(List<String> queueName){
        try{
            System.debug('Updating assigned tickets');
            List<Id> ownerIds=new List<Id>();
            Map<Id,OpsResource__c> idResMap=new Map<Id,OpsResource__c>();
            List<OpsResource__c> updatedResources=new List<OpsResource__c>();
            List<OpsResource__c> newResources=new List<OpsResource__c>();

            DateTime today=DateTime.now();
            System.debug('Today= '+today);
            String gmtDay=today.formatGmt('EEEE');
            System.debug('gmtDay today: '+gmtDay);

            //Set the tickets assigned to 0
            List<OpsResource__c> resources=[Select Id,TicketsAssigned__c,Assignee__c from OpsResource__c where Team_Name__c in :queueName limit 500];
            System.debug('List of resources for updating tickets: '+resources);
            for(OpsResource__c res:resources){
                if(gmtDay.equalsIgnoreCase('Monday')){
                    ownerIds.add(res.Assignee__c);
                    res.TicketsAssigned__c=0;
                    res.WeekTickets__c=0;
                    updatedResources.add(res);
                }
                else{
                    ownerIds.add(res.Assignee__c);
                    res.TicketsAssigned__c=0;
                    updatedResources.add(res);   
                }
            }

            update updatedResources;

            //Create map with id and resource object
            for(OpsResource__c res:updatedResources){
                idResMap.put(res.Assignee__c, res);
            }

            System.debug('OwnerIds List: '+ownerIds);
            //Update the number of tickets for each resource, by iterating through the incidents
            List<BMCServiceDesk__Incident__c> incidents=[Select Id, OwnerId from BMCServiceDesk__Incident__c  where OwnerId in :ownerIds and BMCServiceDesk__state__c=true limit 1000];
            System.debug('List of incidents fetched: '+incidents);
            for(BMCServiceDesk__Incident__c inc:incidents){
                OpsResource__c resource=idResMap.get(inc.OwnerId);
                resource.TicketsAssigned__c++;
                newResources.add(resource);
            }

            System.debug('New list of resources while updating assigned tickets: '+newResources);
            Set<OpsResource__c> tmpSet=new Set<OpsResource__c>();
            tmpSet.addAll(newResources);
            List<OpsResource__c> tmpList=new List<OpsResource__c>();
            tmpList.addAll(tmpSet);
            System.debug('Temp list of resources while updating assigned tickets: '+tmpList);
            update tmpList;
            return true;
        }//try
        catch(Exception e){
            System.debug('An exception occurred while updating assigned tickets');
            return false;
        }//catch
    }

    //Method to send mail depending on the result value
    //Remove this method or refactor this method as its sending mail at each job to CRM OPS 
    // commented this method to stop mails to Ops @shashankhegade
    public static void sendMail(String result){
        /*System.debug('In send mail');
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>();
        sendTo.add(UserInfo.getUserId());
        mail.setToAddresses(sendTo);
        mail.setSenderDisplayName('Ticket Assignment Job');
        mail.setSubject('AUTOMATED TICKET ALLOCATION FAILURE');
        String body;

        if(result=='No Resources'){
            body = 'There are no available resources for automated ticket allocation.';
        }
        else if(result=='No Tickets'){
            body = 'There are no open tickets to be allocated.';
        }
        else{
            body= 'Automated ticket allocation has failed.';
        }
        mail.setHtmlBody(body);
        mails.add(mail);
        System.debug('Sending mail now');
        Messaging.sendEmail(mails);  */ 
    }

    //Main method which is called initially
    @RemoteAction
    webservice static Integer assignOpenTickets(){  
        try{
            //Get gmt hours
            /*DateTime today=DateTime.now();
            Integer gmtHours=today.hourGmt();
            String gmtDay=today.formatGmt('EEEE');
            Integer hours=today.hour();

            //determine week number and week day
            weekDay = today.format('EEEE');    
            weekNumber = today.format('W');
            //System.debug('--date'+'--weekDay:'+ weekDay +'--weekNumber:'+ weekNumber);*/
            DatetimeGMTToIST();
            System.debug('job_time=' + job_time + '--job_day=' + job_day + '--weekNumber=' + weekNumber + '--weekDay=' + weekDay);

            if(Test.isRunningTest()){
                job_time=8;
            }
            /*else{
                job_time=gmtHours;//9
            }*/

            //job_day=gmtDay;   

            //Get all active thresholds and put them in a map(key=queue name). Store their queue names in a list
            List<String> queueNameLst = new List<String>();   
            Map<String,Threshold__c> activeThresholds=new Map<String,Threshold__c>();

            List<Threshold__c> threshold=[Select Is_Active__c, Max_tickets_per_job__c,Job_Run_Time__c, Max_tickets_per_resource__c, Queue_to_use__c, Max_tickets_per_week__c, Interval__c,Team_Email__c,Cutoff__c,Job_frequency__c from  Threshold__c WHERE Is_Active__c=true limit 50];
            
            for(Threshold__c td: threshold){

                //Integer remainder = Math.mod(job_time, (Integer)td.Job_frequency__c);
                
                //System.debug('Remainder for threshold: '+td.Job_frequency__c+'is: '+remainder);

                //added by shashank hegade,changed the logic. initial logic: td.is_Active__c ==true && remainder == 0
                string[] jobTimes = td.Job_Run_Time__c.split(',');
                
                if(jobTimes.contains(jobHour)){ 
                    queueNameLst.add(td.Queue_to_use__c);
                    activeThresholds.put(td.Queue_to_use__c, td);
                    System.debug('Interval for threshold: '+(Integer)td.Interval__c);  
                    intrvlMap.put(td.Queue_to_use__c, (Integer)td.Interval__c);
                    cutOffMap.put(td.Queue_to_use__c, (Integer)td.Cutoff__c);
                }//if
            }//for
            system.debug(queueNameLst);

            //call method to update the assigned tickets of all the resources belonging to queues in the given list
            boolean assignResult=updateTicketsAssigned(queueNameLst);
            if(assignResult==false){
                System.debug('Ticket assignment failed');
                sendMail('Failure');
                return 3;
            }

            //Get open incidents
            List<BMCServiceDesk__Incident__c> openIncidents = getOpenIncidents(queueNameLst);
            if(openIncidents.size()==0){
                System.debug('No open incidents');
                sendMail('No Tickets');
                return 1;
            }//if

            //Get available resources
            List<OpsResource__c> availableResources = getAvaiableResources(queueNameLst);
            if(availableResources.size()==0){
                System.debug('No available resources');
                sendMail('No Resources');
                return 2;
            }//if
            System.debug('Initial list of available resources: '+availableResources);
            System.debug('Assigning the open tickets');

            //Get the map of queue Id (values) against queue name (keys)
            Map<String,Id> queueMap=getQueueIdMap(queueNameLst); 
            if(queueMap==null){
                System.debug('Ticket assignment failed');
                sendMail('Failure');
                return 3;
            }
            //Call method to assign the tickets to resources
            Integer result=assignTicketsToResources(availableResources, openIncidents, activeThresholds,queueMap);
            System.debug('Result is: '+result);
            if(result==2){
                System.debug('Ticket assignment failed');
                sendMail('Failure');
                return 3;
            }//if
            else if(result==1){
                System.debug('No available resources');
                sendMail('No Resources');
                return 2;
            }    
            return 0;
        }//try
        catch(Exception e){
            System.debug('Ticket assignment failed: '+e);
            System.debug(' message: '+e.getMessage());
            System.debug('Cause: '+e.getCause());
            sendMail('Failure');
            return 3;
        }
    }//assignOpenTickets
}//class