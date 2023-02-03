/* 
* File Name: HD_Incident_Pending_Approval_Reminder
* Description : 
* @author : 
* Modification Log ===============================================================
* Date              Author          Modification
*                   Kirti mishra    Line 239 & 255 Update for Story PRTORES-1378
* Aug 08th, 2020    Aneesh Budnar   PRTORES-1810 - Code scanner fixes
*/
public class HD_Incident_Pending_Approval_Reminder {

    static MAP<Id,sObject>  SOIncidents = new MAP<Id,sObject>();
    public static Map<Id,Set<sObject>> userIncidents = new Map<Id,Set<sObject>>() ;
    public static Map<Id,Set<sObject>> queueuserIncidents = new Map<Id,Set<sObject>>() ;
    static Map<Id,Id>  IncidentWorkItem = new Map<Id,Id>();
    static Map<Id,String>  IncidentQueueApprover = new Map<Id,String>();
    public static Map<Id,List<String>> ApproverEmailList = new Map<Id,List<String>>();

    public static void runPendingApprovalWrapper(){
        try{
        List<Approval_Reminder_Setting__mdt>  reminderSets = [SELECT Id,ElapsedTime__c,Label,Incident_Condition__c,Recurring_Pattern__c, Exclude_Weekend__c FROM Approval_Reminder_Setting__mdt LIMIT 500];
            if(reminderSets.size() > 0){
            
            pendingApprovals(reminderSets);
        }
        }catch(Exception e){
            sendEmail( e.getTypeName()+' \n - '+e.getMessage()+' \n '+e.getStackTraceString());
        }
        
        
    }
    
