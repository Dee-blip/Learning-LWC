/*
* Object: HD_Survey_Response__c
* Details : Helper class for HD_SurveyResponseTriggerHandler.
* 
* Developer      Date      Version    Update 
* kimishra      06/13/2020    1.0      Initial version
*
* 
*/
public class HD_SurveyResponseTriggerHelper {
    private static Map<Id, BMCServiceDesk__Incident__c> incidentMap;
    private static Map<Id, User> userMap;
    private static EmailTemplate emailTemplate;
    
    //Lazy Initialization starts
    private static Map<Id, BMCServiceDesk__Incident__c> getIncidentMap(Set<Id> incidentIds){
        if(incidentMap == null){
            incidentMap = new Map<Id, BMCServiceDesk__Incident__c>([SELECT Id, HD_Owner_Manager__c,
                                                                    HD_Owner_Manager__r.Id, OwnerId
                                                                    FROM BMCServiceDesk__Incident__c
                                                                    WHERE Id IN :incidentIds]);
        }
        return incidentMap;
    }
    
    private static Map<Id, User> getUserMap(Set<Id> userIds){
        if(userMap == null){
            userMap = new Map<Id, User>([SELECT Id, Email
                                         FROM User
                                         WHERE Id IN :userIds]);
        }
        return userMap;
    }
    
    private static EmailTemplate getNegativeResponseEmailTemplate() {
        emailTemplate = [SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body 
                         FROM EmailTemplate 
                         WHERE DeveloperName = :System.Label.HD_ITOC_SurveyNegativeResponse  LIMIT 1];
        return emailTemplate;
    }
    
    //Lazy Initialization ends
    
    //methods start
    
    //method to send custom notification to the incident owner manager
    public static void sendCustomNotification(Map<Id, SObject> newItems){
        Set<Id> incidentIds = new Set<Id>();
        Map<Id, List<HD_Survey_Response__c>> incIdResponseMap = new Map<Id, List<HD_Survey_Response__c>>();
        Set<Id> sendEmailIncidentIds = new Set<Id>();
        
        //send email only for responses that have average value less than equal to 4 i.e 1,2,3,4
        //to calculate the average response value - create a map of incident and response records
        for(HD_Survey_Response__c resp : (List<HD_Survey_Response__c>) newItems.values()) {
            List<HD_Survey_Response__c> tempList = new List<HD_Survey_Response__c>();
            
            if(resp.Team_Tag__c == System.Label.HD_ITOC && resp.Field_Type__c == System.Label.HD_Star ) {
                if(incIdResponseMap.containsKey(resp.Incident__c)){
                    tempList = incIdResponseMap.get(resp.Incident__c);
                } 
                tempList.add(resp);
                incIdResponseMap.put(resp.Incident__c, tempList);
            }
        }
        
        //get the average rating per incident
        for(Id incId : incIdResponseMap.keySet()) {
            Decimal totalRating = 0.0;
            Integer count = 0;
            Decimal avgRating = 0.0;
            
            for(HD_Survey_Response__c resp : incIdResponseMap.get(incId)) {
                count++;
                totalRating += Decimal.valueOf(resp.Response__c);
            }
            avgRating = totalRating/count;
            
            //store the incident value if the rating is <=4
            if(avgRating < 4) {
                sendEmailIncidentIds.add(incId);
            }
        }
        
        //if any incident has rating below 4, send email to the manager
        if(!sendEmailIncidentIds.isEmpty()) {
            try{
                Set<Id> userIds = new Set<Id>();
                List<Messaging.SingleEmailMessage> messagesList = new List<Messaging.SingleEmailMessage>();
                //query details for the list of incidents
                incidentMap = getIncidentMap(sendEmailIncidentIds);
                //get email template
                emailTemplate = getNegativeResponseEmailTemplate();
                
                //get all incident's owner and owner manager user id
                for(BMCServiceDesk__Incident__c inc : incidentMap.values()) {
                    userIds.add(inc.HD_Owner_Manager__c);
                    userIds.add(inc.OwnerId);
                }
                
                if(!userIds.isEmpty() && emailTemplate != NULL) {
                    
                    userMap = getUserMap(userIds);
                    //create a list of the target and recipient ids
                    for(BMCServiceDesk__Incident__c inc : incidentMap.values()) {
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.setTemplateId(emailTemplate.Id);
                        message.setTargetObjectId(inc.HD_Owner_Manager__r.Id);
                        
                        //send to owner and owner's manager's email
                        List<String> toAddress = new List<String>();
                        if(userMap.containsKey(inc.HD_Owner_Manager__r.Id)){
                            toAddress.add(userMap.get(inc.HD_Owner_Manager__r.Id).Email); 
                        }
                        message.setToAddresses(toAddress);
                        message.setTreatTargetObjectAsRecipient(false);
                        message.setWhatId(inc.Id);
                        //don't create activity
                        message.setSaveAsActivity(false);
                        
                        //add to messaging list
                        messagesList.add(message);
                    }
                    if(!messagesList.isEmpty()) {
                        Messaging.SendEmailResult[] mailResults = Messaging.sendEmail(messagesList);
                    }
                }
            }
            catch(Exception ex){
                System.debug('--Exception in HD_SurveyResponseTriggerHandler Class--');
                System.debug('Line Number :'+ex.getLineNumber());
                System.debug('Message :'+ex.getMessage());
            }
        }
    }
    //method end
}