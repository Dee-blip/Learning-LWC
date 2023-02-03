/*
Author : Nisarga Madhav
Date : 27/10/2016
Description : Class that auto-create tickets for incidents identified by RUEI (the application that monitors Siebel) with default parameters:
Impact = Low
Category = Siebel Issue
Urgency = Severity 2
Short Description = RUEI Alert: [Subject of Email]
Description = [Body of Email]
JIRA tickets : PRTORES-251 & PRTORES-262
Test Class : HD_Test_RUEI_EmailReceive

*/

global class HD_RUEI_EmailReceive implements Messaging.InboundEmailHandler {
    
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, 
                                                         Messaging.Inboundenvelope envelope) {
                                                         
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        BMCServiceDesk__Incident__c incident;
        HD_RUEI_EmailReceive_addr__c siebelruei = HD_RUEI_EmailReceive_addr__c.getInstance('siebelruei');
      
                                                            
        HD_RUEI_EmailReceive_addr__c rueifromaddr = HD_RUEI_EmailReceive_addr__c.getInstance('rueifromaddr');                                                  
        String shortDescription;
        String description;
        User client=null;
        List<BMCServiceDesk__Category__c> categories;
        List<BMCServiceDesk__Urgency__c> urgencies;
        List<BMCServiceDesk__Impact__c> impacts;

        String priority; 
        try
        {
          if(email.fromAddress==rueifromaddr.emailid__c)//(If mail is sent for RUEI Alerts)
          {
            categories = [select Id,Name from BMCServiceDesk__Category__c where Name ='RUEI Alert' LIMIT 1];
            shortDescription = 'RUEI Alert: '+email.subject;
            shortDescription = shortDescription.trim().abbreviate(255);//(the max no of characters for shortDescription field-255)
            description = email.plainTextBody;
            description = description.trim().replaceAll('\n',' ').abbreviate(32000);//(the max no of characters for description field-32000)
            priority = '2';
            try
            {
              client = [select Id from User where email = :siebelruei.emailid__c LIMIT 1];   

            }
            catch(Exception e)
            {
              result.success = true;
            }
                
          }
          urgencies = [select Id,Name from BMCServiceDesk__Urgency__c where Name ='Severity 2' LIMIT 1];
          impacts = [select Id,Name, BMCServiceDesk__inactive__c from BMCServiceDesk__Impact__c where Name = 'LOW' LIMIT 1];
          
          if(client!=null){
            incident = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=categories.get(0).id,BMCServiceDesk__FKClient__c = client.Id,BMCServiceDesk__incidentDescription__c = description, BMCServiceDesk__shortDescription__c = shortDescription,HD_Ticket_Priority__c = priority,  BMCServiceDesk__FKUrgency__c = urgencies.get(0).id, BMCServiceDesk__FKImpact__c = impacts.get(0).id);
            insert incident;  
          }
          
          result.success = true;
                 
        } 
        catch (Exception e)
        {
          result.success = false;
          result.message = 'Failed! Could not generate ticket '+ e.getMessage();
          
        }
    return result;
  }
}