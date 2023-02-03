/* Developer @Hemant Barapatre
* Purpose: To update the Incident Service Target Object records , field-> Clock to Stopped once Ticket is closed.
* Below is the snippet for scheduling batch job:
	HD_RectifyPausedSLAOnClosed hdr = new HD_RectifyPausedSLAOnClosed();
	String cronID = Database.scheduleBatch(hdr, 'TEXT HD_RectifyPausedSLAOnClosed_Schedular '+System.now(), 1,1);
* Classed used in : HD_RectifyPausedSLAOnClosed_Schedular.apex
*/
global class HD_RectifyPausedSLAOnClosed implements Database.Batchable<sObject>, Database.Stateful{
    
    List<BMCServiceDesk__Incident_Service_Target__c> updatedISTrecords = new List<BMCServiceDesk__Incident_Service_Target__c>();
    String exceptionMessage = null;
    global final String query;
    
    //constructor
    public HD_RectifyPausedSLAOnClosed(){
        this.query = 'select id,'+
            +'BMCServiceDesk__Incident__c,'
            +'BMCServiceDesk__FKIncident__r.BMCServiceDesk__Status_ID__c, BMCServiceDesk__ClockPauseDate__c,'
            +'BMCServiceDesk__ClockState__c,BMCServiceDesk__StateValue__c,'
            +'CreatedDate  from BMCServiceDesk__Incident_Service_Target__c'
            +' Where BMCServiceDesk__FKIncident__r.BMCServiceDesk__Status_ID__c = \'CLOSED\' ' 
            +'and ( BMCServiceDesk__ClockState__c = \'paused\' OR BMCServiceDesk__ClockState__c = \'running\' ) '
            +'and ( BMCServiceDesk__TargetType__c = \'ResolutionTime\' OR BMCServiceDesk__TargetType__c = \'\')  ORDER BY CreatedDate Desc LIMIT 200';
        
    }//
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<BMCServiceDesk__Incident_Service_Target__c> ISTargetsList){
        for(BMCServiceDesk__Incident_Service_Target__c IST : ISTargetsList){
            //BMCServiceDesk__Incident_Service_Target__c IST = new BMCServiceDesk__Incident_Service_Target__c();
            updatedISTrecords.add(IST);
            IST.BMCServiceDesk__ClockState__c  = 'Stopped';
        }
        system.debug(ISTargetsList);
        try{
            update ISTargetsList;
        }
        catch(exception e)
        {    exceptionMessage = e.getMessage();
         System.debug(e);
         
        }
    }
    
    global void finish(Database.BatchableContext BC){
        if(exceptionMessage != null){
            system.debug('[ERROR]:Job Has finished with the Error ! '+exceptionMessage );
        }
        else
        {   
        // notify();
         system.debug('Job Has finished ! '+updatedISTrecords);
        }
        
    }
    /*
    //a simple method for Sending the batch process details
    global void notify()
    {   
        String htmlBody= null;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(new String[] {'hbarapat@akamai.com'});
        mail.setReplyTo('HDbatchProcess@akamai.com');
        mail.setSenderDisplayName('Batch Processing');
        mail.setSubject('Batch Process Completed');
        htmlBody = '<table width="100%" cellpadding="0" cellspacing="0" style="min-width:100%;">'
            +'<thead>'
            +'<tr>'
            +'<th scope="col" style="padding:5px; font-family: Arial,sans-serif; font-size: 16px; line-height:20px;line-height:30px">SLT Id</th>'
            +'<th scope="col" style="padding:5px; font-family: Arial,sans-serif; font-size: 16px; line-height:20px;line-height:30px">Incident</th>'
            +'<th scope="col" style="padding:5px; font-family: Arial,sans-serif; font-size: 16px; line-height:20px;line-height:30px">Incident Id</th>'
            +'<th scope="col" style="padding:5px; font-family: Arial,sans-serif; font-size: 16px; line-height:20px;line-height:30px">Clock</th>'
            +'<th scope="col" style="padding:5px; font-family: Arial,sans-serif; font-size: 16px; line-height:20px;line-height:30px">State</th>'
            +'</tr>'
            +'</thead>'
            
            +'<tbody>';
            
            

        for(BMCServiceDesk__Incident_Service_Target__c IST : updatedISTrecords)
        {
            htmlBody +='<tr>'
                +'<td valign="top" style="padding:5px; font-family: Arial,sans-serif; font-size: 16px; line-height:20px;">'+IST.Id+'</td>'
                +'<td valign="top" style="padding:5px; font-family: Arial,sans-serif; font-size: 16px; line-height:20px;">'+IST.BMCServiceDesk__Incident__c+'</td>'
                +'<td valign="top" style="padding:5px; font-family: Arial,sans-serif; font-size: 16px; line-height:20px;">'+IST.BMCServiceDesk__FKIncident__c+'</td>'
                +'<td valign="top" style="padding:5px; font-family: Arial,sans-serif; font-size: 16px; line-height:20px;">'+IST.BMCServiceDesk__ClockState__c+'</td>'
                +'<td valign="top" style="padding:5px; font-family: Arial,sans-serif; font-size: 16px; line-height:20px;">'+IST.BMCServiceDesk__StateValue__c+'</td>'
            +'</tr>';            
        }
                    
         htmlBody +='</tbody>'
                    +'</table>';
        mail.setHtmlBody(htmlBody);
            //mail.setPlainTextBody('Batch Process has completed '+updatedISTrecords);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }//
    */
    
    
}//END