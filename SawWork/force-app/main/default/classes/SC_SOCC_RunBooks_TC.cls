/*
Author          : Sumukh SS
Description     :  Test class for SOCC Car RunBooks
Test Class      : 

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Sep 2019         Sumukh/Pinkesh                              SOCC CAR 2 - RunBooks 
20 Aug 2020         Pinkesh                     ESESP-3730      Adding changes for Escalations via Case Email
07 Apr 2021         Tejaswini                   ESESP-4955      Increasing Code coverage
04 May 2021         Vikas                       ESESP-4955      Adding changes for SC_SOCC_CommunityController
20 Jun 2021         Tejaswini                   ESESP-5132      Adding changes for SC_SOCC_EscalationListCtrl class
------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class SC_SOCC_RunBooks_TC {
    private static User sysAdmin = SObjectFactory.ADMIN_USER;
    @testSetup
    static void setupMethod()
    {
        // Creating Account
        
        Test.startTest();
        
        Account accRec = new Account(Name='Test Account IP Address',AKAM_Account_ID__c='Test-ABC-1234IPAddr',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
        insert accRec; 
        
        //Creating Timezone records
        List<Timezone__c> lTimezones = new List<Timezone__c>();
        
        Timezone__c tz1 = new Timezone__c(Name ='Asia/Singapore',Offset__c='+8',Posix__c='Asia/Singapore');
        lTimezones.add(tz1);
        
        Timezone__c tz2 = new Timezone__c(Name ='America/Caracas',Offset__c='-4',Posix__c='America/Caracas');
        lTimezones.add(tz2);

        Timezone__c tz3 = new Timezone__c(Name ='GMT',Offset__c='0',Posix__c='GMT');
        lTimezones.add(tz3);

        
        insert lTimezones;
        //Creating contacts
        list<contact> lcont = new list<contact>();
        Contact conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz', Email = 'Test_xyz@akamai.com',
                                     No_Longer_with_Company__c = false, LastName = 'Test ContactAcc', Primary_Contact_Method__c = 'Phone',TimezoneNew__c =tz3.id);
        lcont.add(conRec);
        
        contact conRec2 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2', Email = 'Test_xyz2@akamai.com',
                                      No_Longer_with_Company__c = false, LastName = 'Test ContactAcc2', Primary_Contact_Method__c = 'Phone');
        
        lcont.add(conRec2);
        
               
        //Creating contacts to cover DST changes
        //List<Contact> conList = new List<Contact>();
        Contact rec1 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz11', Email = 'Test_xyz11@akamai.com',
                                   No_Longer_with_Company__c = false, LastName = 'Test ContactAcc11', Primary_Contact_Method__c = 'Phone',TimezoneNew__c =tz1.id);
        
        lcont.add(rec1);
        
        Contact rec2 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz12', Email = 'Test_xyz12@akamai.com',
                                     No_Longer_with_Company__c = false, LastName = 'Test ContactAcc12', Primary_Contact_Method__c = 'Phone',TimezoneNew__c =tz1.id);
        lcont.add(rec2);
        
        Contact rec3 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz13', Email = 'Test_xyz13@akamai.com',
                                     No_Longer_with_Company__c = false, LastName = 'Test ContactAcc13', Primary_Contact_Method__c = 'Mobile',TimezoneNew__c =tz2.id);
        lcont.add(rec3);
        
        Contact rec4 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz14', Email = 'Test_xyz14@akamai.com',
                                     No_Longer_with_Company__c = false, LastName = 'Test ContactAcc14', Primary_Contact_Method__c = 'Mobile',TimezoneNew__c =tz2.id);
        lcont.add(rec4);

        Contact rec5 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz15', Email = 'Test_xyz15@akamai.com',
                                     No_Longer_with_Company__c = false, LastName = 'Test ContactAcc15', Primary_Contact_Method__c = 'Mobile');
        lcont.add(rec5);
        
        
        //insert conList;
        insert lcont;
        
        Test.stopTest();
       
        List<user> u=[select id from user where profile.name like 'GSS Professional Services%' and email like '%akamai.com' and isactive=true limit 1];
        /*Profile p = [Select Id,Name from Profile  where name like 'GSS Professional Services' limit 1];
        User u;
        System.runAs(sysAdmin)
        {
            u = new User(alias = 'testUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='testOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__test_owner@akamai.com',profileid = p.Id);
            insert u;
        }*/
        // Creating Account Team
        List<AccountTeamMember> accTeamInsert = new List<AccountTeamMember>();
        if(u.size()>0)
        {
            accTeamInsert.add(new AccountTeamMember(AccountId = accRec.Id, UserId = u[0].id,TeamMemberRole='Security Services - Primary'));
            insert accTeamInsert;
        }
         
        //Creating Case Product
        EB_AccountProductMap__c eb_product = new EB_AccountProductMap__c();
        eb_product.Name = 'Kona DDoS Defender';
        eb_product.EB_MarkedForDeletion__c = false;
        eb_product.EB_Product__c='Kona DDoS Defender';
        eb_product.EB_Account__c=accRec.id;
        insert eb_product;
        
        // Creating Policy Domain
        Policy_Domain__c  Policy = new Policy_Domain__c();
        Policy.Name = 'TestClassPolicyDomain';
        Policy.Account_Name__c = accRec.Id;
        Policy.Product__c = 'Kona DDoS Defender';
        Policy.Policy_Domain_State__c  = 'Active';
        Policy.Additional_Product__c = 'Application-based Monitoring';
        Insert Policy;
        
        // Creating Handler Type
        Handler_Type__c  HandTypeRec = new Handler_Type__c (Name='Phone Call Handler Type',Fields_To_Show__c ='Situation_Instruction__c,Escalation_List__c');
        insert HandTypeRec;  
        
        // Creating Situation Catalog
        SC_SOCC_Situation_Catalog__c  SitCatRec = new SC_SOCC_Situation_Catalog__c (Handler_Type__c =HandTypeRec.id,Name='Kona DDoS DefenderAttack',Product__c  ='Kona DDoS Defender',Situation_Class__c ='Attack',Handler_Type_picklist__c ='Phone Call Handler Type');
        insert SitCatRec;  
        
        SC_SOCC_Escalation_List__c esclistrec=new SC_SOCC_Escalation_List__c (Policy_Domain__c =Policy.id,Name='Test escalation list name');
        insert esclistrec; 
        
        //Creating Handler
        List<Handler__c> lhandler = new List<Handler__c>();
        
        Handler__c handlerrec= new Handler__c (Name='TestHandler',Handler_Type__c =HandTypeRec.id, Policy_Domain__c =Policy.id,Escalation_List__c =esclistrec.id);
        lhandler.add(handlerrec);
        
        Handler__c handlerrec2= new Handler__c (Name='TestHandlerfordeletion',Handler_Type__c =HandTypeRec.id, Policy_Domain__c =Policy.id,Escalation_List__c =esclistrec.id);
        lhandler.add(handlerrec2);
        insert lhandler;
        
        // Creating situation to handler mapping
        SC_SOCC_Situation_to_Handler_Mapping__c s2hrec = new SC_SOCC_Situation_to_Handler_Mapping__c (Policy_Domain__c =Policy.id,Situation__c =SitCatRec.id, Handler__c =handlerrec.id);
        insert s2hrec;
        
        List<authorized_contact__c> lAuthcon = new List<authorized_contact__c>();
        authorized_contact__c authorizedcont = new authorized_contact__c(Policy_Domain__c =Policy.id, Contact_Name__c=lcont[0].id);
        //insert authorizedcont;
        lAuthcon.add(authorizedcont);
               
        Authorized_Contact__c authCon1 = new Authorized_Contact__c(Policy_Domain__c =Policy.id, Contact_Name__c=rec1.id);
        lAuthcon.add(authCon1);
        
        Authorized_Contact__c authCon2 = new Authorized_Contact__c(Policy_Domain__c =Policy.id, Contact_Name__c=rec2.id);
        lAuthcon.add(authCon2);
        
        Authorized_Contact__c authCon3 = new Authorized_Contact__c(Policy_Domain__c =Policy.id, Contact_Name__c=rec3.id);
        lAuthcon.add(authCon3);
        
        Authorized_Contact__c authCon4 = new Authorized_Contact__c(Policy_Domain__c =Policy.id, Contact_Name__c=rec4.id);
        lAuthcon.add(authCon4);

        Authorized_Contact__c authCon5 = new Authorized_Contact__c(Policy_Domain__c =Policy.id, Contact_Name__c=rec5.id);
        lAuthcon.add(authCon5);
        
        insert lAuthcon;
        
        /*SC_SOCC_Escalation_Contact__c esccontact = new SC_SOCC_Escalation_Contact__c(Name='test',Escalation_List__c=esclistrec.id,Order_Number__c=1, Authorized_Contact__c=authorizedcont.id);
        insert esccontact;*/
        
        List<SC_SOCC_Escalation_Contact__c> escConList = new List<SC_SOCC_Escalation_Contact__c>();
        
        SC_SOCC_Escalation_Contact__c esccontact = new SC_SOCC_Escalation_Contact__c(Name='test',Escalation_List__c=esclistrec.id,Order_Number__c=1, Authorized_Contact__c=authorizedcont.id);
        escConList.add(esccontact);
        
        SC_SOCC_Escalation_Contact__c escCon1 = new SC_SOCC_Escalation_Contact__c(Name='test1',Escalation_List__c=esclistrec.id,Order_Number__c=2, Authorized_Contact__c=authCon1.id);
        escConList.add(escCon1);
        
        SC_SOCC_Escalation_Contact__c escCon2 = new SC_SOCC_Escalation_Contact__c(Name='test2',Escalation_List__c=esclistrec.id,Order_Number__c=3, Authorized_Contact__c=authCon2.id);
        escConList.add(escCon2);
        
        SC_SOCC_Escalation_Contact__c escCon3 = new SC_SOCC_Escalation_Contact__c(Name='test3',Escalation_List__c=esclistrec.id,Order_Number__c=4, Authorized_Contact__c=authCon3.id);
        escConList.add(escCon3);
        
        SC_SOCC_Escalation_Contact__c escCon4 = new SC_SOCC_Escalation_Contact__c(Name='test4',Escalation_List__c=esclistrec.id,Order_Number__c=5, Authorized_Contact__c=authCon4.id);
        escConList.add(escCon4);

        SC_SOCC_Escalation_Contact__c escCon5 = new SC_SOCC_Escalation_Contact__c(Name='test4',Escalation_List__c=esclistrec.id,Order_Number__c=6, Authorized_Contact__c=authCon5.id);
        escConList.add(escCon5);
        
        insert escConList;
        
        
        SC_SOCC_Escalation_via_Case_Email__c esccontactForEmail = new SC_SOCC_Escalation_via_Case_Email__c(Name='test',Escalation_List__c=esclistrec.id, Authorized_Contact__c=authorizedcont.id);
        insert esccontactForEmail;
        
        DateTime myDateTime = DateTime.now();
        
        List<SC_SOCC_Availability__c> newRecords = new List<SC_SOCC_Availability__c>();
        SC_SOCC_Availability__c sc1 = new SC_SOCC_Availability__c();
        sc1.Day_Of_Week__c = 'Monday';
        sc1.Contact__c = lcont[0].id;
        sc1.Start_Time__c = Time.newInstance(0, 00, 0, 0);
        sc1.End_Time__c = Time.newInstance(23, 59, 0, 0);
        newRecords.add(sc1);
        
        SC_SOCC_Availability__c sc3 = new SC_SOCC_Availability__c();
        sc3.Day_Of_Week__c = 'Tuesday';
        sc3.Contact__c = lcont[0].id;
        sc3.Start_Time__c = Time.newInstance(2, 0, 0, 0);
        sc3.End_Time__c = Time.newInstance(3, 0, 0, 0);
        newRecords.add(sc3);
        
        /*SC_SOCC_Availability__c sc33 = new SC_SOCC_Availability__c();
        sc33.Day_Of_Week__c = 'Tuesday';
        sc33.Contact__c = lcont[0].id;
        sc33.Start_Time__c = Time.newInstance(5, 0, 0, 0);
        sc33.End_Time__c = Time.newInstance(6, 0, 0, 0);
        newRecords.add(sc33);
        
        SC_SOCC_Availability__c sc34 = new SC_SOCC_Availability__c();
        sc34.Day_Of_Week__c = 'Tuesday';
        sc34.Contact__c = lcont[0].id;
        sc34.Start_Time__c = Time.newInstance(0, 0, 0, 0);
        sc34.End_Time__c = Time.newInstance(1, 0, 0, 0);
        newRecords.add(sc34);*/
        
        SC_SOCC_Availability__c sc4 = new SC_SOCC_Availability__c();
        sc4.Day_Of_Week__c = 'Wednesday';
        sc4.Contact__c = lcont[0].id;
        sc4.Start_Time__c = Time.newInstance(2, 0, 0, 0);
        sc4.End_Time__c = Time.newInstance(4, 0, 0, 0);
        newRecords.add(sc4);
        
        SC_SOCC_Availability__c sc5 = new SC_SOCC_Availability__c();
        sc5.Day_Of_Week__c = 'Wednesday';
        sc5.Contact__c=lcont[0].id;
        sc5.Start_Time__c = Time.newInstance(2, 00, 0, 0);
        sc5.End_Time__c = Time.newInstance(18, 30, 0, 0);
        newRecords.add(sc5);
        
        SC_SOCC_Availability__c sc6 = new SC_SOCC_Availability__c();
        sc6.Day_Of_Week__c = 'Thursday';
        sc6.Contact__c=lcont[0].id;
        sc6.Start_Time__c = Time.newInstance(2, 00, 0, 0);
        sc6.End_Time__c = Time.newInstance(20, 0, 0, 0);
        newRecords.add(sc6);
        
        SC_SOCC_Availability__c sc7 = new SC_SOCC_Availability__c();
        sc7.Day_Of_Week__c = 'Friday';
        sc7.Contact__c=lcont[0].id;
        sc7.Start_Time__c = Time.newInstance(2, 0, 0, 0);
        sc7.End_Time__c = Time.newInstance(23, 59, 0, 0);
        newRecords.add(sc7);
        
        SC_SOCC_Availability__c sc8 = new SC_SOCC_Availability__c();
        sc8.Day_Of_Week__c = 'Saturday';
        sc8.Contact__c=lcont[0].id;
        sc8.Start_Time__c = Time.newInstance(19, 00, 0, 0);
        sc8.End_Time__c = Time.newInstance(20, 0, 0, 0);
        newRecords.add(sc8);
        
        SC_SOCC_Availability__c sc11 = new SC_SOCC_Availability__c();
        sc11.Day_Of_Week__c = 'Sunday';
        sc11.Contact__c=lcont[0].id;
        sc11.Start_Time__c = Time.newInstance(19, 0, 0, 0);
        sc11.End_Time__c = Time.newInstance(23, 59, 0, 0);
        newRecords.add(sc11);
        
                
        SC_SOCC_Availability__c sc13 = new SC_SOCC_Availability__c();
        sc13.Contact__c=lcont[0].id;
        //sc8.Start_Date_Time__c = DateTime.newInstance(2021,6,14,10,0,0);
        //sc8.End_Date_Time__c = DateTime.newInstance(2021,6,18,11,0,0);
        sc13.Start_Date_Time__c = myDateTime.addDays(-7);//myDateTime.addHours(5);
        sc13.End_Date_Time__c = myDateTime.addDays(1);//myDateTime.addDays(2).addHours(2);
        sc13.Out_Of_Office__c = true;
        newRecords.add(sc13);
        
        /*SC_SOCC_Availability__c sc14 = new SC_SOCC_Availability__c();
        sc14.Contact__c=lcont[0].id;
        //sc9.Start_Date_Time__c = DateTime.newInstance(2021,6,18,13,0,0);
        //sc9.End_Date_Time__c = DateTime.newInstance(2021,6,25,11,0,0);
        sc14.Start_Date_Time__c = myDateTime.addDays(3).addHours(10);
        sc14.End_Date_Time__c = myDateTime.addDays(9);
        sc14.Out_Of_Office__c = true;
        newRecords.add(sc14);
        
        SC_SOCC_Availability__c sc15 = new SC_SOCC_Availability__c();
        sc15.Contact__c=lcont[0].id;
        //sc10.Start_Date_Time__c = DateTime.newInstance(2021,6,11,13,0,0);
        //sc10.End_Date_Time__c = DateTime.newInstance(2021,6,13,23,59,0);
        sc15.Start_Date_Time__c = myDateTime.addDays(7).addHours(1);
        sc15.End_Date_Time__c = myDateTime.addDays(8).addHours(13);
        sc15.Out_Of_Office__c = true;
        newRecords.add(sc15);
        
        SC_SOCC_Availability__c sc16 = new SC_SOCC_Availability__c();
        sc16.Contact__c=lcont[0].id;
        //sc11.Start_Date_Time__c = DateTime.newInstance(2021,6,07,13,0,0);
        //sc11.End_Date_Time__c = DateTime.newInstance(2021,6,24,23,59,0);
        sc16.Start_Date_Time__c = myDateTime.addMinutes(30);
        sc16.End_Date_Time__c = myDateTime.addMinutes(50);
        sc16.Out_Of_Office__c = true;
        newRecords.add(sc16);
        
        SC_SOCC_Availability__c sc17 = new SC_SOCC_Availability__c();
        sc17.Contact__c=lcont[0].id;
        //sc11.Start_Date_Time__c = DateTime.newInstance(2021,6,07,13,0,0);
        //sc11.End_Date_Time__c = DateTime.newInstance(2021,6,24,23,59,0);
        sc17.Start_Date_Time__c = myDateTime.addDays(10);
        sc17.End_Date_Time__c = myDateTime.addDays(20);
        sc17.Out_Of_Office__c = true;
        newRecords.add(sc17);
        
        SC_SOCC_Availability__c sc18 = new SC_SOCC_Availability__c();
        sc18.Contact__c=lcont[0].id;
        //sc11.Start_Date_Time__c = DateTime.newInstance(2021,6,07,13,0,0);
        //sc11.End_Date_Time__c = DateTime.newInstance(2021,6,24,23,59,0);
        sc18.Start_Date_Time__c = myDateTime.addDays(-7);
        sc18.End_Date_Time__c = myDateTime.addDays(1);
        sc18.Out_Of_Office__c = true;
        newRecords.add(sc18);
        
        SC_SOCC_Availability__c sc19 = new SC_SOCC_Availability__c();
        sc19.Contact__c=lcont[0].id;
        //sc11.Start_Date_Time__c = DateTime.newInstance(2021,6,07,13,0,0);
        //sc11.End_Date_Time__c = DateTime.newInstance(2021,6,24,23,59,0);
        sc19.Start_Date_Time__c = myDateTime.addDays(-7);
        sc19.End_Date_Time__c = myDateTime.addDays(14);
        sc19.Out_Of_Office__c = true;
        newRecords.add(sc19);*/
        
        SC_SOCC_Availability__c avail1 = new SC_SOCC_Availability__c();
        avail1.Day_Of_Week__c = 'Thursday';
        avail1.Contact__c=rec1.id;
        avail1.Start_Time__c = Time.newInstance(00, 30, 0, 0);
        avail1.End_Time__c = Time.newInstance(0, 45, 0, 0);
        newRecords.add(avail1);
        
        SC_SOCC_Availability__c avail2 = new SC_SOCC_Availability__c();
        avail2.Day_Of_Week__c = 'Friday';
        avail2.Contact__c=rec1.id;
        avail2.Start_Time__c = Time.newInstance(1, 00, 0, 0);
        avail2.End_Time__c = Time.newInstance(10, 00, 0, 0);
        newRecords.add(avail2);

        SC_SOCC_Availability__c avail3 = new SC_SOCC_Availability__c();
        avail3.Contact__c=rec1.id;
        avail3.Day_Of_Week__c = 'Wednesday';
        avail3.Start_Time__c = Time.newInstance(11, 00, 0, 0);
        avail3.End_Time__c = Time.newInstance(12, 00, 0, 0);
        newRecords.add(avail3);
        
        SC_SOCC_Availability__c avail4 = new SC_SOCC_Availability__c();
        avail4.Contact__c=rec1.id;
        avail4.Start_Date_Time__c = myDateTime.addDays(2);
        avail4.End_Date_Time__c = myDateTime.addDays(3);
        avail4.Out_Of_Office__c = true;
        newRecords.add(avail4);
        
        SC_SOCC_Availability__c avail5 = new SC_SOCC_Availability__c();
        avail5.Day_Of_Week__c = 'Tuesday';
        avail5.Contact__c=rec2.id;
        avail5.Start_Time__c = Time.newInstance(00, 00, 0, 0);
        avail5.End_Time__c = Time.newInstance(23, 59, 0, 0);
        newRecords.add(avail5);      
        
        SC_SOCC_Availability__c avail6 = new SC_SOCC_Availability__c();
        avail6.Day_Of_Week__c = 'Saturday';
        avail6.Contact__c=rec2.id;
        avail6.Start_Time__c = Time.newInstance(20, 30, 0, 0);
        avail6.End_Time__c = Time.newInstance(22, 0, 0, 0);
        newRecords.add(avail6);
        
        SC_SOCC_Availability__c avail7 = new SC_SOCC_Availability__c();
        avail7.Day_Of_Week__c = 'Sunday';
        avail7.Contact__c=rec2.id;
        avail7.Start_Time__c = Time.newInstance(23, 10, 0, 0);
        avail7.End_Time__c = Time.newInstance(23, 30, 0, 0);
        newRecords.add(avail7);
        
        SC_SOCC_Availability__c avail8 = new SC_SOCC_Availability__c();
        avail8.Contact__c=rec2.id;
        avail8.Start_Date_Time__c = myDateTime.addDays(10);
        avail8.End_Date_Time__c = myDateTime.addDays(11);
        avail8.Out_Of_Office__c = true;
        newRecords.add(avail8);
        
        
        SC_SOCC_Availability__c avail9 = new SC_SOCC_Availability__c();
        avail9.Day_Of_Week__c = 'Monday';
        avail9.Contact__c=rec3.id;
        avail9.Start_Time__c = Time.newInstance(00, 30, 0, 0);
        avail9.End_Time__c = Time.newInstance(1, 0, 0, 0);
        newRecords.add(avail9);
        
        
        SC_SOCC_Availability__c avail10 = new SC_SOCC_Availability__c();
        avail10.Day_Of_Week__c = 'Sunday';
        avail10.Contact__c=rec3.id;
        avail10.Start_Time__c = Time.newInstance(1, 00, 0, 0);
        avail10.End_Time__c = Time.newInstance(13, 0, 0, 0);
        newRecords.add(avail10);
        
        SC_SOCC_Availability__c avail11 = new SC_SOCC_Availability__c();
        avail11.Day_Of_Week__c = 'Saturday';
        avail11.Contact__c=rec3.id;
        avail11.Start_Time__c = Time.newInstance(12, 00, 0, 0);
        avail11.End_Time__c = Time.newInstance(13, 0, 0, 0);
        newRecords.add(avail11);
        
        SC_SOCC_Availability__c avail12 = new SC_SOCC_Availability__c();
        avail12.Contact__c=rec3.id;
        avail12.Start_Date_Time__c = myDateTime.addDays(1);
        avail12.End_Date_Time__c = myDateTime.addDays(3);
        avail12.Out_Of_Office__c = true;
        newRecords.add(avail12);
                     
        SC_SOCC_Availability__c avail13 = new SC_SOCC_Availability__c();
        avail13.Day_Of_Week__c = 'Tuesday';
        avail13.Contact__c=rec4.id;
        avail13.Start_Time__c = Time.newInstance(00, 00, 0, 0);
        avail13.End_Time__c = Time.newInstance(23, 59, 0, 0);
        newRecords.add(avail13);
        
        SC_SOCC_Availability__c avail14 = new SC_SOCC_Availability__c();
        avail14.Day_Of_Week__c = 'Saturday';
        avail14.Contact__c=rec4.id;
        avail14.Start_Time__c = Time.newInstance(20, 30, 0, 0);
        avail14.End_Time__c = Time.newInstance(21, 30, 0, 0);
        newRecords.add(avail14);
        
        SC_SOCC_Availability__c avail15 = new SC_SOCC_Availability__c();
        avail15.Day_Of_Week__c = 'Monday';
        avail15.Contact__c=rec4.id;
        avail15.Start_Time__c = Time.newInstance(23, 30, 0, 0);
        avail15.End_Time__c = Time.newInstance(23, 59, 0, 0);
        newRecords.add(avail15);
        
        SC_SOCC_Availability__c avail16 = new SC_SOCC_Availability__c();
        avail16.Contact__c=rec4.id;
        avail16.Start_Date_Time__c = myDateTime.addDays(10);
        avail16.End_Date_Time__c = myDateTime.addDays(11);
        avail16.Out_Of_Office__c = true;
        newRecords.add(avail16);
        
        SC_SOCC_Availability__c avail17 = new SC_SOCC_Availability__c();
        avail17.Contact__c=rec4.id;
        avail17.Start_Date_Time__c = myDateTime.addDays(3);
        avail17.End_Date_Time__c = myDateTime.addDays(5);
        avail17.Out_Of_Office__c = true;
        newRecords.add(avail17);
        
        SC_SOCC_Availability__c avail18 = new SC_SOCC_Availability__c();
        avail18.Day_Of_Week__c = 'Monday';
        avail18.Contact__c=rec5.id;
        avail18.Start_Time__c = Time.newInstance(23, 30, 0, 0);
        avail18.End_Time__c = Time.newInstance(23, 59, 0, 0);
        newRecords.add(avail18);

        SC_SOCC_Availability__c avail19 = new SC_SOCC_Availability__c();
        avail19.Contact__c=rec5.id;
        avail19.Start_Date_Time__c = myDateTime.addDays(3);
        avail19.End_Date_Time__c = myDateTime.addDays(5);
        avail19.Out_Of_Office__c = true;
        newRecords.add(avail19);

        insert newRecords;
        
        
        List<SC_SOCC_Availability__c> updateList = new List<SC_SOCC_Availability__c>();
        
        avail1.Timezone_offset__c = +7;
        updateList.add(avail1);
        avail2.Timezone_offset__c = +7;
        updateList.add(avail2);
        avail3.Timezone_offset__c = +7;
        updateList.add(avail3);
        avail4.Timezone_offset__c = +7;
        updateList.add(avail4);
        
        avail5.Timezone_offset__c = +9;
        updateList.add(avail5);
        avail6.Timezone_offset__c = +9;
        updateList.add(avail6);
        avail7.Timezone_offset__c = +9;
        updateList.add(avail7);
        avail8.Timezone_offset__c = +9;
        updateList.add(avail8);  
        
        avail9.Timezone_offset__c = -5;
        updateList.add(avail9);
        avail10.Timezone_offset__c = -5;
        updateList.add(avail10);
        avail11.Timezone_offset__c = -5;
        updateList.add(avail11);
        avail12.Timezone_offset__c = -5;
        updateList.add(avail12);
        
        avail13.Timezone_offset__c = -3;
        updateList.add(avail13);
        avail14.Timezone_offset__c = -3;
        updateList.add(avail14);
        avail15.Timezone_offset__c = -3;
        updateList.add(avail15);
        avail16.Timezone_offset__c = -3;
        updateList.add(avail16);
        
        update updateList;
                
    }
    
    @isTest
    public static void Test_SC_SOCC_RUN_BOOKMethods(){
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //69
        Test.startTest();
        
        Policy_Domain__c Pdid = [select id,AKAM_Policy_Domain_ID__c from Policy_Domain__c limit 1];
        SC_SOCC_Situation_Catalog__c SitCatId=[Select id from SC_SOCC_Situation_Catalog__c limit 1];
        Handler__c HandlerId=[select id from Handler__c where Name='TestHandler' limit 1];
        Handler__c HandlerIdfordeletion=[select id from Handler__c where Name='TestHandlerfordeletion' limit 1];
        SC_SOCC_Situation_to_Handler_Mapping__c s2hmapping=[select id from SC_SOCC_Situation_to_Handler_Mapping__c limit 1];
        SC_SOCC_Escalation_List__c esclistid=[select id from SC_SOCC_Escalation_List__c limit 1];
        
        List<AccountTeamMember> acctteam=[select userid from AccountTeamMember limit 1];
        User runasaccteamcontext;
        if(acctteam.size()>0){
            Id uId = acctteam[0].userid;
            runasaccteamcontext=[select id from user where id=:uId limit 1];
        }
        
        
        SC_SOCC_RUN_BOOK.getSituationToHandlerMappings(Pdid.id);
        SC_SOCC_RUN_BOOK.getLightningBaseURL();
        SC_SOCC_RUN_BOOK.getCommunityContactURL();
        SC_SOCC_RUN_BOOK.getSituationsforPD(Pdid.id);
        if(runasaccteamcontext!=null)
        {
            system.runAs(runasaccteamcontext)
            {
                SC_SOCC_RUN_BOOK.createSituationToHandlerMapping(SitCatId.id,HandlerId.Id,Pdid.id); 
            }
        }
        
        SC_SOCC_RUN_BOOK.getAllHandlers(Pdid.id);
        SC_SOCC_RUN_BOOK.getHandlerPD(SitCatId.id,Pdid.id);
        SC_SOCC_RUN_BOOK.getHandlerFieldMappings();
        String encryptedPdId = SC_SOCC_CommunityController.encryptPDId(Pdid.AKAM_Policy_Domain_ID__c);
        SC_SOCC_RUN_BOOK.getPDID(encryptedPdId);
        SC_SOCC_RUN_BOOK.getassociatedSituations(HandlerId.Id);
        SC_SOCC_RUN_BOOK.showNotificationCase(HandlerId.Id);
        SC_SOCC_RUN_BOOK.getHandlerRecordDetails(HandlerId.Id);
        //SC_SOCC_RUN_BOOK.getInstruction(Pdid.id,HandlerId.Id);
        SC_SOCC_RUN_BOOK.getEscalationListRec(esclistid.id);
        SC_SOCC_RUN_BOOK.getSituationToHandlerMappingsHandlerEscalationContacts(Pdid.id);
        //SC_SOCC_RUN_BOOK.addMultipleInstructionforApproval(null,Pdid.id);
        list<id> handleridlist = new list<id>();
        handleridlist.add(HandlerIdfordeletion.Id);
        
        list<string>handleridstring = new list<string>();
        handleridstring.add(String.valueOf(HandlerId.id));
        
        SC_SOCC_RUN_BOOK.getHandlerEscContactList(handleridstring);
        SC_SOCC_RUN_BOOK.checkforPendingInstruction(handleridlist);
        SC_SOCC_RUN_BOOK.deleteSHMappingRecord(s2hmapping.id);
        SC_SOCC_RUN_BOOK.deleteAllHandlers(handleridlist,Pdid.id);
        SC_SOCC_RUN_BOOK.getCommunityAccess();
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //34
        Test.stopTest();
        
    }
    
    @isTest
    public static void Test_SC_SOCC_Handler_ControllerMethods(){
        Test.startTest();
        SC_SOCC_Escalation_List__c esclistid=[select id from SC_SOCC_Escalation_List__c limit 1];
        Handler__c HandlerId=[select id from Handler__c where Name='TestHandler' limit 1];
        Policy_Domain__c Pdid = [select id,AKAM_Policy_Domain_ID__c from Policy_Domain__c limit 1];
        
        SC_SOCC_Handler_Controller.getEscalationListContactDetails(esclistid.id);
        SC_SOCC_Handler_Controller.getHandlerEscalationContact(HandlerId.id);
        SC_SOCC_Handler_Controller.getHandlerCompleteDetails(HandlerId.id);
        SC_SOCC_Handler_Controller.getPolicyDomainRecord(Pdid.id);
        SC_SOCC_Handler_Controller.getFieldstoShow();
        Test.stopTest();
        
    }
    
    @isTest
    public static void Test_SC_SOCC_EscalationListCtrlMethods(){
        Test.startTest();
        
        SC_SOCC_Escalation_List__c escList = [select Id, Name, Policy_Domain__c, Policy_Domain__r.Account_Name__c from SC_SOCC_Escalation_List__c limit 1];
        SC_SOCC_Escalation_Contact__c escCon = [Select Id, Authorized_Contact__c, Authorized_Contact__r.Contact_Name__r.Name, Order_Number__c, Action_If_Unreachable__c from SC_SOCC_Escalation_Contact__c limit 1];
        List<SC_SOCC_Escalation_via_Case_Email__c> escConForEmail = [Select Id, Authorized_Contact__c, Authorized_Contact__r.Contact_Name__r.Name from SC_SOCC_Escalation_via_Case_Email__c limit 1];
        Handler__c handler = [select Id from Handler__c where Name = 'TestHandler' limit 1];
        Policy_Domain__c pd = [select Id, AKAM_Policy_Domain_ID__c from Policy_Domain__c limit 1];
        List<SC_SOCC_Availability__c> lAvailability = [select Id, Availability__c, Start_Time__c, End_Time__c from SC_SOCC_Availability__c limit 100];
        contact con = [select Id from Contact where Email = 'Test_xyz@akamai.com' limit 1];
        contact conWithoutAvailability = [select Id from Contact where Email='Test_xyz2@akamai.com' limit 1];
        Authorized_Contact__c authCon = [select Id from Authorized_Contact__c limit 1];
        
        List<string> lAuthConId= new List<string>();
        lAuthConId.add(authCon.id);
        
        //For Copy Escalation Lists
        SC_SOCC_Escalation_List__c copiedEscList = new SC_SOCC_Escalation_List__c(Name='Test Copy EL 1', Policy_Domain__c=pd.Id);
        List<SC_SOCC_Escalation_List__c> lCopiedEscList = new List<SC_SOCC_Escalation_List__c>();
        lCopiedEscList.add(copiedEscList);
        String lCopiedEscListJSON = JSON.serialize(lCopiedEscList);
        
        //For Saving complete Escalation List
        /*SC_SOCC_EscalationListCtrl.EscalationContactWrapper selectedEscalationContacts = new SC_SOCC_EscalationListCtrl.EscalationContactWrapper();
        selectedEscalationContacts.escCon=escCon;
        selectedEscalationContacts.lAvailability=lAvailability;
        List<SC_SOCC_EscalationListCtrl.EscalationContactWrapper> lSelectedEscalationContacts = new List<SC_SOCC_EscalationListCtrl.EscalationContactWrapper>();
        lSelectedEscalationContacts.add(selectedEscalationContacts);
        String lSelectedEscalationContactsJson = JSON.serialize(lSelectedEscalationContacts);*/
        
        SC_SOCC_EscalationListCtrl.AvailabilityDetailsWrapper selectedEscalationContacts = new SC_SOCC_EscalationListCtrl.AvailabilityDetailsWrapper();
        selectedEscalationContacts.escCon=escCon;
        //selectedEscalationContacts.lAvailability=lAvailability;
        List<SC_SOCC_EscalationListCtrl.AvailabilityDetailsWrapper> lSelectedEscalationContacts = new List<SC_SOCC_EscalationListCtrl.AvailabilityDetailsWrapper>();
        lSelectedEscalationContacts.add(selectedEscalationContacts);
        String lSelectedEscalationContactsJson = JSON.serialize(lSelectedEscalationContacts);
        
        List<String> lEscConIdForSave = new List<String>();
        lEscConIdForSave.add(Id.valueOf(escCon.Id));
        List<String> lEscConForEmailIdForSave = new List<String>();
        lEscConForEmailIdForSave.add(Id.valueOf(escConForEmail[0].Id));
        
        
        SC_SOCC_EscalationListCtrl.EscalationListInstructionWrapper escalationListInstructionWrapper = SC_SOCC_EscalationListCtrl.getData(pd.Id, escList.Id);
        escalationListInstructionWrapper = SC_SOCC_EscalationListCtrl.getData(pd.Id, '');
        SC_SOCC_EscalationListCtrl.getAuthorizedContactRecords(pd.Id, lAuthConId);
        SC_SOCC_EscalationListCtrl.getAuthorizedContactRecords(pd.Id, null);
        //SC_SOCC_EscalationListCtrl.getAvailabiltyRecords(con.Id);
        //SC_SOCC_EscalationListCtrl.getAvailabiltyRecords(conWithoutAvailability.Id);    
        SC_SOCC_EscalationListCtrl.getEscalationContactRecords(pd.Id, escList.Id, true);
        SC_SOCC_EscalationListCtrl.getEscalationContactRecords(pd.Id, escList.Id, false);
        SC_SOCC_EscalationListCtrl.getlEscalationList(pd.Id);
        SC_SOCC_EscalationListCtrl.getlPDForCopy(escList); 
        SC_SOCC_EscalationListCtrl.getInvalidEscalationContacts(pd.Id, escList.Id);
        SC_SOCC_EscalationListCtrl.getAssociatedHandlers(escList.Id);
        //SC_SOCC_EscalationListCtrl.bulkUpdateContactAvailability(lAvailability);
        //Changes for ESESP-4955
        //SC_SOCC_EscalationListCtrl.ValidAndInvalidEscalationListWrapper validAndInvalidEscalationListWrapper = SC_SOCC_EscalationListCtrl.copyAllEscaltionListFromAura(escList, lCopiedEscListJSON);
        SC_SOCC_EscalationListCtrl.copyAllEscaltionListFromAura(escList, lCopiedEscListJSON);
        String escalationListId = SC_SOCC_EscalationListCtrl.saveCompleteEscalationList(escList, lSelectedEscalationContactsJson, lEscConIdForSave, escConForEmail, lEscConForEmailIdForSave, '');
        SC_SOCC_EscalationListCtrl.delEachEscList(pd.Id, escList.Id);
        
        //Changes by Tejaswini for ESESP-5132 
        String pds = '';
        List < String > lAuthConIdForEmail = new List < String >();
        SC_SOCC_EscalationListCtrl.getAuthorizedContactRecordsForEmail(pds,lAuthConIdForEmail);
        pds+=pd.Id;       
        SC_SOCC_EscalationListCtrl.getAuthorizedContactRecordsForEmail(pds,lAuthConIdForEmail);
            
        System.debug('Number of Queries used in this apex code so far esccontroller: ' + Limits.getQueries());
        //61
        Test.stopTest();
    }

    //Changes by Tejaswini for ESESP-5132 
    @isTest
    public static void Test_SC_SOCC_EscalationListCtrlMethods2(){
     
        Map < String, Integer > mDayNo = new Map < String, Integer > {'Monday'=>1,'Tuesday'=>2,'Wednesday'=>3,'Thursday'=>4,'Friday'=>5,'Saturday'=>6,'Sunday'=>7};
        Map<Id,List<SC_SOCC_EscalationListCtrl.TimeDetails>> mOffSetRec = new Map<Id,List<SC_SOCC_EscalationListCtrl.TimeDetails>>();
        Map<Id,List<SC_SOCC_EscalationListCtrl.TimeDetails>> mOffSetRec1 = new Map<Id,List<SC_SOCC_EscalationListCtrl.TimeDetails>>();
        List<Id> lConId = new List<Id>();
        Map <Id, Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>>> mConIdLAvailibilityRecs = new Map <Id,Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>>> ();
        Test.startTest();
        System.debug('Test_SC_SOCC_EscalationListCtrlMethods2'); 
        System.debug('###Number of Queries used in this apex code so far: ' + Limits.getQueries());              
        Contact con = [select Id from Contact where Email = 'Test_xyz@akamai.com' limit 1];
        lConId.add(con.Id);
        List<SC_SOCC_Availability__c> lAvailability = [SELECT Id, Availability__c, Contact__c, Day_Of_Week__c, Start_Time__c, End_Time__c FROM SC_SOCC_Availability__c WHERE Contact__c in: lConId ORDER BY Day_Of_Week__c, Start_Time__c limit 100];
        for (SC_SOCC_Availability__c eachRec:lAvailability)
        {
            if (eachRec.Start_Time__c != null && eachRec.End_Time__c != null) {
            if (!mConIdLAvailibilityRecs.containsKey(eachRec.Contact__c)) {
              mConIdLAvailibilityRecs.put(eachRec.Contact__c, new Map < Integer, List < SC_SOCC_EscalationListCtrl.TimeDetails >> ());
            }
            Map < Integer, List < SC_SOCC_EscalationListCtrl.TimeDetails >> dayNoAndAvailMap = mConIdLAvailibilityRecs.get(eachRec.Contact__c);
            Integer key = mDayNo.get(eachRec.Day_Of_Week__c);
            if (!dayNoAndAvailMap.containsKey(key)) {
              dayNoAndAvailMap.put(key, new List < SC_SOCC_EscalationListCtrl.TimeDetails> ());
            }
            List <SC_SOCC_EscalationListCtrl.TimeDetails > tempAvailRecords = dayNoAndAvailMap.get(key);  
            SC_SOCC_EscalationListCtrl.TimeDetails timerec = new SC_SOCC_EscalationListCtrl.TimeDetails();
            timerec.startTime = eachRec.Start_Time__c;
            timerec.endTime = eachRec.End_Time__c;
  
            tempAvailRecords.add(timerec);
            dayNoAndAvailMap.put(key, tempAvailRecords);
            mConIdLAvailibilityRecs.put(eachRec.Contact__c, dayNoAndAvailMap);
          }
        }
        //For +ve Timezone
        Integer tzOffsetMS = 19800000;
        String tzOffset ='+05:30';
        Map<Id,Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>>> map1 = SC_SOCC_EscalationListCtrl.getAvailabilityMapInUserTZ(tzOffsetMS,tzOffset,mConIdLAvailibilityRecs,lConId,mOffSetRec);
        
        //For -ve Timezone
        Integer tzOffsetMS2 = -14400000;
        String tzOffset2 ='-04:00';
        Map<Id,Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>>> map2 = SC_SOCC_EscalationListCtrl.getAvailabilityMapInUserTZ(tzOffsetMS2,tzOffset2,mConIdLAvailibilityRecs,lConId,mOffSetRec);
        
        //when OOO is there for that day
        /*List<SC_SOCC_EscalationListCtrl.TimeDetails> lrecs = new List<SC_SOCC_EscalationListCtrl.TimeDetails>();
        SC_SOCC_EscalationListCtrl.TimeDetails rec = new SC_SOCC_EscalationListCtrl.TimeDetails();
        rec.startTime = Time.newInstance(2, 0, 0, 0);
        rec.endTime = Time.newInstance(5, 0, 0, 0);
        lrecs.add(rec);
        mOffSetRec.put(con.Id,lrecs);*/
        //Map<Id,Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>>> map3 = SC_SOCC_EscalationListCtrl.getAvailabilityMapInUserTZ(tzOffsetMS,tzOffset,mConIdLAvailibilityRecs,lConId,true,mOffSetRec);
        //Map<Id,Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>>> map4 = SC_SOCC_EscalationListCtrl.getAvailabilityMapInUserTZ(tzOffsetMS2,tzOffset2,mConIdLAvailibilityRecs,lConId,true,mOffSetRec);
        
        /*Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>> map5 = mConIdLAvailibilityRecs.get(con.Id);
        map5.remove(1);
        
        Map <Id, Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>>> map6 = new Map <Id, Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>>>();
        map6.put(con.Id,map5);
        
        Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>> map7 = mConIdLAvailibilityRecs.get(con.Id);
        map7.remove(7);
        
        Map <Id, Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>>> map8 = new Map <Id, Map<Integer,List<SC_SOCC_EscalationListCtrl.TimeDetails>>>();
        map8.put(con.Id,map7);*/
        
        //SC_SOCC_EscalationListCtrl.getAvailabilityMapInUserTZ(tzOffsetMS,tzOffset,map6,lConId,true,mOffSetRec);
        //SC_SOCC_EscalationListCtrl.getAvailabilityMapInUserTZ(tzOffsetMS2,tzOffset2,map8,lConId,true,mOffSetRec);
        
        /*Map < Id, List < SC_SOCC_EscalationListCtrl.DateTimeDetail >> mOOORecordsOfWeek = new Map < Id, List < SC_SOCC_EscalationListCtrl.DateTimeDetail >> ();
        for (SC_SOCC_Availability__c eachRec: [Select Id, Contact__c, Start_Date_Time__c, End_Date_Time__c from SC_SOCC_Availability__c WHERE Contact__c in: lConId and Out_Of_Office__c = true and Record_In_Current_Week__c = true ORDER BY Start_Date_Time__c]) {
            if (!mOOORecordsOfWeek.containsKey(eachRec.Contact__c)) {
            mOOORecordsOfWeek.put(eachRec.Contact__c, new List < SC_SOCC_EscalationListCtrl.DateTimeDetail > ());
          }  
          List < SC_SOCC_EscalationListCtrl.DateTimeDetail > lOutOfOfficeRecs = mOOORecordsOfWeek.get(eachRec.Contact__c);
          Integer sthr = (eachRec.Start_Date_Time__c).hourGmt();
          Integer stmin = (eachRec.Start_Date_Time__c).minuteGmt();
          Time startTime = Time.newInstance(sthr, stmin, 0, 0);
  
          Integer ethr = (eachRec.End_Date_Time__c).hourGmt();
          Integer etmin = (eachRec.End_Date_Time__c).minuteGmt();
          Time endTime = Time.newInstance(ethr, etmin, 0, 0);
  
          Date startDate = Date.newInstance((eachRec.Start_Date_Time__c).yearGmt(), (eachRec.Start_Date_Time__c).monthGmt(), (eachRec.Start_Date_Time__c).dayGmt());
          Date endDate = Date.newInstance((eachRec.End_Date_Time__c).yearGmt(), (eachRec.End_Date_Time__c).monthGmt(), (eachRec.End_Date_Time__c).dayGmt());
          SC_SOCC_EscalationListCtrl.DateTimeDetail oooRec = new SC_SOCC_EscalationListCtrl.DateTimeDetail();
          oooRec.startDateTime = eachRec.Start_Date_Time__c;
          oooRec.endDateTime = eachRec.End_Date_Time__c;
          oooRec.startTime = startTime;
          oooRec.endTime = endTime;
          oooRec.startDate = startDate;
          oooRec.endDate = endDate;
          lOutOfOfficeRecs.add(oooRec);
  
          mOOORecordsOfWeek.put(eachRec.Contact__c, lOutOfOfficeRecs);  
        }*/
        DateTime myDateTime = DateTime.now();
        String day = myDateTime.formatGMT('EEEE');
        Integer dayNo = mDayNo.get(day);

        Integer dd = myDateTime.dayGmt();
        Integer mm = myDateTime.monthGmt();
        Integer yy = myDateTime.yearGmt();
        
        DateTime weekStartDate = Datetime.newInstanceGmt(yy,mm,dd).addDays(1 - dayNo);
        DateTime weekEndDate   = Datetime.newInstanceGmt(yy,mm,dd,23,59,59).addDays(7 - dayNo);
        
        //mOffSetRec = SC_SOCC_EscalationListCtrl.getMapOfOffSetRec(mOOORecordsOfWeek,lConId,tzOffsetMS,tzOffset,weekStartDate,weekEndDate);
        
        //mOffSetRec1 = SC_SOCC_EscalationListCtrl.getMapOfOffSetRec(mOOORecordsOfWeek,lConId,tzOffsetMS2,tzOffset2,weekStartDate,weekEndDate);
        
        List<SC_SOCC_EscalationListCtrl.DateTimeDetail> lOOOData = new List<SC_SOCC_EscalationListCtrl.DateTimeDetail>();
        SC_SOCC_EscalationListCtrl.DateTimeDetail ooorec = new SC_SOCC_EscalationListCtrl.DateTimeDetail();
        ooorec.startDateTime = (DateTime.now()).addDays(1);
        ooorec.endDateTime = (DateTime.now()).addDays(10);
        lOOOData.add(ooorec);
        
        String data = SC_SOCC_EscalationListCtrl.getOOODataInString(lOOOData,weekStartDate,tzOffsetMS2,tzOffset2);
        
        List<Time> lTimeRecs = new List<Time>();
        
        String status = SC_SOCC_EscalationListCtrl.getDayAvailabilityStatus(lTimeRecs);
        
        Time t1 = Time.newInstance(0, 0, 0, 0);
        lTimeRecs.add(t1);
        Time t2 = Time.newInstance(23,59,0,0);
        lTimeRecs.add(t2);
        String status1 = SC_SOCC_EscalationListCtrl.getDayAvailabilityStatus(lTimeRecs);
        
        String list2 = SC_SOCC_EscalationListCtrl.getAvailDataInString(lTimeRecs);
        
        lTimeRecs.clear();
        Time t3 = Time.newInstance(0, 0, 0, 0);
        lTimeRecs.add(t3);
        Time t4 = Time.newInstance(10,0,0,0);
        lTimeRecs.add(t4);
        String status2 = SC_SOCC_EscalationListCtrl.getDayAvailabilityStatus(lTimeRecs);

        System.debug('###Number of Queries used in this apex code so far: ' + Limits.getQueries());
        
        Test.stopTest();
    }    
    
    @isTest
    public static void Test_SC_SOCC_APIMethods()
    {
        Test.startTest();
        
        Account acc = [Select Id from Account limit 1];
        Policy_Domain__c pd = [select Id, AKAM_Policy_Domain_ID__c from Policy_Domain__c limit 1];
        SC_SOCC_Escalation_List__c escList = [select Id, Akam_Escalation_List_Id__c, Name, Policy_Domain__c, Policy_Domain__r.Account_Name__c from SC_SOCC_Escalation_List__c limit 1];
        contact con = [select Id, AKAM_Contact_ID__c from Contact where Email = 'Test_xyz@akamai.com' limit 1];
        
        /*User soccUser = [Select Id from User where Profile.Name = 'Managed Security – SOC' and isActive=true limit 1];
        User amgUser = [Select Id from User where Profile.Name = 'Support - AMG Agent' and isActive=true and email like '%@akamai.com%' limit 1];
        
        Account accRec = new Account(Name='SOCC User Account Mapping Test',AKAM_Account_ID__c='Test-ABC-1234SUAM',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
        insert accRec;
        // Creating Policy Domain
        Policy_Domain__c  Policy = new Policy_Domain__c();
        Policy.Name = 'TestClassPolicyDomainUAM';
        Policy.Account_Name__c = accRec.Id;
        Policy.Product__c = 'Kona DDoS Defender';
        Policy.Policy_Domain_State__c  = 'Active';
        Policy.Additional_Product__c = 'Application-based Monitoring';
        Insert Policy;
        
        SOCC_User_Account_Mapping__c  userAccountMapping = new SOCC_User_Account_Mapping__c(PD_Account__c=accRec.id, Internal_User__c=amgUser.id, Active__c=true);
        insert userAccountMapping;
        system.runAs(amgUser){
            SC_SOCC_CommunityController.getPDList();
        }
        userAccountMapping.Internal_User__c = soccUser.Id;
        update userAccountMapping;
        userAccountMapping.Active__c = false;
        update userAccountMapping;*/
        
        
        
        SC_SOCC_APIMethods.copyEL(escList.Akam_Escalation_List_Id__c, pd.AKAM_Policy_Domain_ID__c, 'Test EL Name API', con.AKAM_Contact_ID__c);
        Test.stopTest();
        
    }
    
    @isTest
    public static void Test_SC_SOCC_UserAccountMapping_Trigger()
    {
        Id amgProfile, PSProfile,adminProfile;
        /*for( Profile pf :[SELECT Id,Name FROM Profile WHERE Name = 'Support - AMG Agent' OR Name = 'GSS Professional Services' or name = 'System Administrator']){
            if( pf.Name == 'Support - AMG Agent')
                amgProfile = pf.id;
            else if(pf.Name == 'GSS Professional Services')
                PSProfile = pf.Id;
            else
                adminProfile = pf.id;
            
        }*/
        /*User adminUser = new User(LastName = 'LIVESTON1',
                           FirstName='JASON1',
                           Alias = 'jlsusiv1',
                           Email = 'adminw.xvdgsjk@akamai.com',
                           Username = 'adminw.xvdgsjk@akamai.com',
                           ProfileId = adminProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        insert adminUser;*/
        
        /*User amgUser = new User(LastName = 'LIVESTON1',
                           FirstName='JASON1',
                           Alias = 'amgldiv1',
                           Email = 'amgw.xvdgsjk@akamai.com',
                           Username = 'amgw.xvdgsjk@akamai.com',
                           ProfileId = amgProfile,
                           Title = 'Account Service Manager..',
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        insert amgUser;*/
        Test.startTest();
        System.debug('1. ESESP-5132 number of Queries used in this apex code so far: ' + Limits.getQueries());
        User adminUser = [Select Id from User where Profile.Name = 'System Administrator' and isActive=true limit 1];
        User amgUser = [Select Id from User where Profile.Name = 'Support - AMG Agent' and Title = 'Account Service Manager..' and isActive=true limit 1];
        User soccUser = [Select Id from User where Profile.Name = 'Managed Security – SOC' and isActive=true limit 1];
        List<user> psUser = [Select Id from User where Profile.Name = 'GSS Professional Services' and email like '%akamai.com' and isActive=true limit 1];
        List<user> psUserManager = [Select Id from User where Profile.Name = 'GSS Professional Services Manager' and email like '%akamai.com' and isActive=true limit 1];
        List<user> customerUser = [Select Id from User where Profile.Name = 'SFCommunityCustomers' and isActive=true limit 1];
        
        System.debug('1.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        system.runAs(adminUser){
            //Test.startTest();
            Account accRec = new Account(Name='SOCC User Account Mapping Test',AKAM_Account_ID__c='Test-ABC-1234SUAM',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
            insert accRec;
            /*Account accRecDup = new Account(Name='SOCC User Account Mapping Testcvgdks',AKAM_Account_ID__c='Test-ABC-123SUAMiy',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
            insert accRecDup;*/
            List<AccountTeamMember> lAccTeamMem = new List<AccountTeamMember>();
            AccountTeamMember actTM;
            if(psUser.size()>0)
            {
                actTM = new AccountTeamMember(AccountId = accRec.id, UserId = psUser[0].id, TeamMemberRole = 'Security Services - Primary');
                //insert actTM;
                lAccTeamMem.add(actTM);
            }
            if(psUserManager.size()>0)
            {
                AccountTeamMember actTMManager = new AccountTeamMember(AccountId = accRec.id, UserId = psUserManager[0].id, TeamMemberRole = 'Sales - Primary');
                //insert actTMManager;
                lAccTeamMem.add(actTMManager);
            }         
           
            if(lAccTeamMem.size()>0)
            {
                insert lAccTeamMem;
            }
            // Creating Policy Domain
            Policy_Domain__c  Policy = new Policy_Domain__c();
            Policy.Name = 'TestClassPolicyDomainUAM';
            Policy.Account_Name__c = accRec.Id;
            Policy.Product__c = 'Kona DDoS Defender';
            Policy.Policy_Domain_State__c  = 'Active';
            Policy.Additional_Product__c = 'Application-based Monitoring';
            Policy.AKAM_Policy_Domain_ID__c = 'TestPDCom';
            Insert Policy;
            
            // Creating Handler Type    
            Handler_Type__c  handlerTypeRec = new Handler_Type__c(Name='Phone Call Handler Type', Fields_To_Show__c='Situation_Instruction__c,Escalation_List__c'); 
            insert handlerTypeRec;  
                
            //Creating Handler  
            Handler__c handlerRec = new Handler__c(Name='TestHandler', Policy_Domain__c=Policy.Id, Handler_Type__c=handlerTypeRec.Id);  
            insert handlerRec;  
                
            if(customerUser.size()>0)
            {
                system.runAs(customerUser[0]){  
                Instruction__c instruction1 = new Instruction__c(Handler__c=handlerRec.Id, Instructions_Type__c='Situation Instruction', Status__c='In Progress', Value__c='Test Situation Instruction');   
                insert instruction1;    
                }   
            }
                
            SC_SOCC_CommunityController.fetchInstructions(SC_SOCC_CommunityController.encryptPDId(Policy.AKAM_Policy_Domain_ID__c));
            
            List<SOCC_User_Account_Mapping__c> lUserAccMap = new List<SOCC_User_Account_Mapping__c>();
            SOCC_User_Account_Mapping__c  userAccountMapping = new SOCC_User_Account_Mapping__c(PD_Account__c=accRec.id, Internal_User__c=amgUser.id, Active__c=true);
            //insert userAccountMapping;
            lUserAccMap.add(userAccountMapping);
            
            SOCC_User_Account_Mapping__c  userAccountMappingSOCC = new SOCC_User_Account_Mapping__c(PD_Account__c=accRec.id, Internal_User__c=soccUser.id, Active__c=true);
            //insert userAccountMappingSOCC;
            lUserAccMap.add(userAccountMappingSOCC);
            
            SOCC_User_Account_Mapping__c  userAccountMappingPS = new SOCC_User_Account_Mapping__c(PD_Account__c=accRec.id, Internal_User__c=soccUser.id, Active__c=true);
            lUserAccMap.add(userAccountMappingPS);
            
            insert lUserAccMap;
            
            system.runAs(amgUser){
                SC_SOCC_CommunityController.getPDList();
                SC_SOCC_CommunityController.getContactEmailAddress();
                String encryptedPDId = SC_SOCC_CommunityController.encryptPDId(Policy.AKAM_Policy_Domain_ID__c);
                SC_SOCC_RUN_BOOK.getPDID(encryptedPDId);
            }
            userAccountMapping.Internal_User__c = soccUser.Id;
            
            try{
                update userAccountMapping;
            }
            catch(Exception e){
                
            }
            if(psUser.size()>0)
            {
            userAccountMapping.Internal_User__c = psUser[0].Id;
            try{
                update userAccountMapping;
            }
            catch(Exception e){
                
            }
                userAccountMapping.Active__c = false;
            update userAccountMapping;
            }            
            
            
            userAccountMappingSOCC.Active__c = false;
            update userAccountMappingSOCC;
            
            /*SOCC_User_Account_Mapping__c  userAccountMappingPS = new SOCC_User_Account_Mapping__c(PD_Account__c=accRec.id, Internal_User__c=soccUser.id, Active__c=true);
            insert userAccountMappingPS;*/
            if(actTM!=null)
            {
                actTM.TeamMemberRole = 'ADS AM';
                update actTM;
            } 
            if(psUser.size()>0)
            {
                userAccountMappingPS.Internal_User__c = psUser[0].Id;
                try{
                update userAccountMappingPS;
                }
                catch(Exception e){
                
                }
            }
            
            if(psUserManager.size()>0){
            userAccountMappingPS.Internal_User__c = psUserManager[0].id;
            try{
                update userAccountMappingPS;
            }
            catch(Exception e){
                
                }
            }
            if(psUserManager.size()>0){
            SOCC_User_Account_Mapping__c  userAccountMappingPSInsert = new SOCC_User_Account_Mapping__c(PD_Account__c=accRec.id, Internal_User__c=psUserManager[0].id, Active__c=true);
            try{
                insert userAccountMappingPSInsert;
             }
            catch(Exception e){
                
                }
            }
            /*SOCC_User_Account_Mapping__c uamSocc = new SOCC_User_Account_Mapping__c(PD_Account__c=accRec.id, Internal_User__c=amgUser.id, Active__c=true);
            insert uamSocc;
            
            SOCC_User_Account_Mapping__c uamSoccDup = new SOCC_User_Account_Mapping__c(PD_Account__c=accRecDup.id, Internal_User__c=amgUser.id, Active__c=false);
            insert uamSoccDup;
            uamSoccDup.Active__c = true;
            update uamSoccDup;*/
            
            //Test.stopTest();
        }
        System.debug('2. ESESP-5132 number of Queries used in this apex code so far: ' + Limits.getQueries());
        Test.stopTest();
    }
    @isTest
    public static void Test_SC_SOCC_UserAccountMapping_Trigger1 ()
    { 
        test.startTest();
        System.debug('11. ESESP-5132 number of Queries used in this apex code so far: ' + Limits.getQueries());
        User adminUser = [Select Id from User where Profile.Name = 'System Administrator' and isActive=true limit 1];
        User amgUser = [Select Id from User where Profile.Name = 'Support - AMG Agent' and Title = 'Account Service Manager..' and isActive=true limit 1];

        system.runAs(sysAdmin){
            //test.startTest();
            List<Account> lAcc = new List<Account>();
            Account accRecDup = new Account(Name='SOCC User Account Mapping Testcvgdks',AKAM_Account_ID__c='Test-ABC-123SUAMiy',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
            //insert accRecDup;
            lAcc.add(accRecDup);
            Account accRec = new Account(Name='SOCC User Account Mapping Test',AKAM_Account_ID__c='Test-ABC-1234SUAM',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
            //insert accRec;
            lAcc.add(accRec);
            
            insert lAcc;
            
            List<SOCC_User_Account_Mapping__c> lUserAccMap = new List<SOCC_User_Account_Mapping__c>();
            SOCC_User_Account_Mapping__c uamSocc = new SOCC_User_Account_Mapping__c(PD_Account__c=accRec.id, Internal_User__c=amgUser.id, Active__c=true);
            //insert uamSocc;
            lUserAccMap.add(uamSocc);
            SOCC_User_Account_Mapping__c uamSoccDup = new SOCC_User_Account_Mapping__c(PD_Account__c=accRecDup.id, Internal_User__c=amgUser.id, Active__c=false);
            //insert uamSoccDup;
            lUserAccMap.add(uamSoccDup);
            
            insert lUserAccMap;
            
            uamSoccDup.Active__c = true;
            update uamSoccDup;
            //test.stopTest();
        }
        System.debug('12. ESESP-5132 number of Queries used in this apex code so far: ' + Limits.getQueries());
        test.stopTest();
        
    }
    @isTest
    public static void Test_triggerCoverage ()
    {       
        Test.startTest();
        //Insert Situation
        Handler_Type__c HandTypeRec = [select Id from Handler_Type__c limit 1];
        SC_SOCC_Situation_Catalog__c  SitCatRec = new SC_SOCC_Situation_Catalog__c (Handler_Type__c =HandTypeRec.id,Name='Kona DDoS DefenderAttack2',Product__c ='Kona DDoS Defender',Situation_Class__c ='Attack',Handler_Type_picklist__c ='Phone Call Handler Type');
        insert SitCatRec; 
        
         Handler_Type__c  HandTypeRec2 = new Handler_Type__c (Name='Service Request Emailed to SOCC Handler Type',Fields_To_Show__c ='Situation_Instruction__c,Escalation_List__c');
        insert HandTypeRec2;  
        
         SC_SOCC_Situation_Catalog__c upsertData = new SC_SOCC_Situation_Catalog__c(id=SitCatRec.id,Handler_Type_picklist__c='Service Request Emailed to SOCC Handler Type');
        upsert upsertData id;
        
        //Delete Escalation Contact
        SC_SOCC_Escalation_Contact__c escCon = [Select Id, Authorized_Contact__c, Authorized_Contact__r.Contact_Name__r.Name, Order_Number__c, Action_If_Unreachable__c from SC_SOCC_Escalation_Contact__c limit 1];
        delete(escCon);
        
        //Delete Escalation Contact
        SC_SOCC_Escalation_via_Case_Email__c escConForEmail = [Select Id, Authorized_Contact__c from SC_SOCC_Escalation_via_Case_Email__c limit 1];
        delete(escConForEmail);
        Test.stopTest();
    }
}