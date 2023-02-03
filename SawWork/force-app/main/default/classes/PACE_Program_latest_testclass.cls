@isTest
public class PACE_Program_latest_testclass {
    
    testmethod static void createProgram() {
       // try{
        //Inserting values in Pace Program
        PACE_Program__c  programObject = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0');
        insert programObject;
        System.assertNotEquals(programObject.id, null);
        
        //When Pace Program Name is different
        programObject.Name ='Rapid';
        upsert programObject;
        System.assertNotEquals(programObject.id, null);
        
        //Passing for a particular phase name 
        Id definitionPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Definition').getRecordTypeId();
        PACE_Phase__c phaseObject = new PACE_Phase__c(PACE_Program__c = programObject.Id);
        insert phaseObject;
        System.assertNotEquals(phaseObject.id, null);
        update phaseObject;  
        System.assertNotEquals(phaseObject.id, null);
    }
        testmethod static void PmLoginSkippedccCheckedDateChange()
        {
            PACE_Program__c programObject2 = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Skipped_CC__c=true);
            insert programObject2;
            System.assertNotEquals(programObject2.id, null);
            User thisUser = [SELECT Id FROM User WHERE isActive=true and Profile.Name='Product Management' limit 1];
            System.runAs(thisUser)
            {
                Test.startTest();
                try
                {
                  programObject2.Original_CC__c=date.parse('06/07/2012');
                  programObject2.Planned_CC__c=date.parse('06/07/2012');
                  update programObject2;
                 // System.assertNotEquals(programObject2.Original_CC__c, date.parse('06/07/2012')); 
                  //System.assertNotEquals(programObject2.Planned_CC__c, date.parse('04/07/2012')); 
                }
                catch(Exception e)
                {
                  PACE_Program__c query2=[select Original_CC__c,Planned_CC__c from PACE_Program__c where id=:programObject2.id];   
                  System.assertNotEquals(query2.Original_CC__c, date.parse('06/07/2012')); 
                  System.assertNotEquals(query2.Planned_CC__c, date.parse('04/07/2012')); 
                
                }
            }
        }
         testmethod static void PmLoginSkippedccUnChecked()
         {
            PACE_Program__c programObject2 = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Skipped_CC__c=false);
            insert programObject2;
            System.assertNotEquals(programObject2.id, null);
            User thisUser = [SELECT Id FROM User WHERE isActive=true and Profile.Name='Product Management' limit 1];
            System.runAs(thisUser)
            {
                Test.startTest();
                try
                {
                  programObject2.Original_CC__c=date.parse('06/07/2012');
                  programObject2.Planned_CC__c=date.parse('06/07/2012');
                  update programObject2;
                 // System.assertEquals(programObject2.Original_CC__c, date.parse('06/07/2012')); 
                  //System.assertEquals(programObject2.Planned_CC__c, date.parse('04/07/2012')); 
                }
                catch(Exception e)
                {
                     PACE_Program__c query2=[select Original_CC__c,Planned_CC__c from PACE_Program__c where id=:programObject2.id];   
                    System.assertEquals(query2.Original_CC__c, date.parse('06/07/2012')); 
                    System.assertEquals(query2.Planned_CC__c, date.parse('04/07/2012')); 
                 
                }
            }
        }
        testmethod static void ProdLoginSkippedccCheckedDateChange()
        {
             User thisUser = [SELECT Id FROM User  WHERE isActive=true and Profile.Name='Product Operations' limit 1];
            System.runAs(thisUser)
            {
                Test.startTest();
                
                    PACE_Program__c programObject2 = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Skipped_CC__c=true);
                    insert programObject2;
                    System.assertNotEquals(programObject2.id, null);
                try
                {
                    programObject2.Original_CC__c=date.parse('06/07/2012');
                    programObject2.Planned_CC__c=date.parse('06/07/2012');
                    update programObject2;
                  //  System.assertEquals(programObject2.Original_CC__c, date.parse('06/07/2012')); 
                   // System.assertEquals(programObject2.Planned_CC__c, date.parse('04/07/2012')); 
                }
                catch(Exception e)
                {   
                     PACE_Program__c query2=[select Original_CC__c,Planned_CC__c from PACE_Program__c where id=:programObject2.id];   
                    System.assertEquals(query2.Original_CC__c, date.parse('06/07/2012')); 
                    System.assertEquals(query2.Planned_CC__c, date.parse('04/07/2012')); 
               
                     
                }
            }
        }
        testmethod static void ProdLoginSkippedccUnChecked()
        {
             User thisUser = [SELECT Id FROM User WHERE isActive=true and Profile.Name='Product Operations' limit 1];
            System.runAs(thisUser)
            {
                Test.startTest();
                
                    PACE_Program__c programObject2 = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Skipped_CC__c=false);
                    insert programObject2;
                try
                {
                    programObject2.Original_CC__c=date.parse('06/07/2012');
                    programObject2.Planned_CC__c=date.parse('06/07/2012');
                    update programObject2;
                    //System.assertEquals(programObject2.Original_CC__c, date.parse('06/07/2012')); 
                    //System.assertEquals(programObject2.Planned_CC__c, date.parse('04/07/2012'));
                }
                catch(Exception e)
                {
                    PACE_Program__c query2=[select Original_CC__c,Planned_CC__c from PACE_Program__c where id=:programObject2.id];   
                    System.assertEquals(query2.Original_CC__c, date.parse('06/07/2012')); 
                    System.assertEquals(query2.Planned_CC__c, date.parse('04/07/2012'));
                 
                }
            }
        }
    //program phase='definition' cc dates cant be changed
    testmethod static void ProgramPhaseDefinitionCCdatesLocked()
        {
            PACE_Program__c programObject2 = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Program_Phase__c='Definition');
            insert programObject2;
            System.assertNotEquals(programObject2.id, null);
            User thisUser = [SELECT Id FROM User  WHERE isActive=true and Profile.Name='Product Management' limit 1];
            System.runAs(thisUser)
            {
                Test.startTest();
                try
                {
                    programObject2.Original_CC__c=date.parse('06/07/2012');
                    programObject2.Planned_CC__c=date.parse('04/07/2012');
                    update programObject2;
                    //System.assertNotEquals(programObject2.Original_CC__c, date.parse('06/07/2012')); 
                    //System.assertNotEquals(programObject2.Planned_CC__c, date.parse('04/07/2012')); 
                }
                catch(Exception e)
                {
                     PACE_Program__c query2=[select Original_CC__c,Planned_CC__c from PACE_Program__c where id=:programObject2.id];   
                    System.assertNotEquals(query2.Original_CC__c, date.parse('06/07/2012')); 
                    System.assertNotEquals(query2.Planned_CC__c, date.parse('04/07/2012')); 
              
                }
            }
        }
    //program phase='development' cc dates cant be changed
    testmethod static void ProgramPhaseDevelopmentdatesLocked()
        {
            PACE_Program__c programObject2 = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Program_Phase__c='Development');
            insert programObject2;
            System.assertNotEquals(programObject2.id, null);
            User thisUser = [SELECT Id FROM User  WHERE isActive=true and Profile.Name='Product Management' limit 1];
            System.runAs(thisUser)
            {
                Test.startTest();
                try
                {
                    programObject2.Original_CC__c=date.parse('06/07/2012');
                    programObject2.Planned_CC__c=date.parse('04/07/2012');
                    programObject2.Original_EC__c=date.parse('03/07/2012');
                    programObject2.Planned_EC__c=date.parse('02/07/2012');
                    update programObject2;
                    programObject2.BatchDate__c=(date.today()-15);
                    update programObject2;
                    programObject2.Original_LC__c=date.parse('06/07/2012');
                    programObject2.Original_BETA__c=date.parse('04/07/2012');
                    programObject2.Original_LA__c=date.parse('03/07/2012');
                    programObject2.Original_GA__c=date.parse('02/07/2012');
                   // programObject2.BatchDate__c=date.parse('02/07/2012');

                          
                          
                    update programObject2;
                                    }
                catch(Exception e)
                {
                    PACE_Program__c query2=[select Original_CC__c,Planned_CC__c,Original_EC__c,Planned_EC__c,BatchDate__c,Original_LC__c,Original_BETA__c,Original_LA__c,Original_GA__c from PACE_Program__c where id=:programObject2.id]; 
                    System.assertNotEquals(query2.Original_LC__c, date.parse('06/07/2012')); 
                    System.assertNotEquals(query2.Original_BETA__c, date.parse('04/07/2012'));
                    System.assertNotEquals(query2.Original_LA__c, date.parse('03/07/2012')); 
                    System.assertNotEquals(query2.Original_GA__c, date.parse('02/07/2012')); 
                    System.assertNotEquals(query2.Original_CC__c,date.parse('06/07/2012'));
                    System.assertNotEquals(query2.Planned_CC__c,date.parse('04/07/2012'));
                    System.assertNotEquals(query2.Original_EC__c,date.parse('03/07/2012'));
                    System.assertNotEquals(query2.Planned_EC__c,date.parse('02/07/2012'));


                }
            }
        }
    //program phase='launch' cc dates cant be changed
     testmethod static void ProgramPhaseLaunchdatesLocked()
        {
            PACE_Program__c programObject2 = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Program_Phase__c='Launch');
            insert programObject2;
            System.assertNotEquals(programObject2.id, null);
            User thisUser = [SELECT Id FROM User  WHERE isActive=true and Profile.Name='Product Management' limit 1];
            System.runAs(thisUser)
            {
                Test.startTest();
                try
                {
                    programObject2.Original_CC__c=date.parse('06/07/2012');
                    programObject2.Planned_CC__c=date.parse('04/07/2012');
                    programObject2.Original_EC__c=date.parse('03/07/2012');
                    programObject2.Planned_EC__c=date.parse('02/07/2012');
                    programObject2.Original_LC__c=date.parse('07/07/2012');
                    programObject2.Planned_LC__c=date.parse('08/07/2012');
                    programObject2.Original_SC__c=date.parse('09/07/2012');
                    programObject2.Planned_BETA__c=date.parse('01/07/2012');
                    programObject2.Original_BETA__c=date.parse('03/08/2012');
                    programObject2.Planned_Actual_SC__c=date.parse('02/08/2012');
                    //programObject2.Original_LA__c=date.parse('03/09/2012');
                    //programObject2.Original_GA__c=date.parse('02/09/2012');
                    update programObject2;
                   /* System.assertNotEquals(programObject2.Original_CC__c, date.parse('06/07/2012')); 
                    System.assertNotEquals(programObject2.Planned_CC__c, date.parse('04/07/2012')); 
                    System.assertNotEquals(programObject2.Original_EC__c, date.parse('03/07/2012')); 
                    System.assertNotEquals(programObject2.Planned_EC__c, date.parse('02/07/2012'));                
                    System.assertNotEquals(programObject2.Original_LC__c, date.parse('07/07/2012')); 
                    System.assertNotEquals(programObject2.Planned_LC__c, date.parse('08/07/2012')); 
                    System.assertNotEquals(programObject2.Original_SC__c, date.parse('09/07/2012')); 
                    System.assertNotEquals(programObject2.Planned_BETA__c, date.parse('01/07/2012'));                
                    System.assertNotEquals(programObject2.Original_BETA__c, date.parse('03/08/2012')); 
                    System.assertNotEquals(programObject2.Planned_Actual_SC__c, date.parse('02/08/2012')); */
                     }
                catch(Exception e)
                {
                    PACE_Program__c query2=[select Original_CC__c,Planned_CC__c,Original_EC__c,Original_LC__c,Planned_EC__c,Planned_LC__c,Original_SC__c,Planned_BETA__c,Original_BETA__c,Planned_Actual_SC__c from PACE_Program__c where id=:programObject2.id];   
                    System.assertNotEquals(query2.Original_CC__c, date.parse('06/07/2012')); 
                    System.assertNotEquals(query2.Planned_CC__c, date.parse('04/07/2012')); 
                    System.assertNotEquals(query2.Original_EC__c, date.parse('03/07/2012')); 
                    System.assertNotEquals(query2.Planned_EC__c, date.parse('02/07/2012'));                
                    System.assertNotEquals(query2.Original_LC__c, date.parse('07/07/2012')); 
                    System.assertNotEquals(query2.Planned_LC__c, date.parse('08/07/2012')); 
                    System.assertNotEquals(query2.Original_SC__c, date.parse('09/07/2012')); 
                    System.assertNotEquals(query2.Planned_BETA__c, date.parse('01/07/2012'));                
                    System.assertNotEquals(query2.Original_BETA__c, date.parse('03/08/2012')); 
                    System.assertNotEquals(query2.Planned_Actual_SC__c, date.parse('02/08/2012')); 
                   
                }
            }
        }
    //program skipped cc on checked blank original and planned dates
    testmethod static void SkippedccCheckedDatesBlanked()
        {
            PACE_Program__c programObject2 = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Skipped_CC__c=false,Original_CC__c=date.parse('06/07/2012'),Planned_CC__c=date.parse('04/07/2012'));
            insert programObject2;
            System.assertNotEquals(programObject2.id, null);
            User thisUser = [SELECT Id FROM User  WHERE isActive=true and Profile.Name='Product Operations' limit 1];
            System.runAs(thisUser)
            {
                Test.startTest();
                try
                {
                    programObject2.Skipped_CC__c=true;
                    programObject2.Original_CC__c=date.parse('06/07/2012');
                    programObject2.Planned_CC__c=date.parse('06/07/2012');
                    update programObject2;
                    //PACE_Program__c PgmObj=[Select Id,Skipped_CC__c,Original_CC__c,Planned_CC__c FROM PACE_Program__c where Id=:programObject2.id];
                    //System.assertEquals(true,PgmObj.Skipped_CC__c); 
                    //System.assertEquals(null,PgmObj.Original_CC__c);
                    //System.assertEquals(null,PgmObj.Planned_CC__c); 
                   
                }
                catch(Exception e)
                {
                    PACE_Program__c PgmObj=[Select Id,Skipped_CC__c,Original_CC__c,Planned_CC__c FROM PACE_Program__c where Id=:programObject2.id];
                    System.assertEquals(true,PgmObj.Skipped_CC__c); 
                    System.assertEquals(null,PgmObj.Original_CC__c);
                    System.assertEquals(null,PgmObj.Planned_CC__c); 
                   
                }
            }
        }
    
    
    
    
    
    
    
    
    
        //program phase='Concept' only then insert new program
     testmethod static void BeforeInsertcpp()
        {

            User thisUser = [SELECT Id FROM User  WHERE isActive=true and Profile.Name='Product Management' limit 1];
            System.runAs(thisUser)
            {
                Test.startTest();
                try
                {
                    
            PACE_Program__c programObject2 = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Program_Phase__c='Launch');
            insert programObject2;
            System.assertEquals(programObject2.id, null);
            PACE_Program__c programObject3 = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Program_Phase__c='Concept');
            insert programObject3;
            System.assertNotEquals(programObject2.id, null);       
                                  
                }
                catch(Exception e)
                {
                   
                }
            }
        }
    //status completed check
    testmethod static void StatusCheck()
        {
              PACE_Program__c programObject2 = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Skipped_CC__c=false,Original_CC__c=date.parse('06/07/2012'),Planned_CC__c=date.parse('04/07/2012'));
            insert programObject2;
             System.assertNotEquals(programObject2.id, null);
            User thisUser = [SELECT Id FROM User  WHERE isActive=true and Profile.Name='Product Management' limit 1];
            System.runAs(thisUser)
            {
                Test.startTest();
                try
                {
                    
                    //checkRecursive.isFirstRun();
                    programObject2.Program_Phase__c='Definition';
                     update programObject2;
                    // if (oldOpp.Program_Phase__c != ppc.Program_Phase__c && ppc.Validation_Override__c == False)
                             
                    //programObject2.Status__c='Cancelled';   
                    //update programObject2;
                    //System.assertNotEquals(programObject2.Status__c, 'Cancelled'); 
                }
                catch(Exception e)
                {
                     
                }
            }
        }

    testmethod static void validateDates()
    {

        User prodManagementUser = [SELECT Id FROM User  WHERE isActive=true and Profile.Name='Product Management' limit 1];

        //inserting as ADMIN
        PACE_Program__c definitionProgram = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Skipped_CC__c=false,Original_CC__c = null,Planned_CC__c=null, Original_EC__c = null, Resource_Status__c = null, Schedule_Status__c = null, Program_Phase__c = 'Definition');
        insert definitionProgram;
        System.assert(definitionProgram.Id != null, 'error inserting program with definition phase');

        //inserting as adming
        PACE_Program__c developmentProgram = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Skipped_CC__c=false,Original_CC__c = null,Planned_CC__c=null, Original_EC__c = null, Planned_EC__c = null, Original_LC__c = null, Planned_LC__c = null, Original_LA__c = null, Planned_LA__c = null, Original_GA__c = null, Planned_GA__c = null,  Resource_Status__c = null, Schedule_Status__c = null, Program_Phase__c = 'Development');
        insert developmentProgram;
        System.assert(developmentProgram.Id != null, 'error inserting program with definition phase');

        System.runAs(prodManagementUser){

            //validating errors at concept phase
            try{
                PACE_Program__c program = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0',Skipped_CC__c=false,Original_CC__c = date.parse('06/07/2012'),Planned_CC__c=null,Program_Phase__c = 'Concept');
                insert program;    
                System.assert(program.Id != null, 'error inserting program');
            }
            catch(Exception e){
                System.debug(e.getMessage());
            }

            //validating errors at definition phase
            try{
                definitionProgram.Schedule_Status__c = 'At Risk';
                definitionProgram.Schedule_Reason__c = null;
                update definitionProgram;
            }
            catch(Exception e){
                System.debug(e.getMessage());
            }

            //validating errors at development phase (works for launch as well)
            try {
                developmentProgram.Schedule_Status__c = 'At Risk';
                developmentProgram.Schedule_Reason__c = null;

                developmentProgram.Resource_Status__c = 'At Risk';
                developmentProgram.Resource_Reason__c = null;

                update developmentProgram;

            } catch(Exception e) {
                System.debug(e.getMessage());
            }

        }
    }
       
}