public class HD_BatchableAutomatedTicketAssignment implements Database.Batchable<SObject> {
    public final map<Id,Id> incOwnerMap ;
    public final List<Id> updatedIncidentsList;
    public final map<string,string> emailToQueueMap;
    public final string queryString;
    public HD_BatchableAutomatedTicketAssignment(string query,List<Id> incidentsList,map<Id,Id> incidentOwnerMap,map<string,string> emailMap){
        incOwnerMap = new map<id,id>(incidentOwnerMap);
        emailToQueueMap = new map<string,string>(emailMap);
        updatedIncidentsList = new List<Id>(incidentsList);
        queryString = query;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        system.debug(queryString);
        system.debug(updatedIncidentsList);
        return Database.getQueryLocator(queryString);
    }
    
    public void execute(Database.BatchableContext BC, List<BMCServiceDesk__Incident__c> scope){
        
        for(BMCServiceDesk__Incident__c incident: scope){
            Id ownerId = incOwnerMap.get(incident.Id);
            system.debug(ownerId);
            incident.put('OwnerId', ownerId);
            incident.put('isAssingedByRoundRobin__c',true);
        }
        update scope;
    }
    
    public void finish(Database.BatchableContext BC){
        sendEmailToQueue();
    }
    
    public void sendEmailToQueue(){
        
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        for( string queueEmail: emailToQueueMap.keySet()){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<string> toAddressList = new List<string>();
            toAddressList.add(queueEmail);
            mail.setToAddresses(toAddressList);
            mail.setSenderDisplayName('Automated Ticket Allocation Job');
            mail.setSubject('AUTOMATED TICKET ALLOCATION');
            mail.setHtmlBody(emailToQueueMap.get(queueEmail));
            emailMessages.add(mail);
        }
        messaging.sendEmail(emailMessages);
    }
   
    
}