    public static  void pendingApprovals( List<Approval_Reminder_Setting__mdt>  reminderSets){
        
     List<Id> IncidentIds = new List<Id>() ;
     List<String> inc_conditions = new  List<String>();
     List<String>inc_fields_list = new  List<String>();    
     Set<String> inc_fields  =  new Set<String>{'BMCServiceDesk__Category_ID__c'};
     String column_names = ''; 
       
      List<ProcessInstance> pending_process =  [SELECT Id, status, TargetObjectId, (SELECT Id, ActorId,Actor.Name, ElapsedTimeInHours, ProcessInstanceId ,ElapsedTimeInDays FROM Workitems WHERE ElapsedTimeInDays < 60),  (SELECT Id, StepStatus, Comments FROM Steps)
          FROM ProcessInstance where TargetObject.Type = 'BMCServiceDesk__Incident__c' and status = 'Pending' ];
   
     //String sql =   'SELECT Id, status, TargetObjectId, (SELECT Id, ActorId, ElapsedTimeInHours, ElapsedTimeInDays, ProcessInstanceId  FROM Workitems),  (SELECT Id, StepStatus, Comments FROM Steps) FROM ProcessInstance where TargetObject.Type = :incident_api and '+st_str;
     
        for(ProcessInstance pi : pending_process ){
            IncidentIds.add(pi.TargetObjectId);
        }

        for(Approval_Reminder_Setting__mdt ars :reminderSets){
          System.debug(' INSIDE ARS '+ars.Id);
            if(ars.Incident_Condition__c != ''){
               inc_conditions =  ars.Incident_Condition__c.split('&');
                for(String cnd : inc_conditions){
                    if( cnd == 'OR' || cnd == 'AND'){
                        continue;
                    }
                     inc_fields.add(cnd.split('#')[0]);
                }
            }
        }

       
        inc_fields_list.addAll(inc_fields);
      
        if(inc_fields != null){
            column_names = String.join(inc_fields_list,',');
        }

        String sql = 'SELECT ID, Name, '+ String.escapeSingleQuotes(column_names)+' from BMCServiceDesk__Incident__c WHERE ID IN :IncidentIds '; //cs fix - PRTORES-1581 shegade
        SOIncidents =  new MAP<Id,sObject>( (List<sObject>)Database.query(sql));

        addUserIncidents(pending_process, reminderSets);
        populateEmailAddressMap();
        sendNotifications();
          
    }


  
    public static void populateEmailAddressMap(){
      
      Set<ID> QueueORUserIds = new Set<ID>();
      QueueORUserIds.addAll(userIncidents.keySet());
      QueueORUserIds.addAll(queueUserIncidents.keySet());
      List<Group> approvalQueue = [SELECT ID,Email,Name from Group WHERE Type = 'Queue' and ID In :QueueORUserIds ];
      List<String> email_addresses =  new List<String>();
      List<id> queueWithoutEmail =  new List<id>();

      //Adding queue email if available
      for(Group qu : approvalQueue){
          if(qu.Email == null || ( qu.Email != null && qu.Email.trim() == '') ){

              queueWithoutEmail.add(qu.Id);
          }else{
             userIncidents.put(qu.Id, queueUserIncidents.remove(qu.Id));
             email_addresses =  new List<String>();
             email_addresses.add( String.valueOf(qu.Email) );
             System.debug('ABC ADDING EMAIL Queue - '+email_addresses);
             ApproverEmailList.put(qu.Id,email_addresses);
          }
      }

      // Get Queue members email if Queue Email is not avialble.
      MAP<id,List<id>> GrouptoUserListMap = new MAP<id,List<id>>();
      List<id> goupUserIds = new List<id>();
      List<Id>usersIds =  new List<id>();

      if(queueWithoutEmail.size() > 0)
      {
         for ( GroupMember gm : [Select UserOrGroupId,GroupId From GroupMember where GroupId =:queueWithoutEmail]){
           if(GrouptoUserListMap.get(gm.GroupID) != null ){
              goupUserIds = GrouptoUserListMap.get(gm.GroupID);
           }
           goupUserIds.add(gm.UserOrGroupId);
           GrouptoUserListMap.put(gm.GroupID,goupUserIds);
           usersIds.add(gm.UserOrGroupId);
         }

      } //if queueWithoutEmail.size


      // Get All users with email which are Queue Member and also direct approvers of incident
      MAP<ID,String> UserEmail = new MAP<ID,String>();
      for(User usr : [SELECT Id,Name, Email FROM User Where (id in :usersIds OR  id in :QueueORUserIds) AND isActive = true]){
        
        UserEmail.put(usr.Id,  usr.Email);
      }

      // Construct approver email map depending on Queue members or single approval user
      List<String> EmailList =  new List<String>();
      for(Id queuser : QueueORUserIds){
          if( ApproverEmailList.get(queuser) == null){
            EmailList = new List<String>();
            if(string.valueOf(queuser).startsWith('00G'))
             {  
                for(Id user_id : GrouptoUserListMap.get(queuser)){
                  System.debug('ABC LL ADDING EMAIL GROUP MEMBER - '+user_id);
                  if( UserEmail.get(user_id) != null)
                    EmailList.add( String.valueOf(UserEmail.get(user_id)) );
                }  
             }

             if(string.valueOf(queuser).startsWith('005'))
             {
                System.debug('ABC LL ADDING EMAIL USER - '+queuser);
                if( UserEmail.get(queuser) != null)
                 EmailList.add( String.valueOf(UserEmail.get(queuser)) );
             }
            
             ApproverEmailList.put(queuser,EmailList);
          }
      }// for loop QueueORUserIds

    }

public  static Messaging.SingleEmailMessage prepareMail(Id approverId, boolean isQueueApprover, OrgWideEmailAddress[] owea)
  {
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

          

           List<String> emailAddresses =  new List<String>();
           Set<sObject> incidents = new Set<sObject>();

           emailAddresses = ApproverEmailList.get(approverId);
           System.debug(' ABC Email '+approverId+' - '+emailAddresses);

          if(emailAddresses.size() > 0)
           { 
             mail.setToAddresses(emailAddresses); 
           }
           
           if ( owea.size() > 0 ) {
              mail.setOrgWideEmailAddressId(owea.get(0).Id);
          }

           List<String> emailBCC =  new List<String>();
           mail.setSubject('Attention Required: Pending Approval for Incident/Service Requests'); 

           String textBody = '';
           
           String recUrl = System.URL.getSalesforceBaseURL().toExternalForm()+'/apex/bmcservicedesk__ssredirect?inc=';
           String appUrl =  'https://'+ System.URL.getSalesforceBaseUrl().getHost() +'/p/process/ProcessInstanceWorkitemWizardStageManager?id=';
          if(isQueueApprover)
          {
            List<String> queues = new List<String>();

            
           textBody += '<br/><br/>';
           textBody += 'Below are the Incident/Service Requests waiting for your approval. ';
           textBody += '<br/><br/>';
           textBody += '<table style="border:none;text-align:left;" cellspacing="18px"><tr><th>Ticket#</th><th>Category</th><th>Link to Approval</th></tr>';

            for(sObject inc : queueUserIncidents.get(approverId)){
               System.debug('ABC - Inc '+inc.Id);
               if(!queues.contains(IncidentQueueApprover.get(inc.Id)))
               {
                  queues.add(IncidentQueueApprover.get(inc.Id));
               }
               
               
              textBody += '<tr><td><a href="'+recUrl+inc.Id+'">'+inc.get('Name')+'</td>';
              textBody += '<td>'+inc.get('BMCServiceDesk__Category_ID__c')+'</td>';
              textBody  += '<td><a href="'+appUrl+IncidentWorkItem.get(inc.Id)+'"> Approve/Reject </a> </td></tr>';
            }
            textBody = 'You are receiving this reminder because you belong to the queue/s ' + String.join(queues, '.')+textBody;
          }
          else 
          {
            textBody += 'Below are the Incident/Service Requests waiting for your approval. ';
           textBody += '<br/><br/>';
           textBody += '<table style="border:none;text-align:left;" cellspacing="18px"><tr><th>Ticket#</th><th>Category</th><th>Link to Approval</th></tr>';

            for(sObject inc : userIncidents.get(approverId)){
               System.debug('ABC - Inc '+inc.Id);
               
              textBody += '<tr><td><a href="'+recUrl+inc.Id+'">'+inc.get('Name')+'</td>';
              textBody += '<td>'+inc.get('BMCServiceDesk__Category_ID__c')+'</td>';
              textBody  += '<td><a href="'+appUrl+IncidentWorkItem.get(inc.Id)+'"> Approve/Reject </a> </td></tr>';
            }
          }
           textBody += '</table>';
           mail.setHtmlBody(textBody);    
           return mail;
  }


