@isTest(SeeAllData=false)
private class HD_Test_UserAvaialability {

 
   public static User runUser = [Select id,TimeZoneSidKey,Name from User where Profile.Name = 'System Administrator' and TimeZoneSidKey != '' and isActive = true][0];
   public static User assignUser =  [Select id,TimeZoneSidKey,Name from User where Profile.Name = 'System Administrator' and TimeZoneSidKey != '' and TimeZoneSidKey != :runUser.TimeZoneSidKey   and isActive = true][0];
   public static Integer dayOfTheWeek;
   public static BusinessHours userBusinessHours;

   public static BMCServiceDesk__Incident__c testIncident;

   static{
      HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
      testIncident = rfFactory.getNewIncident(HD_IncidentTestDataFactory.Team.GENERIC);
   }
       
   static testMethod void caseZero(){
       dayOfTheWeek=0;
       availabilitytest();
   }
   static testMethod void caseOne(){
       dayOfTheWeek=1;
       availabilitytest();
   }
   static testMethod void caseTwo(){
       dayOfTheWeek=2;
       availabilitytest();
   }
   static testMethod void caseThree(){
       dayOfTheWeek=3;
       availabilitytest();
   }
   static testMethod void casFour(){
       dayOfTheWeek=4;
       availabilitytest();
   }
   static testMethod void caseFive(){
       dayOfTheWeek=5;
       availabilitytest();
   }
   static testMethod void caseSix(){
       dayOfTheWeek=6;
       availabilitytest();
   }
   static testMethod void caseSeven(){
       dayOfTheWeek=7;
       availabilitytest();
   }
    
    static void availabilitytest(){
   
   /*
    List<BMCServiceDesk__Urgency__c> urgency3 = [select Id from BMCServiceDesk__Urgency__c where NAME = 'Severity 3' limit 1];
            if(urgency3.size() <= 0 )
            {
            BMCServiceDesk__Urgency__c  Urgency  = new BMCServiceDesk__Urgency__c();
            Urgency.Name = 'Severity 3';
            urgency3.add(Urgency);
            insert urgency3;
            }
           
           
           HD_Ticket_Priority__c priority_setting;
           
            if(HD_Ticket_Priority__c.getInstance('3') == null){
            
                priority_setting = new HD_Ticket_Priority__c();
                priority_setting.Name = '3';
                priority_setting.Urgency_Id__c = urgency3[0].Id;
                priority_setting.Urgency_Name__c = 'Severity 3';
                insert  priority_setting;
                
            }
              
            
        
        LIST<BMCServiceDesk__Impact__c> impactlow =  [ select Id from BMCServiceDesk__Impact__c where NAME = 'LOW' LIMIT 1 ];
         if (impactlow.size() <= 0 )
         {
           BMCServiceDesk__Impact__c impact = new BMCServiceDesk__Impact__c();
           impact.Name = 'LOW';
           impactlow.add(impact);
           insert impactlow;
         }         
         
   
    BMCServiceDesk__CategoryTypes__c ctype  = new BMCServiceDesk__CategoryTypes__c();
    List< BMCServiceDesk__CategoryTypes__c> ctype_l = [Select Id from BMCServiceDesk__CategoryTypes__c where Name = 'Q_ITOC' LIMIT 1];
     if( ctype_l.size() > 0){
        ctype = ctype_l[0];
     }else{
     
     ctype = new BMCServiceDesk__CategoryTypes__c(Name = 'Q_ITOC' );       
     insert ctype;
     }
     BMCServiceDesk__Category__c raa_category = new BMCServiceDesk__Category__c();
          raa_category.Name = 'Test ITOC category';     
          raa_category.BMCServiceDesk__FKCategoryType__c = ctype.id;
          raa_category.BMCServiceDesk__AvailableForIncidents__c = true;
          
          insert raa_category;
       */   
      

      BMCServiceDesk__Incident__c inc = testIncident;
      //inc.BMCServiceDesk__FKUrgency__c = urgency3[0].id;
      //inc.BMCServiceDesk__incidentDescription__c = 'Test Description ';
      //inc.BMCServiceDesk__FKClient__c = system.userInfo.getUserId();
      User  usr =  [select id,ManagerId from user where id=: Userinfo.getUserId()];
      inc.BMCServiceDesk__Client_Manager__c =  usr.ManagerId;
      //inc.BMCServiceDesk__FKImpact__c  = impactlow[0].id;  
      //inc.BMCServiceDesk__FKCategory__c = raa_category.id; 
      insert inc;  
          
      //BMCServiceDesk__Incident__c inc1 = [Select Id,OwnerId from BMCServiceDesk__Incident__c where ID = :inc.Id Limit 1][0];  
     
        test.startTest();
     System.runAs(runUser){
     
        //inc1.CCText__c = inc1.CCText__c+';';
        inc.OwnerId = assignUser.Id;
        update inc;
        
        HD_UserAvailability usrAv =  new HD_UserAvailability();
        usrAv.dayOfTheWeek=dayOfTheWeek;
        usrAv.findUserAvailability(runUser.Id,inc);
        
        
        Time myTime = Time.newInstance( 10, 30, 2, 20);
        Time myTime2 = Time.newInstance(18, 30, 2, 20);
        Time zeroTime = Time.newInstance(0, 0, 0, 0);
            usrAv.timeBetweenNextOffice(3,myTime);
            usrAv.exactTimeInMinutesAndHours(8,myTime,myTime2);
            usrAv.generateAlert('Test Name',3,myTime, myTime2,zeroTime);
            usrAv.generateAlert('Test Name',3,myTime2,myTime,Time.newInstance(2, 3, 0, 0));
            usrAv.generateAlert('Test Name',3,NULL,myTime,Time.newInstance(20, 3, 0, 0));
            usrAv.generateAlert('Test Name',3,myTime,zeroTime,myTime2);
            usrAv.generateAlert('Test Name',3,myTime,myTime,myTime2);
          
         System.assertNotEquals(inc.ownerId,null);
        


       }
       test.stopTest();
     }


}