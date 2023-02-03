/*
* File Name: HD_GenericIncidentMailer
* Description : Custom Generic Email Service to create incident and also co-relate existing incidents.
* @author : Amogh M P
* Test Class : HD_Test_GenericIncidentMailer
*/

global without sharing class HD_GenericIncidentMailer implements Messaging.InboundEmailHandler {
    
    BMCServiceDesk__Category__c mainCategory;
    String mainDescription;
    String mainPriority;
    
    //Method to add note on the existing ticket.
    private void constructNote(BMCServiceDesk__Incident__c existingIncident,BMCServiceDesk__Incident__c incident,Boolean latestNote){

        String note;
        BMCServiceDesk__Action__c actionId = [SELECT Id, Name from BMCServiceDesk__Action__c where Name = 'Notes' LIMIT 1];
        String description = 'Notes';
        if(latestNote){
        	List<String> latestEmail = incident.BMCServiceDesk__incidentDescription__c.split('From: "');
            if(latestEmail != null){
            	note = 'Reply Email content:'+'\n'+ latestEmail[0];
        	}
            else{
                note = 'Reply Email content:'+'\n'+ incident.BMCServiceDesk__incidentDescription__c;
            }
        }
        else{
            note = 'Duplicate Email content:'+'\n'+incident.BMCServiceDesk__incidentDescription__c;
        }
        BMCServiceDesk__IncidentHistory__c actionNote = new BMCServiceDesk__IncidentHistory__c(BMCServiceDesk__FKAction__c = actionId.Id, BMCServiceDesk__description__c = description, BMCServiceDesk__note__c = note, BMCServiceDesk__FKIncident__c = existingIncident.Id);
        insert actionNote;
    }
    
    //Method to construct Incident detail map corresponding to unique factors.
    private Map<String,String> constructDetailMap(BMCServiceDesk__Incident__c incident, List<String> listUniqueFactors){
        Map<String,String> uniqueDetailmap = new Map<String,String>();
        List<String> descDetails = incident.BMCServiceDesk__incidentDescription__c.split('\n');
        for(String eachDesc : descDetails){
            List<String> e = eachDesc.trim().split(':');
            if(listUniqueFactors.contains(e[0])){
            	uniqueDetailmap.put(e[0],e[1]);
            }
        }
        return uniqueDetailmap;
    }
    
    //Method to compare the existing tickets.
    private Boolean checkMatchingFactors(BMCServiceDesk__Incident__c incident, Map<String,String> uniqueDetailmap, Boolean latestNote, Messaging.InboundEmail email){
        for(BMCServiceDesk__Incident__c existingIncident : [SELECT BMCServiceDesk__incidentDescription__c 
                                                            FROM BMCServiceDesk__Incident__c 
                                                            WHERE BMCServiceDesk__FKCategory__c = :incident.BMCServiceDesk__FKCategory__c
                                                            AND BMCServiceDesk__FKClient__c = :incident.BMCServiceDesk__FKClient__c
                                                            AND BMCServiceDesk__Status_ID__c != 'CLOSED' 
                         					   				AND BMCServiceDesk__Status_ID__c != 'RESOLVED' 
                         					   				AND Record_Type__c != 'Service Incident'
                                                            ORDER BY Opened_Date_For__c DESC LIMIT 1000]){
                                         
        	Map<String,String> existingUniqueDetailmap = new Map<String,String>();                                                   
            if(existingIncident.BMCServiceDesk__incidentDescription__c != NULL){                                                    
            	List<String> existingDescDetails = existingIncident.BMCServiceDesk__incidentDescription__c.split('\n');
        		for(String eachDesc : existingDescDetails){
            		List<String> e = eachDesc.trim().split(':');
                	if(uniqueDetailmap.keySet().contains(e[0])){
                		existingUniqueDetailmap.put(e[0],e[1]);
                	}
        		}
	        }                                                      
            if(uniqueDetailmap.equals(existingUniqueDetailmap)){
            	createActionEmail(email,existingIncident);
                constructNote(existingIncident,incident,latestNote);
                return TRUE;                                                        
            }                                                    
		}
        return FALSE;
    }
    
    //Method to check if any existion ticket exists with the mentioned unique factors in the body. 
    private Boolean matchingUniqueFactors(BMCServiceDesk__Incident__c incident, HD_Email_Addresses__mdt emailCat, Messaging.InboundEmail email){

        Boolean match = FALSE;
        String uniqueFactors = emailCat.Unique_Factors__c;
        List<String> listUniqueFactors = uniqueFactors.split(',');
        Map<String,String> uniqueDetailmap = constructDetailMap(incident,listUniqueFactors);
		
        if(uniqueDetailmap.size() == listUniqueFactors.size()){
            match = checkMatchingFactors(incident,uniqueDetailmap,emailCat.Note_with_latest_Email__c,email);
        }
        return match;
    }
    
    //Method to check if any existion ticket exists with the mentioned unique factors in the subject.
    private Boolean matchingUniqueFactorsSubject(BMCServiceDesk__Incident__c incident, HD_Email_Addresses__mdt emailCat, Messaging.InboundEmail email){
        String subjectUniqueFactors = emailCat.Subject_Unique_Factors__c;
        String matcher;
        Pattern p = Pattern.compile(subjectUniqueFactors);
        Matcher m;
        if(emailCat.Check_body_without_map__c){
            if(email.plainTextBody != NULL){
            	m = p.matcher(email.plainTextBody.replaceAll('\n', '-->n'));
            }
            else{
                m = p.matcher(email.htmlBody.replaceAll('\n', '-->n'));
            }
        }
        else{
            m = p.matcher(incident.BMCServiceDesk__shortDescription__c);
        }
    	if(m.matches()){
            matcher = '%'+m.group(1)+'%';
            String categoryId = incident.BMCServiceDesk__FKCategory__c;
            String soqlSubject = 'SELECT BMCServiceDesk__shortDescription__c FROM BMCServiceDesk__Incident__c WHERE BMCServiceDesk__shortDescription__c LIKE :matcher AND BMCServiceDesk__FKCategory__c = :categoryId AND Record_Type__c != \'Service Incident\'';
            if(emailCat.Resolved_and_Closed__c){
                soqlSubject += ' AND BMCServiceDesk__Status_ID__c != \'CLOSED\' AND BMCServiceDesk__Status_ID__c != \'RESOLVED\' ORDER BY Opened_Date_For__c DESC';
            }
            soqlSubject += ' LIMIT 1';
            List<BMCServiceDesk__Incident__c> existingIncident = database.query(soqlSubject);
            
            if(existingIncident.size()>0){
                createActionEmail(email,existingIncident[0]);
                constructNote(existingIncident[0],incident,emailCat.Note_with_latest_Email__c);
        		return TRUE;    
            }
    	}
        return FALSE;
    }
    
    //Method to parse the body of the map and create a map.
    private Map<String,String> createBodyMap(String body){
        Map<String,String> incDetailmap = new Map<String,String>();
        List<String> incidentDetails = body.split('#');
        if(incidentDetails.size() > 1){
        	for(Integer i=0; i<incidentDetails.size(); i+=2){
            	incDetailmap.put(incidentDetails[i],incidentDetails[i+1]);
        	}
        }
        return incDetailmap;
    }
    
    //Method to set the category.
    private BMCServiceDesk__Category__c setCategory(String cat){
        return [Select Id,Name from BMCServiceDesk__Category__c where Name = :cat LIMIT 1];
    }
    
    //Method to set the parent category.
    private BMCServiceDesk__Category__c setCategoryWithParent(String cat, String parentCategory){
        return [Select Id,Name from BMCServiceDesk__Category__c where Name = :cat AND BMCServiceDesk__parentTree__c =:parentCategory LIMIT 1];
    }
    
    //Method to set short description.
    private String setShortDescription(String subject){
        return subject.trim().abbreviate(255);
    }
    
    //Method to set description.
    private String setDescription(String body){
        return body.trim().abbreviate(32000);
    }
    
    //Method to set priority.
    private String setPriority(String urgency){
        String priority;
        if(urgency == 'Severity 4'){
            priority = '4';
        }else if(urgency == 'Severity 3'){
            priority = '3';
        }else if(urgency == 'Severity 2'){
            priority = '2';
        }else{
            priority = '1';}
        return priority;
    }
    
    //Method to set the client.
    private User setClient(String clientUsername){
        return [select Id from User where Username = :clientUsername LIMIT 1];
    }
    
    //Method to set CC address.
    private String setCC(List<String> ccAddresses){
        String ccAddress = '';
        for(String cc : ccAddresses)
        {
        	ccAddress += cc + ';';
        }
        return ccAddress;
    }
    
    //Method to add email action on the ticket.
    private void createActionEmail(Messaging.InboundEmail email, BMCServiceDesk__Incident__c incident){
        BMCServiceDesk__Action__c actionId = [SELECT Id, Name from BMCServiceDesk__Action__c where Name = 'Email Received' LIMIT 1];
        String actionDescription = 'Email Received-' + email.subject;
        String note = ' ';
        note += 'From: ' + email.fromAddress + '\n';
        note += 'To: ' + email.toAddresses + '\n';
        if(email.ccAddresses != NULL){
        	note += 'CC: ' + email.ccAddresses + '\n';
        }else{
            note += 'CC: ' + '\n';
        }
        note += 'Subject: ' + email.subject + '\n\n';
        if(email.plainTextBody != NULL){
        	note +=  email.plainTextBody.replaceAll('\n', '-->n').stripHtmlTags().replaceAll('-->n', '\n');
        }
        else{
            note +=  email.htmlBody.replaceAll('\n', '-->n').stripHtmlTags().replaceAll('-->n', '\n');
        }
        BMCServiceDesk__IncidentHistory__c actionEmail = new BMCServiceDesk__IncidentHistory__c(BMCServiceDesk__FKAction__c = actionId.Id, BMCServiceDesk__description__c = actionDescription, BMCServiceDesk__note__c = note, BMCServiceDesk__FKIncident__c = incident.Id);
        insert actionEmail;
    }
    
    //Method to construct incident with template
    private void constructIncidentBmcTemplate(String body, HD_Email_Addresses__mdt emailCat){
        
        Map<String,String> incDetailmap = createBodyMap(body);
        if(incDetailmap.containsKey('Category') && incDetailmap.get('Category').trim() != ''){
        	mainCategory = setCategory(incDetailmap.get('Category').trim());
        }else{
        	mainCategory = setCategoryWithParent(emailCat.HD_Category__r.Category__c,emailCat.HD_Category__r.Parent_Tree__c);
        }
        if(incDetailmap.containsKey('Description') && incDetailmap.get('Description').trim() != ''){
			mainDescription = setDescription(incDetailmap.get('Description').trim());
        }else{
            mainDescription = setDescription(body);
        }
        if(incDetailmap.containsKey('Urgency') && incDetailmap.get('Urgency').trim() != ''){
        	mainPriority = setPriority(incDetailmap.get('Urgency').trim());
        }else{
            mainPriority = emailCat.HD_Category__r.Priority__c;
        }
    }
    
    //Method to construct incident without template.
    private void constructIncidentNoTemplate(String body, HD_Email_Addresses__mdt emailCat){
        mainCategory = setCategoryWithParent(emailCat.HD_Category__r.Category__c,emailCat.HD_Category__r.Parent_Tree__c);
        mainDescription = setDescription(body);
        mainPriority = emailCat.HD_Category__r.Priority__c;
    }
    
    //Method to find out if incident should be created or not based on the criteria. 
    private HD_Email_Addresses__mdt incidentToBeCreated(String body, Messaging.InboundEmail email){
        for(HD_Email_Addresses__mdt emailMultiple : [SELECT mailId__c ,HD_Category__r.Category__c,HD_Category__r.Parent_Tree__c, HD_Category__r.Client_Username__c, HD_Category__r.AddCC__c,HD_Category__r.Priority__c, Co_Relate__c, Unique_Factors__c, Subject_Co_Relate__c, Subject_Unique_Factors__c, Follow_BMC_Template__c, Note_with_latest_Email__c, Sequence__c, Check_body_without_map__c, Resolved_and_Closed__c from HD_Email_Addresses__mdt where mailId__c = :email.fromAddress ORDER BY Sequence__c ASC]){
            if(String.isNotBlank(emailMultiple.Subject_Unique_Factors__c) && !emailMultiple.Check_body_without_map__c ){
                String matcher;
        		Pattern p = Pattern.compile(emailMultiple.Subject_Unique_Factors__c);
				Matcher m = p.matcher(email.subject);
                if(m.matches()){
                    return emailMultiple;
                }
            }
            else if(String.isNotBlank(emailMultiple.Unique_Factors__c)){
                List<String> listUniqueFactors = emailMultiple.Unique_Factors__c.split(',');
                integer count = 0;
                for(String uniqueFactors : listUniqueFactors){
                    if(body.contains(uniqueFactors)){
                        count++;
                    }
                }
                if(count == listUniqueFactors.size()){
                    return emailMultiple;
                }
            }
            else{
                return emailMultiple;
            }
        }
        return NULL;
    }
    
    //Main Method of the inbound email.
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.Inboundenvelope envelope){
    
    	Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        String shortDescription;
        User client;
        String ccAddress='';
        BMCServiceDesk__Incident__c incident;

        String body;
        if(email.plainTextBody != NULL){
        	body = email.plainTextBody.replaceAll('\n', '-->n').stripHtmlTags().replaceAll('-->n', '\n');
        }
        else{
            body = email.htmlBody.replaceAll('\n', '-->n').stripHtmlTags().replaceAll('-->n', '\n');
        }
        
        HD_Email_Addresses__mdt emailCat = incidentToBeCreated(body,email);
        
        if(emailCat != NULL){
        Boolean appendInfo = TRUE;
        
        try{    
            if(emailCat.Follow_BMC_Template__c){
                constructIncidentBmcTemplate(body,emailCat);
            }
            else{
                constructIncidentNoTemplate(body,emailCat);
            }
            shortDescription = setShortDescription(email.subject);
 			client = setClient(emailCat.HD_Category__r.Client_Username__c);

            if(email.ccAddresses != NULL){
                ccAddress = setCC(email.ccAddresses);
            }

        	incident = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=mainCategory.Id,BMCServiceDesk__FKClient__c = client.Id,BMCServiceDesk__incidentDescription__c = mainDescription, BMCServiceDesk__shortDescription__c = shortDescription,HD_Ticket_Priority__c = mainPriority,CCText__c = ccAddress,BMCServiceDesk__contactType__c = 'API');

        	if(emailCat.Co_Relate__c){
        		appendInfo = matchingUniqueFactors(incident,emailCat,email);
            }
            else if(emailCat.Subject_Co_Relate__c){
                appendInfo = matchingUniqueFactorsSubject(incident,emailCat,email);
            }
        	
            if((!appendInfo || (!emailCat.Co_Relate__c && !emailCat.Subject_Co_Relate__c)) && !emailCat.Check_body_without_map__c ){
            	insert incident;
                createActionEmail(email,incident);
        	}
            else{
                String nonCreatedIncident = email.fromAddress + '\n' + email.toAddresses + '\n' + email.subject + '\n' + body;
                HD_UX_Exception_LoggerCls.logErrorRecord('Incident not created as criteria did not match.',nonCreatedIncident,null);
            }
        	result.success = true;
        }
        
        catch(Exception e){
            result.success = false;
          	result.message = 'Failed! Could not generate ticket '+ e.getMessage();
            HD_UX_Exception_LoggerCls.logErrorRecord(e.getMessage(),e.getStackTraceString(),null);
        }
        }
        else{
            String nonCreatedIncident = email.fromAddress + '\n' + email.toAddresses + '\n' + email.subject + '\n' + body;
            HD_UX_Exception_LoggerCls.logErrorRecord('Incident not created as configuration did not match.',nonCreatedIncident,null);
        }
    return result;
    }
}