    public static void sendNotifications(){
       

       Set<ID> userIds = userIncidents.keySet();
       
       System.debug('  All USER IDS - '+userIds);
       List<User> Users = [select id,Email,Name from User where id in :userIds];
       Messaging.SingleEmailMessage[] emailMessageList = new List<Messaging.SingleEmailMessage> ();
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'no-reply@akamai.com'];
       
       //Used below orgwide email address for sandbox testing as 'no-reply@akamai.com' was not authorized in sandboxes
       //OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noreply.mailer@akamai.com'];
       
       if(userIncidents.size() > 0 ){
         for( Id approverId : userIncidents.keySet()){
             
            mail = prepareMail(approverId,false,owea);
            System.debug(' Email 1 '+mail+' --  '+mail.ToAddresses);
             //if( mail != null && mail.ToAddresses.size() > 0)   {    //KIMISHRA - PRTORES-1378
             if( mail != null && mail.ToAddresses != null)   {
             emailMessageList.add(mail); 
             } 

         }
      }
      if(queueUserIncidents.size() > 0 ){
       for( Id approverId : queueUserIncidents.keySet()){
           
          mail = prepareMail(approverId,true,owea);
          System.debug(' Email 2 '+mail+' --  '+mail.ToAddresses);
          //if( mail != null && mail.ToAddresses.size() > 0)   {    //KIMISHRA - PRTORES-1378
          if( mail != null && mail.ToAddresses != null)   {
           emailMessageList.add(mail);  
          }
       }
      }
        
