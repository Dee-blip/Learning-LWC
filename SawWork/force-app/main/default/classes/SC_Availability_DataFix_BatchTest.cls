/*
Author          : Tejaswini 

Date                 Developer               JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
24 Aug 2021        	 Tejaswini 				ESESP-5875	    Test class for SC_Availability_DataFix_Batch
*/
@isTest
public class SC_Availability_DataFix_BatchTest {
    
    @testSetup
    static void setupMethod() {
        
        Test.startTest();
        
        Account accRec = new Account(Name='Test Account',AKAM_Account_ID__c='Test-ABC-1234Addr',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
        insert accRec; 
        
        List<Timezone__c> lTimezones = new List<Timezone__c>();
        
        Timezone__c tz1 = new Timezone__c(Name ='Asia/Singapore',Offset__c='+8',Posix__c='Asia/Singapore');
        lTimezones.add(tz1);
        
        insert lTimezones;
        
        List<contact> lcont = new List<contact>();
        
        Contact rec1 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz21', Email = 'Test_xyz21@akamai.com',No_Longer_with_Company__c = false, LastName = 'Test ContactAcc21', Primary_Contact_Method__c = 'Phone',TimezoneNew__c =tz1.id);
        lcont.add(rec1);
        
        Contact rec2 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz22', Email = 'Test_xyz22@akamai.com',No_Longer_with_Company__c = false, LastName = 'Test ContactAcc22', Primary_Contact_Method__c = 'Phone',TimezoneNew__c =tz1.id);
        lcont.add(rec2);
        
        Contact rec3 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz23', Email = 'Test_xyz23@akamai.com',No_Longer_with_Company__c = false, LastName = 'Test ContactAcc23', Primary_Contact_Method__c = 'Mobile',TimezoneNew__c =tz1.id);
        lcont.add(rec3);
        
        Contact rec4 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz24', Email = 'Test_xyz24@akamai.com',No_Longer_with_Company__c = false, LastName = 'Test ContactAcc24', Primary_Contact_Method__c = 'Mobile',TimezoneNew__c =tz1.id);
        lcont.add(rec4);
        
        insert lcont;
                
        List<SC_SOCC_Availability__c> newRecords = new List<SC_SOCC_Availability__c>();
        
        SC_SOCC_Availability__c sc1 = new SC_SOCC_Availability__c();
        sc1.Day_Of_Week__c = 'Monday';
        sc1.Contact__c = rec1.id;
        sc1.Start_Time__c = Time.newInstance(0, 00, 0, 0);
        sc1.End_Time__c = Time.newInstance(23, 59, 0, 0);
        newRecords.add(sc1);
        
        SC_SOCC_Availability__c sc2 = new SC_SOCC_Availability__c();
        sc2.Day_Of_Week__c = 'Tuesday';
        sc2.Contact__c = rec2.id;
        sc2.Start_Time__c = Time.newInstance(2, 0, 0, 0);
        sc2.End_Time__c = Time.newInstance(3, 0, 0, 0);
        newRecords.add(sc2);
        
        SC_SOCC_Availability__c sc3 = new SC_SOCC_Availability__c();
        sc3.Day_Of_Week__c = 'Wednesday';
        sc3.Contact__c = rec3.id;
        sc3.Start_Time__c = Time.newInstance(2, 0, 0, 0);
        sc3.End_Time__c = Time.newInstance(18, 30, 0, 0);
        newRecords.add(sc3);
        
        SC_SOCC_Availability__c sc4 = new SC_SOCC_Availability__c();
        sc4.Day_Of_Week__c = 'Wednesday';
        sc4.Contact__c = rec4.id;
        sc4.Start_Time__c = Time.newInstance(19, 0, 0, 0);
        sc4.End_Time__c = Time.newInstance(23, 0, 0, 0);
        newRecords.add(sc4);
        
        insert newRecords;
        
        Policy_Domain__c  pd = new Policy_Domain__c();
        pd.Name = 'TestClassPolicyDomain1';
        pd.Account_Name__c = accRec.Id;
        pd.Product__c = 'Kona DDoS Defender';
        pd.Policy_Domain_State__c  = 'Active';
        pd.Additional_Product__c = 'Application-based Monitoring';
        insert pd;
        
        List<Authorized_Contact__c> lAuthcon = new List<Authorized_Contact__c>();
        
        Authorized_Contact__c authCon1 = new Authorized_Contact__c(Policy_Domain__c =pd.id, Contact_Name__c=rec1.id);
        lAuthcon.add(authCon1);
        
        Authorized_Contact__c authCon2 = new Authorized_Contact__c(Policy_Domain__c =pd.id, Contact_Name__c=rec2.id);
        lAuthcon.add(authCon2);
        
        Authorized_Contact__c authCon3 = new Authorized_Contact__c(Policy_Domain__c =pd.id, Contact_Name__c=rec3.id);
        lAuthcon.add(authCon3);
        
        insert lAuthcon;
        
        Test.stopTest();
        
    }
    
    @isTest 
    static void dataFixTest1()
    {
        Test.startTest();
        SC_Availability_DataFix_Batch myBatchObject = new SC_Availability_DataFix_Batch(1);
		Id batchId = Database.executeBatch(myBatchObject);
        Test.stopTest();
        System.assertEquals(0, [Select  count() from SC_SOCC_Availability__c where Contact__c not in (Select contact_name__c from Authorized_Contact__c )]);
    }
    
    @isTest
    static void dataFixTest2()
    {
        Test.startTest();
        SC_Availability_DataFix_Batch myBatchObject = new SC_Availability_DataFix_Batch(2);
		Id batchId = Database.executeBatch(myBatchObject);
        Test.stopTest();
        System.assertEquals(4, [Select count() from SC_SOCC_Availability__c]);
    }
    
    @isTest
    static void dataFixTest3()
    {
        Test.startTest();
        SC_Availability_DataFix_Batch myBatchObject = new SC_Availability_DataFix_Batch(3);
		Id batchId = Database.executeBatch(myBatchObject);
        Test.stopTest();
        System.assertEquals(4, [Select count() from SC_SOCC_Availability__c]);
    }
    
    /*@isTest
    static void dataFixTest4()
    {
        Test.startTest();
        SC_Availability_DataFix_Batch myBatchObject = new SC_Availability_DataFix_Batch(4);
		Id batchId = Database.executeBatch(myBatchObject);   
        Test.stopTest();
        System.assertEquals(4, [Select count() from SC_SOCC_Availability__c]);
    }*/

    @isTest
    static void dataFixTest5()
    {
        Test.startTest();
        Contact con = [Select Id from Contact where LastName = 'Test ContactAcc23' Limit 1];
        List<SC_SOCC_Availability__c> lAvailRecs = [Select Id from SC_SOCC_Availability__c where Contact__c=:con.Id];
        delete lAvailRecs;
        
        SC_Availability_DataFix_Batch myBatchObject = new SC_Availability_DataFix_Batch(5);
		Id batchId = Database.executeBatch(myBatchObject);
        Test.stopTest();
        
        System.assertEquals(7, [Select  count() from SC_SOCC_Availability__c where Contact__c=:con.Id]);
                
    }

}