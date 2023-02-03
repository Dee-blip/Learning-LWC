/* 
* File Name: HD_EmailToIncident
* Description : Email handler that creates an Incident from an Email sent to a particular address
* @author : 
* Modification Log ===============================================================
* Date              Author          Modification
* Aug 08th, 2020    Aneesh Budnar   PRTORES-1810 - Code scanner fixes
*/
global class HD_EmailToIncident implements Messaging.InboundEmailHandler {
    
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, 
                                                         Messaging.Inboundenvelope envelope) {
                                                         
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        BMCServiceDesk__Incident__c incident;
        List<Attachment> attachments = new List<Attachment>();                                                     
        HD_Email_Addresses__mdt  emailCat = [SELECT mailId__c ,HD_Category__r.Category__c,HD_Category__r.Parent_Tree__c,HD_Category__r.Priority__c, HD_Category__r.Client_Username__c, HD_Category__r.AddCC__c  from HD_Email_Addresses__mdt  where mailId__c = :email.fromAddress limit 1];
        String shortDescription;
        String description;
        User client;
        BMCServiceDesk__Category__c category;
        String priority; 
        try
        {
          
            category = [select Id,Name from BMCServiceDesk__Category__c where Name = :emailCat.HD_Category__r.Category__c AND  BMCServiceDesk__parentTree__c =:emailCat.HD_Category__r.Parent_Tree__c LIMIT 1];
            shortDescription = email.subject;
            shortDescription = shortDescription.trim().abbreviate(255);//(the max no of characters for shortDescription field-255)
            if(email.plainTextBody == null)
            {
                description = email.htmlBody.stripHtmlTags();
            }
            else{
                
              description = email.plainTextBody;                
            }
            description = description.trim().replaceAll('\n',' ').abbreviate(32000);//(the max no of characters for description field-32000)
            priority = emailCat.HD_Category__r.Priority__c ;
            string userName = '%'+emailCat.HD_Category__r.Client_Username__c+'%';
            client = [select Id from User where Username like :userName LIMIT 1];
            
            incident = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=category.Id,BMCServiceDesk__FKClient__c = client.Id,BMCServiceDesk__incidentDescription__c = description, BMCServiceDesk__shortDescription__c = shortDescription,HD_Ticket_Priority__c = priority,BMCServiceDesk__contactType__c = 'API');
            if(emailCat.HD_Category__r.AddCC__c == true)
            {
                incident.CCText__c = email.fromAddress+';';
            }
            insert incident;
            
/*
            if (email.binaryAttachments != null && email.binaryAttachments.size()<5) {
              for (integer i = 0 ; i < email.binaryAttachments.size() ; i++) {
                  //if(email.binaryAttachments[i].filename)
                  //{
                    System.debug('fileType:'+email.binaryAttachments[i].headers);
                      Attachment attachment = new Attachment();
                      attachment.ParentId = incident.Id;
                      attachment.Name = email.binaryAttachments[i].filename;
                      attachment.Body = email.binaryAttachments[i].body;
                      attachments.add(attachment);
                  //}
                
              }
                insert(attachments);
            }  
        */    
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