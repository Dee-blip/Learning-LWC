@isTest(seeAllData=false)
public class SC_SOCC_RB_Print_PDF_TC {

    @testSetup
    static void setupMethod()
    {
        // Creating Account
        Test.startTest();
        Account accRec = new Account(Name='Test Account IP Address',AKAM_Account_ID__c='Test-ABC-1234IPAddr',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
        insert accRec; 
        
        list<contact> lcont = new list<contact>();
        Contact conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz', Email = 'Test_xyz@akamai.com',
                                     No_Longer_with_Company__c = false, LastName = 'Test ContactAcc', Primary_Contact_Method__c = 'Phone');
        lcont.add(conRec);
        
        contact conRec2 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2', Email = 'Test_xyz2@akamai.com',
                                      No_Longer_with_Company__c = false, LastName = 'Test ContactAcc2', Primary_Contact_Method__c = 'Phone');
        
        lcont.add(conRec2);
        
        insert lcont;
        
        Test.stopTest();
        
        List<User> u=[select id from user where profile.name like 'GSS Professional Services%' and  email like '%akamai.com' and isactive=true limit 1];
        // Creating Account Team
        List<AccountTeamMember> accTeamInsert = new List<AccountTeamMember>();
        if(u.size() > 0){
            accTeamInsert.add(new AccountTeamMember(AccountId = accRec.Id, UserId = u[0].id,TeamMemberRole='Security Services - Primary'));
            insert accTeamInsert;
        }
        
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
        SC_SOCC_Situation_Catalog__c  SitCatRec = new SC_SOCC_Situation_Catalog__c (Handler_Type__c =HandTypeRec.id,Name='Kona DDoS DefenderAttack',Product__c	='Kona DDoS Defender',Situation_Class__c ='Attack',Handler_Type_picklist__c ='Phone Call Handler Type');
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
        
        authorized_contact__c authorizedcont = new authorized_contact__c(Policy_Domain__c =Policy.id, Contact_Name__c=lcont[0].id);
        insert authorizedcont;
        
        SC_SOCC_Escalation_Contact__c esccontact = new SC_SOCC_Escalation_Contact__c(Name='test',Escalation_List__c=esclistrec.id,Order_Number__c=1, Authorized_Contact__c=authorizedcont.id);
        insert esccontact;
        
        SC_SOCC_Escalation_via_Case_Email__c esccontactForEmail = new SC_SOCC_Escalation_via_Case_Email__c(Name='test',Escalation_List__c=esclistrec.id, Authorized_Contact__c=authorizedcont.id);
        insert esccontactForEmail;
        
        List<SC_SOCC_Availability__c> newRecords = new List<SC_SOCC_Availability__c>();
        SC_SOCC_Availability__c sc1 = new SC_SOCC_Availability__c();
        sc1.Day_Of_Week__c = 'Monday';
        sc1.Contact__c = lcont[0].id;
        sc1.Start_Time__c = Time.newInstance(2, 0, 0, 0);
        sc1.End_Time__c = Time.newInstance(4, 0, 0, 0);
        newRecords.add(sc1);
        
        SC_SOCC_Availability__c sc2 = new SC_SOCC_Availability__c();
        sc2.Day_Of_Week__c = 'Tuesday';
        sc2.Contact__c=lcont[0].id;
        sc2.Start_Time__c = Time.newInstance(2, 0, 0, 0);
        sc2.End_Time__c = Time.newInstance(4, 0, 0, 0);
        newRecords.add(sc2);
        
        SC_SOCC_Availability__c sc3 = new SC_SOCC_Availability__c();
        sc3.Day_Of_Week__c = 'Wednesday';
        sc3.Contact__c=lcont[0].id;
        sc3.Start_Time__c = Time.newInstance(00, 00, 0, 0);
        sc3.End_Time__c = Time.newInstance(23, 59, 0, 0);
        newRecords.add(sc3);
        
        SC_SOCC_Availability__c sc4 = new SC_SOCC_Availability__c();
        sc4.Day_Of_Week__c = 'Thursday';
        sc4.Contact__c=lcont[0].id;
        sc4.Start_Time__c = Time.newInstance(00, 00, 0, 0);
        sc4.End_Time__c = Time.newInstance(23, 59, 0, 0);
        newRecords.add(sc4);
        
        SC_SOCC_Availability__c sc5 = new SC_SOCC_Availability__c();
        sc5.Day_Of_Week__c = 'Friday';
        sc5.Contact__c=lcont[0].id;
        sc5.Start_Time__c = Time.newInstance(00, 00, 0, 0);
        sc5.End_Time__c = Time.newInstance(23, 59, 0, 0);
        newRecords.add(sc5);
        
        SC_SOCC_Availability__c sc6 = new SC_SOCC_Availability__c();
        sc6.Day_Of_Week__c = 'Saturday';
        sc6.Contact__c=lcont[0].id;
        sc6.Start_Time__c = Time.newInstance(4, 0, 0, 0);
        sc6.End_Time__c = Time.newInstance(8, 0, 0, 0);
        newRecords.add(sc6);
        
        SC_SOCC_Availability__c sc7 = new SC_SOCC_Availability__c();
        sc7.Day_Of_Week__c = 'Sunday';
        sc7.Contact__c=lcont[0].id;
        sc7.Start_Time__c = Time.newInstance(2, 0, 0, 0);
        sc7.End_Time__c = Time.newInstance(7, 0, 0, 0);
        newRecords.add(sc7);
        insert newRecords;
    }
    
    @isTest
    public static void Test_printCoverage()
    {
        Policy_Domain__c pd = [Select id from Policy_Domain__c limit 1];
        List<SC_SOCC_Situation_to_Handler_Mapping__c> shMapList = [Select id from SC_SOCC_Situation_to_Handler_Mapping__c where Policy_Domain__c =: pd.Id];
        String shMapIdList = ',';
        for(SC_SOCC_Situation_to_Handler_Mapping__c shMap: shMapList){
            shMapIdList += shMap.id+',';
        }
       
        Test.setCurrentPageReference(new PageReference('Page.SC_SOCC_PrintRunbook')); 
		System.currentPageReference().getParameters().put('id', pd.id);
        System.currentPageReference().getParameters().put('activeSections', shMapIdList);
        
        Apexpages.StandardController stdController = new Apexpages.StandardController(pd);
        SC_SOCC_RUNBOOK_Print_PDF controller = new SC_SOCC_RUNBOOK_Print_PDF(stdController);
        
        SC_SOCC_RUNBOOK_Print_PDF controllerNew = new SC_SOCC_RUNBOOK_Print_PDF();
        
    }
}