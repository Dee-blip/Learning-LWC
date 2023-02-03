public  class HD_CMR_Schedulerlogic {



   public static void hourlyStatusCheck(){
   
   
        try{
      System.debug('STarted ---');
       HD_CMR_SETTINGS__c SETTING_AUTOLOCK = HD_CMR_SETTINGS__c.getInstance('Auto_Lock');
       if( SETTING_AUTOLOCK == NULL || SETTING_AUTOLOCK.Value__c != 'true')
        return;
        
       System.debug('Continue ----');
       DateTime CompareDate = System.now().addMinutes(-15);
       DateTime NextHour =    System.now().addMinutes(60);
       String timenow = System.now().format();
       DateTime Back3days =    System.now().addDays(-3);
            
       List<BMCServiceDesk__Change_Request__c> chreqs = [
       SELECT id,Name,HD_Change_Status__c,BMCServiceDesk__Scheduled_Start_Date__c,BMCServiceDesk__Scheduled_End_Date__c ,Change_Locked__c,Scheduled_Job_Lock__c 
       FROM BMCServiceDesk__Change_Request__c WHERE BMCServiceDesk__State__c = TRUE and Change_Locked__c != TRUE and (( BMCServiceDesk__Scheduled_Start_Date__c < :NextHour and  HD_Change_Status__c = 'AUTHORIZED'  and BMCServiceDesk__Scheduled_Start_Date__c > :Back3days)
       OR ( BMCServiceDesk__Scheduled_End_Date__c < :NextHour and  HD_Change_Status__c = 'IN PROGRESS' AND  BMCServiceDesk__Scheduled_End_Date__c >  :Back3days)  )  ] ;
       
       Boolean after15Minutes = false;
       Boolean after30Minutes = false;
       Boolean after45Minutes = false;
       
       System.debug('TICKETS ---- '+chreqs.size());
       
       List<BMCServiceDesk__Change_Request__c> UpdateList = new List<BMCServiceDesk__Change_Request__c>();
       for ( BMCServiceDesk__Change_Request__c chreq : chreqs){
      
          if(chreq.BMCServiceDesk__Scheduled_Start_Date__c <   CompareDate  && chreq.HD_Change_Status__c == 'AUTHORIZED'){
          
             chreq.Flag_For_CAB_Review__c = true;

             //chreq.HD_Change_Status__c = 'AUTO FAILED';
             //chreq.Change_Locked__c = true;
             chreq.Scheduled_Job_Lock__c  = 'AUTHORIZED LOCK '+timenow;
             System.debug('Added '+ chreq.id);
             UpdateList.add(chreq);
          
          }
          
          if(chreq.BMCServiceDesk__Scheduled_End_Date__c <  CompareDate  &&  chreq.HD_Change_Status__c == 'IN PROGRESS'){
          
             chreq.Flag_For_CAB_Review__c = true;
            // chreq.HD_Change_Status__c = 'AUTO FAILED';
            // chreq.Change_Locked__c = true;
             chreq.Scheduled_Job_Lock__c  = 'IN PROGRESS LOCK '+timenow;
             UpdateList.add(chreq);
          
          }
         
          
          if( (chreq.BMCServiceDesk__Scheduled_End_Date__c > System.now() && chreq.BMCServiceDesk__Scheduled_End_Date__c <= System.now().addMinutes(15)) 
          
            || (chreq.BMCServiceDesk__Scheduled_Start_Date__c > System.now() && chreq.BMCServiceDesk__Scheduled_Start_Date__c <= System.now().addMinutes(15))
          ){
            after15Minutes =  true;    
          
          }
          
          if( (chreq.BMCServiceDesk__Scheduled_End_Date__c > System.now().addMinutes(15) && chreq.BMCServiceDesk__Scheduled_End_Date__c <= System.now().addMinutes(30))
            || (chreq.BMCServiceDesk__Scheduled_Start_Date__c > System.now() && chreq.BMCServiceDesk__Scheduled_Start_Date__c <= System.now().addMinutes(30))
           ){
            after30Minutes =  true;    
          
          }
          
          if( (chreq.BMCServiceDesk__Scheduled_End_Date__c > System.now().addMinutes(30) && chreq.BMCServiceDesk__Scheduled_End_Date__c <= System.now().addMinutes(45))
            ||(chreq.BMCServiceDesk__Scheduled_Start_Date__c > System.now() && chreq.BMCServiceDesk__Scheduled_Start_Date__c <= System.now().addMinutes(45))
           ){
            after45Minutes =  true;    
          
          }
          
          System.debug('TICKET - '+chreq.name+' Lock - '+chreq.Change_Locked__c+' Status - '+chreq.HD_Change_Status__c);
          System.debug('TICKET - a15 '+after15Minutes+' a30- '+after30Minutes+' a45 - '+after45Minutes);   
       
       }
       
       
       update UpdateList;
       
       String SchTimer;
       

       
       if(after15Minutes == true){

            dateTime dt1=System.now().addMinutes(15);    
            SchTimer = getTimerStr(dt1);
            system.debug('SchTimer:'+SchTimer);
            HD_ChangeRequestStatusUpdater crs1  = new HD_ChangeRequestStatusUpdater();
            system.schedule('Change StatusUpdater 15 '+System.now().format(), SchTimer, crs1);
       
       }
       

       
       if(after30Minutes ==  true){
           dateTime dt2=System.now().addMinutes(30); 
           SchTimer = getTimerStr(dt2);  
           HD_ChangeRequestStatusUpdater crs2  = new HD_ChangeRequestStatusUpdater();
           system.schedule('Change StatusUpdater 30 '+System.now().format(), SchTimer, crs2);
       
       }
       
       if(after45Minutes ==  true){
           dateTime dt3=System.now().addMinutes(45); 
           SchTimer = getTimerStr(dt3);
           HD_ChangeRequestStatusUpdater crs3  = new HD_ChangeRequestStatusUpdater();
           system.schedule('Change StatusUpdater 45 '+System.now().format(), SchTimer, crs3);
       
       }
       
        
       
     } catch (Exception e) {
        System.debug('Error '+e);
        sendEmail(e.getMessage());
         
     }
        
   
   
   
   }
   
   
   
   public static void StatusUpdater15mins(){
   
        try{
        DateTime CompareDate = System.now().addMinutes(-15);
        DateTime NextHour =    System.now().addMinutes(60);
        DateTime Back3days =    System.now().addDays(-3);
        
            List<BMCServiceDesk__Change_Request__c> chreqs = [
              SELECT id,Name,HD_Change_Status__c,BMCServiceDesk__Scheduled_Start_Date__c,BMCServiceDesk__Scheduled_End_Date__c ,
              Change_Locked__c,Scheduled_Job_Lock__c FROM BMCServiceDesk__Change_Request__c 
              WHERE  Change_Locked__c != TRUE and  BMCServiceDesk__State__c = TRUE and
              (( BMCServiceDesk__Scheduled_Start_Date__c < :CompareDate and  HD_Change_Status__c = 'AUTHORIZED' and BMCServiceDesk__Scheduled_Start_Date__c > :Back3days)
              OR ( BMCServiceDesk__Scheduled_End_Date__c < :CompareDate and  HD_Change_Status__c = 'IN PROGRESS' and BMCServiceDesk__Scheduled_End_Date__c  >  :Back3days)  )  ] ;
       
       System.debug(' SUPDATE -- '+chreqs.size());
       
         List<BMCServiceDesk__Change_Request__c> UpdateList = new List<BMCServiceDesk__Change_Request__c>();
         for ( BMCServiceDesk__Change_Request__c chreq : chreqs){
                       
             if(chreq.BMCServiceDesk__Scheduled_Start_Date__c <=   CompareDate  && chreq.HD_Change_Status__c == 'AUTHORIZED'){
          
                 chreq.Flag_For_CAB_Review__c = true;

                // chreq.HD_Change_Status__c = 'AUTO FAILED';
                // chreq.Change_Locked__c = true;
                 chreq.Scheduled_Job_Lock__c  = 'AUTHORIZED LOCK '+System.now();
                 UpdateList.add(chreq);
          
             }
          
            if(chreq.BMCServiceDesk__Scheduled_End_Date__c <=  CompareDate  &&  chreq.HD_Change_Status__c == 'IN PROGRESS'){
              
              chreq.Flag_For_CAB_Review__c = true;
                 //chreq.HD_Change_Status__c = 'AUTO FAILED';
                // chreq.Change_Locked__c = true;
                 chreq.Scheduled_Job_Lock__c  = 'IN PROGRESS LOCK '+System.now();
                 UpdateList.add(chreq);

            }
          

            
            
         } 
         
          update UpdateList;
          
        }catch (Exception e) {
        System.debug('Error '+e);
         sendEmail(e.getMessage());
         
     }
   
   }


   public static String getTimerStr(DateTime dt1){
    
        String Csec,Cmin,Chr,Cday,Cmonth,CYear,SchTimer;
        Csec=String.valueof(dt1.second());
            Cmin=String.valueof(dt1.minute());
            Chr=String.valueof(dt1.hour());
            Cday=String.valueof(dt1.day());
            Cmonth=String.valueof(dt1.month());
            CYear=String.valueof(dt1.Year());
            SchTimer=Csec+' '+Cmin+' '+Chr+' '+Cday+' '+Cmonth+' ? '+CYear;
            system.debug('SchTimer:'+SchTimer);
            return SchTimer;
    
    
    }
    
    public static void sendEmail(String message){
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         String[] toAddresses = new String[] {'kahegde@akamai.com'};
         mail.setToAddresses(toAddresses);
         mail.setSubject('CMR Apex Schedule Job Error ');
         mail.setPlainTextBody(message);
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }


}