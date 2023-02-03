/*
* File Name: HD_Change_Client_when_Terminated
* Description : Client changed from terminated employee to their manager on all open tickets and mail triggered to the manager.
* @author : Amogh M P
* Test Class : HD_Test_Change_Client_when_Terminated
* Scheduler Class : HD_Change_Client_Terminated_Scheduler
*/

public without sharing class HD_Change_Client_when_Terminated {

    Map<Id,String> managerIdEmail = new Map<Id,String>();
    Map<String,String> managerEmailName = new Map<String,String>();
    Map<Id,String> clientIdName = new Map<Id,String>();
    Map<Id,Id> clientManagerMap = new Map<Id,Id>();
    
    //BEGIN: Method to find out the inactive users and their corresponding open corpIT tickets.
    public void changeClientWithEmailAlert(){
        
        List<Id> userIds = new List<Id>();
        Map<Id,List<BMCServiceDesk__Incident__c>> idIncidentsMap = new Map<Id,List<BMCServiceDesk__Incident__c>>();
        List<String> categories = new List<String>();
        List<String> categoryTypes = new List<String>();
        
        try{
        DateTime lastSeen = System.now() - 3;
          
        for(User u : [Select Id, Name, ManagerId, Manager.Name, Manager.IsActive, Manager.Email, Manager.ManagerId, Manager.Manager.Email, Manager.Manager.Name, IsActive, LastModifiedDate, Inactivated_On__c 
                      from User 
                      where IsActive = FALSE 
                      and Inactivated_On__c >= :lastSeen 
                      and ManagerId != NULL])
        {
            clientIdName.put(u.Id, u.Name);
            if(u.Manager.IsActive == TRUE){
            	clientManagerMap.put(u.Id,u.ManagerId);
                managerIdEmail.put(u.ManagerId,u.Manager.Email);
            	managerEmailName.put(u.Manager.Email,u.Manager.Name);
            }
            else{
                clientManagerMap.put(u.Id,u.Manager.ManagerId);
                managerIdEmail.put(u.Manager.ManagerId,u.Manager.Manager.Email);
            	managerEmailName.put(u.Manager.Manager.Email,u.Manager.Manager.Name);
            }
            userIds.add(u.Id);
        }

        for(HDEmailAlertForTicketsExcceding__mdt emailAlertCustMetaData : [SELECT Categories__c, Category_Type__c  FROM HDEmailAlertForTicketsExcceding__mdt WHERE Job_Name__c  = 'HD_Change_Client_when_Terminated']){
            if(!String.isEmpty(emailAlertCustMetaData.Categories__c)){
            	categories.addAll(emailAlertCustMetaData.Categories__c.split(','));
            }
            if(!String.isEmpty(emailAlertCustMetaData.Category_Type__c)){
            	categoryTypes.addAll(emailAlertCustMetaData.Category_Type__c.split(','));
            }
        }

        for(BMCServiceDesk__Incident__c inc : [Select Id, Name, BMCServiceDesk__FKClient__c, BMCServiceDesk__Client_Manager__c, BMCServiceDesk__Client_Manager__r.Name, BMCServiceDesk__Client_Name__c, HD_Owner_user_queue__c, BMCServiceDesk__shortDescription__c, BMCServiceDesk__incidentDescription__c, BMCServiceDesk__Type__c, HD_Client_title__c, HD_Client_City__c, BMCServiceDesk__Category_ID__c, HD_Parent_Tree__c, BMCServiceDesk__openDateTime__c, BMCServiceDesk__dueDateTime__c, HD_Ticket_Priority__c
                         					   from BMCServiceDesk__Incident__c 
                         					   where BMCServiceDesk__Status_ID__c != 'CLOSED' 
                         					   AND BMCServiceDesk__Status_ID__c != 'RESOLVED' 
                         					   AND Record_Type__c != 'Service Incident'
                         					   AND BMCServiceDesk__FKClient__c IN :userIds
                         					   AND (HD_IncidentGroup__c IN :categoryTypes OR BMCServiceDesk__Category_ID__c IN :categories)])
        {             
            if(idIncidentsMap.containsKey(inc.BMCServiceDesk__FKClient__c)){
                List<BMCServiceDesk__Incident__c> clientIncidents = idIncidentsMap.get(inc.BMCServiceDesk__FKClient__c);
                clientIncidents.add(inc);
                idIncidentsMap.put(inc.BMCServiceDesk__FKClient__c, clientIncidents);
            }
            else{
                idIncidentsMap.put(inc.BMCServiceDesk__FKClient__c, new List<BMCServiceDesk__Incident__c> { inc });
            }
        }

        createManagerClientMap(idIncidentsMap);
        changeClient(idIncidentsMap);
        }
        catch(Exception e)
        {
            System.debug(System.LoggingLevel.ERROR,'Error Message' + e.getMessage());
        }
    }
    //END
    
    //BEGIN: Method to change client from terminated employee to their manager.
    private void changeClient(Map<Id,List<BMCServiceDesk__Incident__c>> idIncidentsMap){
        
        List<BMCServiceDesk__Incident__c> updatedIncidents = new List<BMCServiceDesk__Incident__c>();
        for(Id idValue : idIncidentsMap.keySet())
        {
            for(BMCServiceDesk__Incident__c inc : idIncidentsMap.get(idValue))
            {
                inc.BMCServiceDesk__FKClient__c = clientManagerMap.get(idValue);
                updatedIncidents.add(inc);
            }
        }
        //System.debug('Updating Client');
        Database.update(updatedIncidents,false);
    }
    //END
    
    //BEGIN: Method to create map of Manager and client tickets who are terminated.
    private void createManagerClientMap(Map<Id,List<BMCServiceDesk__Incident__c>> idIncidentsMap){
        
        Map<String,Map<Id,List<BMCServiceDesk__Incident__c>>> managerIncidentsMap = new Map<String,Map<Id,List<BMCServiceDesk__Incident__c>>>();
        for(Id idValue : idIncidentsMap.keySet())
        {
        	Id managerId = clientManagerMap.get(idValue);
            String managerEmail = managerIdEmail.get(managerId);
            
            if(managerIncidentsMap.containsKey(managerEmail)){
                Map<Id,List<BMCServiceDesk__Incident__c>> clientIncident = managerIncidentsMap.get(managerEmail); //old map
                clientIncident.put(idValue, idIncidentsMap.get(idValue));
                managerIncidentsMap.put(managerEmail, clientIncident);
            }
            else{
                Map<Id,List<BMCServiceDesk__Incident__c>> clientIncident = new Map<Id,List<BMCServiceDesk__Incident__c>>();
                clientIncident.put(idValue, idIncidentsMap.get(idValue));
                managerIncidentsMap.put(managerEmail, clientIncident);
            }
        }
        sendMail(managerIncidentsMap);
    }
    //END
    
    //BEGIN: Method to trigger mail to the manager.
    private void sendMail(Map<String,Map<Id,List<BMCServiceDesk__Incident__c>>> managerIncidentsMap){
        
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        for(String managerEmail : managerIncidentsMap.keySet()){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> sendTo = new List<String>();
            sendTo.add(managerEmail);
            mail.setToAddresses(sendTo);
            mail.setSenderDisplayName('Helpdesk Automated Job');
            String ebody1 = '';
            mail.setSubject('Helpdesk tickets open for terminated user');
       
            String managerName = managerEmailName.get(managerEmail);
            ebody1 += '<p style="font-size:15px;">Hello ' + managerName + ',</p>';
            ebody1 += '<p style="font-size:15px;">You have been designated as Client for the below tickets. They were opened for terminated user and is currently open for action.</p>';
            ebody1 += '<p style="font-size:15px;">Please advise further action to Ticket\'s Owner so that we can assist further and work towards effective closure.</p>';
            ebody1 += '<br>';
            ebody1 += '<p style="font-size:15px;">The Terminated employee name, their ticket number, owner of the ticket and other details have been shown below: <p>';
            ebody1 += '<table bordercolor="black" border=1 bgcolor="#f2f2f2"><thead><tr><th><h3>Terminated Employee Name</h3></th><th><h3>Ticket Number</h3></th><th><h3>Owner</h3></th><th><h3>Ticket Details</h3></th></tr></thead>';
            ebody1 += '<tbody>';
            
            for(Id clientId : managerIncidentsMap.get(managerEmail).keySet()){
                integer size = managerIncidentsMap.get(managerEmail).get(clientId).size();
                
                String clientName = clientIdName.get(clientId);
                ebody1 += '<tr><td rowspan="' + size + '">' + clientName;
                
                for(BMCServiceDesk__Incident__c inc : managerIncidentsMap.get(managerEmail).get(clientId)){
                    String ebody = '';
                    ebody += '<br>Ticket Type: ' + inc.BMCServiceDesk__Type__c;
                    ebody += '<br>Short Description: '+ inc.BMCServiceDesk__shortDescription__c;
                    ebody += '<br>Description: '+ inc.BMCServiceDesk__incidentDescription__c;
                    ebody += '<br>Client Name: '+ inc.BMCServiceDesk__Client_Name__c;
                    ebody += '<br>Client Title: '+ inc.HD_Client_title__c;
                    ebody += '<br>Client Manager: '+ inc.BMCServiceDesk__Client_Manager__r.Name;
                    ebody += '<br>Client City : '+ inc.HD_Client_City__c;
                    ebody += '<br>Category: '+ inc.BMCServiceDesk__Category_ID__c;
                    ebody += '<br>Category Tree: '+ inc.HD_Parent_Tree__c;
                    ebody += '<br>Open Date: '+ inc.BMCServiceDesk__openDateTime__c;
                    ebody += '<br>Due Date: '+ inc.BMCServiceDesk__dueDateTime__c;
                    ebody += '<br>Priority: '+ inc.HD_Ticket_Priority__c;
                    ebody += '<br><br>Link to Incident: ' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '?startURL=/apex/bmcservicedesk__ssredirect?inc=' + inc.Id + '">' + inc.Name + '</a>';
                    ebody += '<br>Link to Incident (Lightning view): ' + '<a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/BMCServiceDesk__Incident__c/' + inc.Id + '/view">' + inc.Name + '</a>';
                    ebody += '<br><br>';

                    ebody1 += '</td><td>' + inc.Name + '</td><td>' + inc.HD_Owner_user_queue__c + '</td><td>' + ebody + '</td></tr>';
                    
                }
            }
            mail.setHtmlBody(ebody1);
            mailList.add(mail);
        }
        //System.debug('Sending mail now');
        Messaging.sendEmail(mailList);
    }
    //END
}