        if(emailMessageList.size() > 0){
         Messaging.sendEmail(emailMessageList);

        }
  }

    public static void addUserIncidents(List<ProcessInstance> pending_process,  List<Approval_Reminder_Setting__mdt>  reminderSets){

        Boolean incidentMatch ;
        Integer repeatHours  = 0;
        Boolean reoccuranceTime;

        for(Approval_Reminder_Setting__mdt ars :reminderSets){
            
            if(ars.Recurring_Pattern__c != ''){
                repeatHours = Integer.valueOf(ars.Recurring_Pattern__c);
                
            }

            for(ProcessInstance pi : pending_process ){
                for( ProcessInstanceWorkItem item  : pi.WorkItems){
                     System.debug('ABC INC '+pi.TargetObjectId+' ActorId '+item.ActorId);
                     reoccuranceTime =  false;
                     Integer settingElapsedTime =  Integer.ValueOf(ars.ElapsedTime__c);
                     Double item_elapsedHours =  item.ElapsedTimeInHours;          
                     Integer ItemElapsedTimeInHours = item_elapsedHours.intValue();
                     Integer ElapsedTimeInHours = getExcludedWeekendHours(ars.Exclude_Weekend__c,ItemElapsedTimeInHours);
                             
                    
                    if (repeatHours != 0){
                        integer rp_hours =  ElapsedTimeInHours - settingElapsedTime;
                        
                        System.debug( ' ABC INC 1'+pi.TargetObjectId+' rp_hours '+rp_hours+' repeatHours '+repeatHours);
                        integer rem  = Math.Mod(rp_hours,repeatHours);
                        System.debug( ' ABC INC '+pi.TargetObjectId+' ans '+rem);
                        if ( rem == 0 && rp_hours > 0 )
                        {
                            reoccuranceTime = true; 
                        }
                    }
                    
                    System.debug('ABC REOCCUR '+reoccuranceTime);
                    incidentMatch = false;
                    if( settingElapsedTime == ElapsedTimeInHours  || reoccuranceTime   ){
                      incidentMatch =  evalInciCondn(SOIncidents.get(pi.TargetObjectId),ars.Incident_Condition__c);
                    }
                    
                    if( incidentMatch == true){
                        System.debug(' ABC inc match '+pi.TargetObjectId+' -- '+SOIncidents.get(pi.TargetObjectId));
                        Set<sObject> incList = new Set<sObject>();
                        Set<sObject> incListQueue = new Set<sObject>();
                        if(string.valueOf(item.ActorId).startsWith('00G'))
                        {
                            if( queueuserIncidents.get(item.ActorId) != null)
                            { 
                              incListQueue =  queueuserIncidents.get(item.ActorId);
                            } 
                            incListQueue.add(SOIncidents.get(pi.TargetObjectId));
                            queueuserIncidents.put(item.ActorId, incListQueue);

                        }
                        else if(string.valueOf(item.ActorId).startsWith('005'))
                        {
                            if( userIncidents.get(item.ActorId) != null)
                            { 
                              incList =  userIncidents.get(item.ActorId);
                            } 
                            incList.add(SOIncidents.get(pi.TargetObjectId));
                            userIncidents.put(item.ActorId, incList);
                        }
                        
                      IncidentWorkItem.put(pi.TargetObjectId,item.Id);
                      IncidentQueueApprover.put(pi.TargetObjectId,item.Actor.Name);
                                            

                    }
                }
            }
        }

    }

    
    public static Boolean evalInciCondn(SObject inc, String condn ){
        boolean retval = true;
        if(condn == '' || condn == null){
            return true;
        }
        
            System.debug('ABC CONDN INC -'+inc.Id+' CONDN '+condn);
        
             List<String>  inc_conditions =  condn.split('&');
             List<String> condn_el;
             String inc_fldval;
             String cnd_opt;
             Boolean  last_eval = null ;
             String   last_operator ;
             for(String cnd : inc_conditions){
                 if(cnd == 'OR' || cnd == 'AND'){
                     last_operator = cnd ;
                     continue;    
                 }
 
                 condn_el =  cnd.split('#');
              
                 boolean condn_eval = false;
                 if(inc.get(condn_el[0]) == null){
                     inc_fldval = ' ';
                 }else{
                      inc_fldval =  String.valueOf(inc.get(condn_el[0]));
                 }
               System.debug(' FLD VAL '+condn_el[0]+' val '+inc_fldval+'  INC '+inc.Id);
                  
                     if (condn_el[1] == '='){
                         if (inc_fldval == condn_el[2]){
                             condn_eval = true;
                         }
                      }
                     if (condn_el[1] == '!='){
                         if (inc_fldval != condn_el[2]){
                                 condn_eval = true;
                             }
                         
                     }
                     if( condn_el[1] == '~' && inc_fldval.contains(condn_el[2]) ){
                         condn_eval = true;
                     }
                 
                     if( condn_el[1] == '!~' && !inc_fldval.contains(condn_el[2]) ){
                         condn_eval = true;
                     }
                 
                 System.debug('ABC CONDN EVAL - '+inc.id+' - '+condn_eval);
                                  
                 if (last_operator == 'AND'){
                     last_eval = last_eval && condn_eval;
                 }else if (last_operator == 'OR'){
                     last_eval = last_eval || condn_eval;
                 }
                 
                 if (last_eval == null){
                     last_eval = condn_eval;
                 }

             }
            System.debug('ABC CONDN LAST EVAL - '+inc.id+' - '+last_eval);
            return last_eval;
    }
    
    public static integer getExcludedWeekendHours(Boolean excludeWeekend, Integer ElapsedTimeInHours){
        if(excludeWeekend == true){
                        DateTime today = Date.today();
                        DateTime startDate = today - (ElapsedTimeInHours/24) ;
                        Integer excludeWeekendHours = 0;  
                           System.debug(' NO Days '+StartDate+'  ETIH '+ElapsedTimeInHours);
                             while(startDate < today){
                                 if (startDate.format('EEE') == 'Sat' || startDate.format('EEE') == 'Sun') {
                                    excludeWeekendHours += 24;
                                  }
                                 System.debug(' INC Days '+startDate);
                                 startDate = startDate.addDays(1);
                             }
                        ElapsedTimeInHours = ElapsedTimeInHours - excludeWeekendHours;
                     }
        return ElapsedTimeInHours;
    }
    
    
    public static void sendEmail(String message){
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         String[] toAddresses = new String[] {'hd-itsm-dev@akamai.com'};
         mail.setToAddresses(toAddresses);
         mail.setSubject('Helpdesk Exception: Scheduled Approval Reminder Error ');
         mail.setPlainTextBody(message);
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }

}