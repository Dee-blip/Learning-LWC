global class HD_InfosecEmailProcess implements Messaging.InboundEmailHandler {
     
      global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                             Messaging.InboundEnvelope env){
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        String emailcsv;
                                                                 
          try{
                                                                     
                                                                                                                         
                                                                 
                 HD_Instance__mdt infscStng = [SELECT DeveloperName, Label,instanceName__c , SettingValue__c from HD_Instance__mdt Where  DeveloperName = 'Infosecsettings' Limit 1];
                 BMCServiceDesk__Category__c  category;
                 User clientUser;        
                 BMCServiceDesk__Action__c  bmcaction;                                   
                     
                if (infscStng != null){
                    // Initializing configuration values.
                     if( infscStng.instanceName__c != '' ){
                         String[] strvals = infscStng.instanceName__c.split('##');
                         List<String>  kvl = new List<String>();
                         
                         MAP<String,String> kval = new MAP<String,String>();
                         for (String keyval : strvals){
                             kvl = keyval.split('#');
                             kval.put(kvl[0],kvl[1]); 
                         }
                         String categoryname = kval.get('CategoryName');
                         String clientName = kval.get('ClientName');
                         String actionName =  kval.get('ActionName');
                          category  = [SELECT ID, Name from BMCServiceDesk__Category__c  where Name = :categoryName Limit 1];
                          clientUser = [SELECT ID, Name From User where Name = :clientName Limit 1];
                          bmcaction = [SELECT ID,Name from BMCServiceDesk__Action__c  where Name =:actionName Limit 1];
                         
                     }


                     if (infscStng.SettingValue__c != ''){
                         
                         String[] setvalues = infscStng.SettingValue__c.split('##');
                         List<String>  kvl = new List<String>();
                         
                         MAP<String,String> kval = new MAP<String,String>();
                         for (String keyval : setvalues){
                             kvl = keyval.split('#');
                             kval.put(kvl[0],kvl[1]); 
                         }
    
                         // Checking for DDOS, Spamming attacks
                         
                         emailcsv =  kval.get('NotificationEmail');
                         String bufferlimit_str = kval.get('TotalBufferLimit') ;
                         String sameoriginlimit_str = kval.get('SameOriginLimit');
                         
                         Boolean totalBuffExceeded = false; 
                         Boolean sameOriginExceeded =  false; 
                         String[] buff_str;
                         if( bufferlimit_str != null && bufferlimit_str.trim() != '' ){
                             buff_str = bufferlimit_str.split(':');
                             if(buff_str != null && buff_str.size() == 2){
                                 DateTime curdt = Datetime.now();
                                 Integer sec = 0 - (integer.valueof(buff_str[1]));
                                 DateTime cmpdt = curdt.addSeconds(sec);
                                 List<HD_EmailBuffer__c> totalBuf = [Select ID,Name from HD_EmailBuffer__c WHERE CreatedDate > :cmpdt LIMIT 10000];
                                System.debug('Total Debug Values '+totalBuf.size()+ ' INT val '+integer.valueof(buff_str[0]));
                                 if (totalBuf.size() > integer.valueof(buff_str[0])){
                                     totalBuffExceeded =  true;
                                 }
                                 
                             }
                         }// totalbuffer limit
                         
                         
                         if(sameoriginlimit_str != null && sameoriginlimit_str.trim() != '' ) {
                             
                             buff_str = sameoriginlimit_str.split(':');
                        
                             if(buff_str != null && buff_str.size() == 2){
                                 DateTime curdt = Datetime.now();
                                 Integer sec = 0 - (integer.valueof(buff_str[1]));
                                 DateTime cmpdt = curdt.addSeconds(sec);
                                 List<HD_EmailBuffer__c> totalBuf = [Select ID,Name from HD_EmailBuffer__c WHERE CreatedDate > :cmpdt AND From_Address__c = :email.fromAddress LIMIT 10000];
                                 System.debug('Total Debug Values '+totalBuf.size()+ ' INT val '+integer.valueof(buff_str[0]));
                                 if (totalBuf.size() > integer.valueof(buff_str[0])){
                                     sameOriginExceeded =  true;
                                 }
                                 
                             }
                             
                         } //same origin          
                         
                         System.debug('LML Same '+sameOriginExceeded+' total '+totalBuffExceeded) ; 
                         if ( totalBuffExceeded ==true || sameOriginExceeded == true )     {
                             if(emailcsv.trim() != ''){
                                 Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                 String[] toAddresses = emailcsv.split(',');
                                 mail.setToAddresses(toAddresses);
                                 mail.setSubject('Infosec email to ticket Error - too many emails');
                                 String str = '';
                                 if(totalBuffExceeded == true)  {
                                     str += ' Number of emails recieved exceeded the limit. ';
                                 }   
                                 if (sameOriginExceeded == true){
                                     str += ' Number of emails from same address exceeded the limit.';
                                 }
                                 mail.setPlainTextBody(str);
                                 System.debug('LML Before in Sending ...');
                                 Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                             }
                         }     
                         // End of DDOS and Spam check 
                         
                         
                     }// Settingval  
                 }//infsec    

                 // Initiating buffer record
                 HD_EmailBuffer__c emlBuffer =  new HD_EmailBuffer__c ();
                 emlBuffer.Message_Id__c = email.messageid;
                 List<String> ref_arr = email.references;
                 
                 Boolean  replymail =  false;
                 String  actionInc_id = null;
                 integer size = 0; 
                 List<HD_EmailBuffer__c> matching_ebuff =  new List<HD_EmailBuffer__c>();
                 if (ref_arr != null && ref_arr.size() > 0)
                 {
                  matching_ebuff = [SELECT ID, CC_List__c, Email_Body__c, From_Address__c, Incident__c, Message_Id__c, Parent_Email_Buffer__c, Parent_Message_Id__c, References__c, Reply_To__c,Root_Email_Buffer__c,Short_Email_Body__c,Subject__c,To_Addresses__c 
                                   FROM HD_EmailBuffer__c where Message_Id__c IN :ref_arr AND Incident__c != null ];
                    System.debug( 'LML Size -- '+matching_ebuff);
                    
                      if  (matching_ebuff.size() > 0){
                          emlBuffer.Incident__c = matching_ebuff[0].Incident__c;
                          emlBuffer.Root_Email_Buffer__c = matching_ebuff[0].ID;
                          replymail = true;
                          actionInc_id = matching_ebuff[0].Incident__c;
                          emlBuffer.Root_Email_Buffer__c = matching_ebuff[0].ID;
                      }
                     Integer sz = ref_arr.size();
                     emlBuffer.Parent_Message_Id__c = ref_arr[ sz -1];
                     
                     emlBuffer.From_Address__c = email.fromAddress;
                     if(email.ccAddresses != null && email.ccAddresses.size() > 1){
                       emlBuffer.CC_List__c =  String.join(email.ccAddresses, ',');
                     }
                     
                 }
                 
                 //Create new Incident
                 if ( replymail == false){
                     BMCServiceDesk__Incident__c  inc =  new BMCServiceDesk__Incident__c ();
                     inc.BMCServiceDesk__FKCategory__c  = category.Id;
                     inc.BMCServiceDesk__FKClient__c = clientuser.Id;
                     inc.HD_Ticket_Priority__c = '4';
                     inc.BMCServiceDesk__incidentDescription__c = email.subject;
                     insert inc;
                     actionInc_id = inc.Id;
                     
                 }

                 integer totalstrsize = 50000;
                String plainbody=email.plainTextBody;
                  if(email.plainTextBody == null)
                {
                    plainbody = email.htmlBody.stripHtmlTags();
                }
                
                 if(plainbody.length() > totalstrsize){
                    plainbody = plainbody.substring(0,totalstrsize);
                 }
                 emlBuffer.Email_Body__c = plainbody;
                 emlBuffer.Incident__c = actionInc_id;
                 insert emlBuffer;
                 
                 //Attaching New incident history with reply email
                 BMCServiceDesk__IncidentHistory__c  nih =  new BMCServiceDesk__IncidentHistory__c();
                 nih.BMCServiceDesk__FKAction__c  = bmcaction.Id;
                 nih.BMCServiceDesk__FKIncident__c = actionInc_id;
                 nih.BMCServiceDesk__RichTextNote__c = email.htmlBody;
                 nih.BMCServiceDesk__note__c = plainbody;
                 nih.BMCServiceDesk__description__c  = email.subject;
                 insert nih;
                 
                 Boolean tobeclosed =  false;
                 String resol = '';
                 String str = plainbody;
                                   System.debug('LML EMAIL Body '+str);  
                     if(str.contains('Acknowledged and Closed')){
                         resol = 'Acknowledged and Closed';
                     }
                 
                 if(str.contains('Completed and Closed')){
                     resol = 'Completed and Closed';
                 }
                 
                    if (str.contains('Spam and Closed')){
                        resol = 'Spam and Closed';
                    } 
                    
                    if(resol != ''){
                        // List<User> sender_list = [Select ID,Name from user where email = :email.fromAddress and isactive = true ];
                       // Set<Id> resultIds = (new Map<Id,user>(sender_list)).keySet();
                      // List<User> gmembers =  [select Id, UserOrGroupId FROM GroupMember where  Group.DeveloperName = 'Infosec_Ticketing_Team' and UserOrGroupId in :resultIds ];

                      // Updating resolution field only it contains and phrase and sender is group Infosec_Ticketing_Team member
                       List<User> gmembers = [SELECT User.Id, User.Email FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Infosec_Ticketing_Team') and email = :email.fromAddress];
                       System.debug(' LML2 '+email.fromAddress+'  -- '+gmembers.Size());
                        if( gmembers != null && gmembers.size() > 0 ){
                            BMCServiceDesk__Incident__c inc1 = [ SELECT ID,Name,BMCServiceDesk__incidentResolution__c from BMCServiceDesk__Incident__c WHERE id = :actionInc_id Limit 1];
                            inc1.BMCServiceDesk__incidentResolution__c = resol;
                            update inc1;
                        }   
                    }
                 
 
                 result.success = true;
                 
          }
        catch (Exception e)
        {
          if(emailcsv.trim() != ''){
                                 Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                 String[] toAddresses = emailcsv.split(',');
                                 mail.setToAddresses(toAddresses);
                                 mail.setSubject('Infosec email to ticket Error');
                                 String str = e.getMessage()+' '+e.getStackTraceString() ;
                                 
                                 mail.setPlainTextBody(str);
                                 Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                             }
          
        }                                                     
    return result;
        }
    }