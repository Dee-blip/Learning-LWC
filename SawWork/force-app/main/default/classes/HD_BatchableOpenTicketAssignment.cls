global class HD_BatchableOpenTicketAssignment implements Database.Batchable<SObject>{

    global final String query;
    global final String fieldToUpdate;
    global final List<Id> updatedIncidentIds;
    global final Map<Id,Id> incOwnerMap;
    global final String incidentIdMsg;
    global final String updatedIncidentMsg;
    global final String usedRsrcMsg;
    global final Map<String,String> emailContentMap;
    
    global HD_BatchableOpenTicketAssignment(String q, String field,List<Id> incidentIds, Map<Id,Id> incMap, String incidentIdString, String updatedIncidentString, String usedResourceString,Map<String,String> emailMap){
        System.debug('In batchable constructor');
        query=q;
        System.debug('Query: '+query);
        fieldToUpdate=field;
        System.debug('fieldToUpdate: '+fieldToUpdate);
        updatedIncidentIds=incidentIds;
        System.debug('updatedIncidentIds: '+updatedIncidentIds);
        incOwnerMap=incMap;
        System.debug('incOwnerMap: '+incOwnerMap);
        incidentIdMsg=incidentIdString;
        updatedIncidentMsg=updatedIncidentString;  
        usedRsrcMsg=usedResourceString;
        System.debug('emailMap: '+emailMap);
        emailContentMap=emailMap;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
      System.debug('In Batchable start');  
        System.debug('Query: '+query);
         System.debug('fieldToUpdate: '+fieldToUpdate);
         System.debug('updatedIncidentIds: '+updatedIncidentIds);
      return Database.getQueryLocator(query);
    }  
    
    global void execute(Database.BatchableContext BC, List<BMCServiceDesk__Incident__c> scope){
        System.debug('In execute');
        for(BMCServiceDesk__Incident__c inc:scope){
            Id value=incOwnerMap.get(inc.Id);
            System.debug('Value= '+value);
            inc.put(fieldToUpdate,value);
            inc.put('isAssingedByRoundRobin__c',true);
        }
        update scope;
    }
    
    global void finish( Database.BatchableContext BC )
    {
        System.debug('In Batchable Finish');
        sendMail();
    }

    global void sendMail()
    {
        System.debug('In send mail');
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for(String teamEmail:emailContentMap.keySet()){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>();
        sendTo.add(teamEmail);
        mail.setToAddresses(sendTo);
        mail.setSenderDisplayName('Ticket Assignment Job');
        mail.setSubject('AUTOMATED TICKET ALLOCATION');
        String body;
        body = 'Automated ticket allocation job has run successfully. Following are the details<br/>';
        body +=  emailContentMap.get(teamEmail)+'<br/>';
        //body += updatedIncidentMsg+'<br/>';
        //body += usedRsrcMsg;
        mail.setHtmlBody(body);
        mails.add(mail);
        }
        /*
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>();
        sendTo.add(System.UserInfo.getUserEmail());
        mail.setToAddresses(sendTo);
        mail.setSenderDisplayName('Ticket Assignment Job');
        mail.setSubject('AUTOMATED TICKET ALLOCATION');
        String body;
        body = 'Automated ticket allocation job has run successfully. Following are the details<br/>';
        body +=  incidentIdMsg+'<br/>';
        body += updatedIncidentMsg+'<br/>';
        body += usedRsrcMsg;
        mail.setHtmlBody(body);
        mails.add(mail);
*/
        System.debug('Sending mail now');
        Messaging.sendEmail(mails);
    }
}