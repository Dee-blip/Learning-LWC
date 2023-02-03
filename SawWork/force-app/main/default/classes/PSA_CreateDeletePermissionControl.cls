global class PSA_CreateDeletePermissionControl
{
    static String PACKAGE_NAMESPACE_PREFIX = 'pse';
    static Map<String,Id> userAkamIdUserId = new Map<String,Id>();
    static Map<String,Id> userAkamIdConId = new Map<String,Id>();
   
    webservice static string CreateAndDeletePControls(List<Id> toBeAsssignedIds)
        {
            list<String> ProfileNames = New list<String>();
            list<Contact> allPSAResources = new list<Contact>();
            list<string> UserIds = new List<String>();
            Date TodayDate;
            List<Contact> PSResourceList = new list<Contact>();
            TodayDate = System.today();
            List<UserPackageLicense> licenses = new List<UserPackageLicense>();
            List<Id> uIds = new List<Id>();
            List<String> userList = new List<String>();
            List<User> userNameEmail = new List<User>();
            List<Contact> contactsToUpdateRecType = new List<Contact>();
            List<Contact> contactsToInsert = new List<Contact>();
            Set<String> akamContactIds = new Set<String>();

            //Default Region, Practice 
            //changes by sharath: Adding default Work Calendar          
            String region = [select Id from pse__Region__c where Name = 'Corporate' limit 1].Id;
            String practice = [select Id from pse__Practice__c where Name = 'Professional Services' limit 1].Id;
            String grp = [select Id from pse__Grp__c where Name = 'Undefined' limit 1].Id;
            String workCalendar = [select id from pse__Work_Calendar__c where name = 'US Full Time' limit 1].id;
            //Start of changes by janantha to start automation of PSA license
            
            List<Database.SaveResult> conInsertResult = new List<Database.SaveResult>();
            List<Database.SaveResult> conUpdateResult = new List<Database.SaveResult>();

            String accountName = PSA_Settings__c.getInstance('Account Name For PSA').Value__c;
            

            String recordTypeId = [select Id from RecordType where Name = 'PSA Resource'].Id;
            Account acc = [select Id,Name from Account where Name = :accountName limit 1];  
            System.debug('acc***'+acc);
            String PSALicenseId = [select Id from PackageLicense where NamespacePrefix = :PACKAGE_NAMESPACE_PREFIX limit 1].Id;

            //get all the User Id's from UserPackageLicense which were created in the last one month and are associated with PSA license
            
           //licenses = [select ID, UserId from UserPackageLicense where CreatedDate = LAST_N_DAYS:30 and PackageLicenseId = :PSALicenseId];
            
            //Getting those Ids from the userLicenseIds passed to the function for PSA_AutomateLicenseAssignment
            licenses = [select ID, UserId from UserPackageLicense where PackageLicenseId = :PSALicenseId and UserId in :toBeAsssignedIds];
            
            for(UserPackageLicense upl : licenses)
            {
              uIds.add(upl.UserId);
            }
            //System.assertEquals(uIds.size(),999);

            for(User user : [select FirstName,LastName,Name, email, AKAM_User_ID__c from User where Id in :uIds])
            {      
              userList.add(user.AKAM_User_ID__c);   
              userNameEmail.add(user);
              userAkamIdUserId.put(user.AKAM_User_ID__c,user.Id);
            }

            // Check for first and last name instead of name.
            // for(Contact con : [select Id, RecordTypeId, Email, AKAM_Contact_ID__c from Contact where Email in :userEmailUserId.keySet()])
            for(Contact con : [select Id, RecordTypeId, Email, AKAM_Contact_ID__c from Contact where AKAM_Contact_ID__c in :userList])
            {
              //System.assertEquals('abc','def');
              con.RecordTypeId = recordTypeId;
              //con.pse__Salesforce_User__c = user1.Id;
              con.pse__Is_Resource__c = TRUE;
              con.pse__Is_Resource_Active__c = TRUE;
              con.pse__Region__c = region;
              con.pse__Practice__c = practice;
              con.pse__Group__c = grp;
              con.pse__Start_Date__c = Date.today();
              con.pse__Salesforce_User__c = userAkamIdUserId.get(con.AKAM_Contact_ID__c);
              con.pse__Work_Calendar__c = workCalendar;
              userAkamIdConId.put(con.AKAM_Contact_ID__c, con.Id);
              contactsToUpdateRecType.add(con);
              akamContactIds.add(con.AKAM_Contact_ID__c);
            }
            //System.assertEquals(contactsToUpdateRecType,null);
            conUpdateResult = Database.update(contactsToUpdateRecType, false);
            //System.assertEquals(conUpdateResult,null);
            //System.assertEquals(contactsToUpdateRecType.size(),0);
            for(Database.SaveResult sr:conUpdateResult)
            {     
              for(Database.Error er:sr.getErrors())
              {
                System.debug('Error Message ****'+er.getMessage());
              }
            }

            System.debug('contactsToUpdateRecType***'+contactsToUpdateRecType);
            //System.debug('contactExists***'+contactExists);

            
              for(User user1 : userNameEmail)
              {
                if(!akamContactIds.contains(user1.AKAM_User_ID__c))
                {
                  //system.assert(1==2);
                  Contact con1 = new Contact();
                  con1.RecordTypeId = recordTypeId;
                  con1.pse__Is_Resource__c = TRUE;
                  con1.pse__Is_Resource_Active__c = TRUE;
                  con1.email = user1.email;
                  con1.FirstName = user1.FirstName;
                  con1.LastName = user1.LastName;
                  con1.AccountId = acc.Id;
                  con1.pse__Salesforce_User__c = user1.Id;
                  con1.pse__Region__c = region;
                  con1.pse__Practice__c = practice;
                  con1.pse__Group__c = grp;
                  con1.pse__Start_Date__c = Date.today();
                  con1.pse__Work_Calendar__c = workCalendar;
                  con1.CurrencyIsoCode = 'USD';
                  con1.AKAM_Contact_ID__c = user1.AKAM_User_ID__c;
                  contactsToInsert.add(con1);
                }
              }
              //System.assertEquals(contactsToInsert.size(),0);
              System.debug('contactsToInsert***'+contactsToInsert);
              if(contactsToInsert.size() > 0)
                conInsertResult = Database.insert(contactsToInsert,false);
              //System.assertEquals(conInsertResult,null);
              System.debug('conInsertResult***'+conInsertResult);
            

            for(Database.SaveResult sr:conInsertResult)
            {
              if(sr.isSuccess())
              {
                //System.assertEquals(sr.getId(),'005G0000006yg2U');
                //system.assert(1==0);
              }
              else
              {
                  for(Database.Error er:sr.getErrors())
                  {

                    System.debug('Error Message ****'+er.getMessage());
                    //system.assertEquals(10);
                  }
              }
            }
            //End of changes by janantha to start automation of PSA license
            
            list<PSA_Permission_Control__c> ListPC = PSA_Permission_Control__c.getall().values();
            for(PSA_Permission_Control__c PCIterator:ListPC )
                {
                ProfileNames.add(PCIterator.Profile__c);
                }
                    
            allPSAResources = [Select Id,pse__Salesforce_User__c,pse__Salesforce_User__r.LastModifiedDate from Contact where pse__Salesforce_User__c != NULL and (pse__Salesforce_User__r.LastModifiedDate > LAST_MONTH) and pse__Salesforce_User__r.Profile.Name in :ProfileNames];
            
            PSResourceList = [select pse__Salesforce_User__c from Contact where Recordtype.Name = 'PSA Resource' and pse__Salesforce_User__c != NULL ];
            if(allPSAResources.size() != 0)
            {
                for(Contact c:allPSAResources)
                {
                    UserIDs.add(c.pse__Salesforce_User__c);
                }
                
                TodayDate = System.today();
                list<pse__Permission_Control__c> allPermissionControls = [select Id,pse__User__c from pse__Permission_Control__c where pse__End_Date__c > :TodayDate];
                list<String> usersWithPermissionControls = new list<String>();
                for(pse__Permission_Control__c pc : allPermissionControls)
                {
                    usersWithPermissionControls.add(pc.pse__User__c);
                }
                list<String> UsersWithNoPermissionControls=new list<String>();
                
                Boolean Found;
                for(String Id1 : UserIDs)
                {
                    
                    Found = FALSE;
                    for (String ID2 : usersWithPermissionControls)
                    {
                       if(ID1.equalsIgnoreCase(ID2))
                       {
                           Found = TRUE;
                           break;
                       }
                    }
                    
                  if(Found == FALSE)
                  {
                      
                      UsersWithNoPermissionControls.add(Id1);
                  }
                }
              
              try
              {
              InsertPermissionControlList(UsersWithNoPermissionControls);
              }
              catch(exception e)
              {
              return e.getmessage();
              }
              try
              {
              Integer NumberOFRecordsDeleted = DeletePermissionControl(PSResourceList);
              return UsersWithNoPermissionControls.size() + 'Records inserted and ' + NumberOFRecordsDeleted + ' records deleted';
              }
              catch(exception e)
              {
              return e.getmessage();
              }
            }
            
        else return 'No records found with discrepencies';
        }
            
    public static void InsertPermissionControlList(list<String> UserIdsA)
    {
      
      List<pse__Permission_Control__c> toInsertPermissionControlRecords = new List<pse__Permission_Control__c>();
      list<User> UserRecords = [Select Id,ProfileID,Profile.Name from User where Id in :UserIdsA];
      Date TodayDate = system.today();
      List<Database.SaveResult> permsetInsert = new List<Database.SaveResult>();
      List<Id> pcId = new List<Id>();
      List<Messaging.SingleEmailMessage> mailsToBeSent = new List<Messaging.SingleEmailMessage>();
      Messaging.SingleEmailMessage objEmail;
      List<String> sendTo = new List<String>();
      String fromAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c;
      String orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1].Id;
      String GSSOpsEmailId = PSA_Settings__c.getInstance('GSS Ops Email').Value__c;

      for(User U: UserRecords)
      {
          
          pse__Permission_Control__c PCtoInsert = new pse__Permission_Control__c() ;
          PSA_Permission_Control__c PC = PSA_Permission_Control__c.getValues(U.ProfileID);
          if(PC != NULL)
          {
          
          PCtoInsert.pse__User__c = U.Id;
          PCtoInsert.pse__Cascading_Permission__c = PC.PSA_Cascading_Permission__c;
          PCtoInsert.pse__Expense_Entry__c = PC.PSA_Expense_Entry__c;
          PCtoInsert.pse__Expense_Ops_Edit__c = PC.PSA_Expense_Ops_Edit__c;
          PCtoInsert.pse__Forecast_Edit__c = PC.PSA_Forecast_Edit__c;
          PCtoInsert.pse__Forecast_View__c = PC.PSA_Forecast_View__c;
          PCtoInsert.pse__Invoicing__c = PC.PSA_Invoicing__c;
          PCtoInsert.pse__Practice__c = PC.PSA_PC_Practice_ID__c;
          PCtoInsert.pse__Resource_Request_Entry__c = PC.PSA_Resource_Request_Entry__c;
          PCtoInsert.pse__Skills_And_Certifications_Entry__c = PC.PSA_Skills_and_Certifications_Entry__c;
          PCtoInsert.pse__Skills_And_Certifications_View__c = PC.PSA_Skills_and_Certifications_View__c;   
          PCtoInsert.pse__Staffing__c = PC.PSA_Staffing__c; 
          PCtoInsert.pse__Timecard_Ops_Edit__c = PC.PSA_Timecard_Ops_Edit__c;
          PCtoInsert.pse__Timecard_Entry__c = PC.Timecard_Entry__c;   
          PCtoInsert.pse__Start_Date__c = TodayDate;  
          PCtoInsert.pse__End_Date__c = PC.PSA_END_DATE__c ;   
          toInsertPermissionControlRecords.add(PCtoInsert);
          
            
          }
           
      }
      
      //system.assertEquals(toInsertPermissionControlRecords,null);
      permsetInsert = Database.insert(toInsertPermissionControlRecords);

      for(Database.SaveResult sr:permsetInsert)
      {
        if(sr.isSuccess())
        {
          pcId.add(sr.getId());
        }
      }

      for(pse__Permission_Control__c pc:[select Id, pse__User__r.Name, pse__User__r.Email, pse__User__r.ContactId, pse__User__r.AKAM_User_ID__c from pse__Permission_Control__c where Id in :pcId])
      {
          objEmail = new Messaging.SingleEmailMessage();
          sendTo = new List<String>();
          sendTo.add(GSSOpsEmailId);
          objEmail.setToAddresses(sendTo);
          objEmail.setSubject('New User with PSA Access');
          objEmail.setHTMLBody('<html><body>Hi Team,<br/><br/>The below User has been given PSA Access. Please update the Contact Record accordingly<br/><br/>User Name: '+pc.pse__User__r.Name+'<br/>Email: <a href = '+URL.getSalesforceBaseUrl().toExternalForm() + '/' + userAkamIdConId.get(pc.pse__User__r.AKAM_User_ID__c)+'>' +pc.pse__User__r.Email+'</a><br/>License Type: PSA License<br/>Region: Corporate<br/>Practice: Corporate<br/>Group: Undefined');
          objEmail.setOrgWideEmailAddressId(orgWideEmailId);
          mailsToBeSent.add(objEmail);
      }

      if(mailsToBeSent != null && mailsToBeSent.size()>0)
      {
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(mailsToBeSent,false);
        //System.assertEquals(results,null);

      }
      
    }
    public static Integer DeletePermissionControl(List<Contact> PSResourceList)
    {  
      List<String> UserList = new List<String>();
       
       for(Contact con:PSResourceList)
       {
         UserList.add(con.pse__Salesforce_User__c);  
       }
       List<pse__Permission_Control__c> toDeletePermissionControlList = [select Id,pse__User__c from pse__Permission_Control__c where pse__User__r.Id not in :UserList];
       Delete(toDeletePermissionControlList);  
       Return toDeletePermissionControlList.size();
    }  


}