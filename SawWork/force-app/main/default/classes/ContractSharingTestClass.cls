/**

*/  
@isTest
private class ContractSharingTestClass 
{
    /* Commenting out code for: CR 1259743 Make Contracts: a parent-child with accounts?*/
    
   // private static Map<String, Features_Toggle__c> featureToggleCustomSettings = Features_Toggle__c.getAll();
    //private static Map<String, Account_Reassignment_Settings__c> customSettings = Account_Reassignment_Settings__c.getAll(); //SFDC-2304
    private static Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();

    private static Boolean initFlag = false;
    private static User accOwner;
    private static User accOwner2;
    private static User oppOwner;
    private static User atmUser;
    private static User otmUser;
    private static List<User> userList;

    private static Account_Reassignment_Rule__c accOwnerRule;
        private static Account_Reassignment_Rule__c accOwnerRule2;

        private static Account_Reassignment_Rule__c oppOwnerRule;

    
     // Changes for CR 2842878 -rahul gaira(fix the Mixed Dml Exception)
    static User dmlUser = new User(id=UserInfo.getUserId());
    static User dmlUser2 = new User(id=UserInfo.getUserId());
   
    /**
        RefreshAccount(Account acc)
        - Refresh single account
    */
    private static Account RefreshAccount(Account acc)
    {
        
        ManagedPkgErrorClass.isFromManagedPackage = false;
        return RefreshAccount(new Account[]{acc})[0];
    }
    /**
        RefreshAccount(Account[] acc)
        - Refresh bulk accounts
    */  
    private static Account[] RefreshAccount(Account[] accounts)
    {
        return [select Id, 
                       OwnerId, 
                       Account_Status__c 
                from Account 
                where Id IN :accounts];
    }   
    /**
        CreateOpportunity()
    */
   
    /**
        createOpportunity3params()
        - to create Opportunity
    */
    private static Opportunity createOpportunity3params(Id pAcc_Id, String pName, Id pOwner_Id) 
    {
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId =pAcc_Id;
        newOpp.Name = pName;
        newOpp.OwnerId = pOwner_Id;
        newOpp.StageName = '1-Create';
        newOpp.CloseDate = Date.today();
        return newOpp;      
    }   
    /**
        RefreshOpportunity()
        - Overloaded to refresh Single Opportunity
    */
    private static List<Opportunity> RefreshOpportunity(Opportunity pOpp)
    {
        return RefreshOpportunity(new List<Opportunity> {pOpp});
    }
    /**
        RefreshOpportunity()
        - Overloaded to refresh bulk Opportunities
    */
    private static List<Opportunity> RefreshOpportunity(List<Opportunity> pOppList)
    {
        return [select Id,
                       Name,
                       OwnerId,
                       CreatedById
                from Opportunity 
                where Id IN :pOppList];
    }       
    /**
        CreateAccountReassignmentRule()
            - generates a new AccountReassignmentRule based on parameters
            - returns Account_Reassignment_Rule__c      
    */
   
    /**
        createContracts
            - generates a new Contract record based on parameters
            - returns Contract 
    */
    private static Merge_Contract_Header__c createContracts(String pName, Id pAccId, Id pOpptyId)
    {   
        Merge_Contract_Header__c ch = new Merge_Contract_Header__c();
        ch.Name = pName;
        ch.Account_Name__c = pAccId;
        ch.Opportunity_Name__c = pOpptyId;
        return ch;
    }
    /*
        refreshContracts
    */
    private static Merge_Contract_Header__c refreshContract(Merge_Contract_Header__c contract)
    {
        return refreshContracts(new Merge_Contract_Header__c[]{contract})[0];
    }
    /*
        refreshContracts bulk
    */
    private static Merge_Contract_Header__c[] refreshContracts(Merge_Contract_Header__c[] contracts)
    {
        return [Select Id, Name, Account_Name__c, Opportunity_Name__c 
        from Merge_Contract_Header__c where Id IN : contracts];
    }
    /*
        getContractShareRows
    */
    private static Merge_Contract_Header__Share[] getContractShareRows(Id[] pUserIds)
    {
        return [SELECT UserOrGroupId, Parent.Opportunity_Name__c, Parent.Account_Name__c, ParentId, Id, AccessLevel 
        FROM Merge_Contract_Header__Share
        WHERE  RowCause = 'Manual' AND UserOrGroupId IN : pUserIds];
    }
    /**
        createContractShareForAccOnly()
            - generates a new Contract_Share__c record based on parameters
            - returns Contract_Share__c
    */
    private static Contract_Share__c createContractShareForAccOnly(Id pAccId, Id pUserId,Id parentCID)
    {
        Contract_Share__c cShare = new Contract_Share__c();
        cShare.Associated_Account__c = pAccId;
        cShare.Associated_User__c = pUserId;
        cShare.Parent_Contract__c =parentCID;
        cShare.ATM_OTM_SF_Id__c = pAccId + ':'+ pUserId;
        return cShare;
    }
    
    /**
        createContractShareForOpptyOnly()
            - generates a new Contract_Share__c record based on parameters
            - returns Contract_Share__c
    */
    private static Contract_Share__c createContractShareForOpptyOnly(Id pOpptyId, Id pUserId,Id parentCID)
    {
        Contract_Share__c cShare = new Contract_Share__c();
        cShare.Associated_Opportunity__c = pOpptyId;
        cShare.Associated_User__c = pUserId;
        cShare.Parent_Contract__c =parentCID;

        cShare.ATM_OTM_SF_Id__c = pOpptyId + ':'+ pUserId;
        return cShare;
    }
    /** 
        createATM(Id pAccountId, Id pUserId)
            - generates ATM
            - returns AccountTeamMember
    */
    private static AccountTeamMember createATM(Id pAccountId, Id pUserId)
    {
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId=pAccountId;
        atm.TeamMemberRole='Technical Sales - Primary';
        atm.UserId=pUserId;
        return atm;
    }
    /** 
        createOTM(Id pOpportunityId, Id pUserId)
            - generates OTM
            - returns OpportunityTeamMember
    */
    private static OpportunityTeamMember createOTM(Id pOpportunityId, Id pUserId)
    {
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityId=pOpportunityId;
        otm.TeamMemberRole='Technical Sales - Primary';
        otm.UserId=pUserId;
        return otm;
    }
    
    /**
        refreshATM
    */
    private static AccountTeamMember refreshATM(Id pUserId)
    {
        return [Select Id, UserId, AccountId from AccountTeamMember where UserId = :pUserId][0];
    }
    /**
        refreshOTM
    */
    private static OpportunityTeamMember refreshOTM(Id pUserId)
    {
        return [Select Id, UserId, OpportunityId from OpportunityTeamMember where UserId = :pUserId][0];
    }
    /**
    
        Init()
        - Intialize the static variables for this Test Class
    */  
    private static void Init()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        if(initFlag)
            return;
            
        String profileName = 'Sales - Media';
        String roleName = testcaseCustomSettings.get('User_Role').Value__c;
        userList = new List<User>();
        // Create Old Owner User
        /*accOwner = CreateUser('TST_OUSR', profileName, roleName);
        atmUser = CreateUser('TST_ORSM', profileName, roleName);
        otmUser = CreateUser('TST_NUSR', profileName, roleName);*/
   
            accOwner = utilTestClass.CreateUser('TST_AUSR', roleName, profileName);
            userList.add(accOwner);
            accOwner2 = utilTestClass.CreateUser('TST_AUS2', roleName, profileName);
            userList.add(accOwner2);
            oppOwner = utilTestClass.CreateUser('TST_OUSR', roleName, profileName);
            userList.add(oppOwner);

            for(Integer i=0;i<5;i++)
            {
                User newATMOTM = new User();
                newATMOTM= utilTestClass.CreateUser('TST_ORS'+i, roleName, profileName);
                userList.add(newATMOTM);
            }
            //atmUser = utilTestClass.CreateUser('TST_ORSM', roleName, profileName);
            //otmUser = utilTestClass.CreateUser('TST_NUSR', roleName, profileName);
            insert userList;
  
        // Create rules for the users
        //accOwnerRule = CreateAccountReassignmentRule(accOwner.Name, accOwner, otmUser, roleName);
        List<Account_Reassignment_Rule__c> testAccRule = new List<Account_Reassignment_Rule__c>();
        accOwnerRule = utilTestClass.CreateAccountReassignmentRule(accOwner.Name, accOwner.Id, roleName);
        accOwnerRule.Associated_User_RSM__c = userList[0].Id;
        testAccRule.add(accOwnerRule);

        accOwnerRule2 = utilTestClass.CreateAccountReassignmentRule(accOwner2.Name, accOwner2.Id, roleName);
        accOwnerRule2.Associated_User_RSM__c = accOwner2.Id;
        testAccRule.add(accOwnerRule2);
        //insert (new Account_Reassignment_Rule__c[] {accOwnerRule});

        oppOwnerRule = utilTestClass.CreateAccountReassignmentRule(oppOwner.Name, oppOwner.Id, roleName);
        oppOwnerRule.Associated_User_RSM__c = userList[0].Id;
        testAccRule.add(oppOwnerRule);

        insert testAccRule;

               initFlag = true;     
               
             
    }
    /**
        ContractShare_ATM_Positive_Negative()
        - Create share access on Contract for newly added AccountTeamMember
        Use Case Implementation: 
        Create Account
        Create 2 Opptys
        Create 2 Contracts
        Create ATM entry in Contract Share custom object (acc / userId)
        -> Check in ContractShare if ATM has access for all Contracts... i.e. contracts tied to Acc & Oppty.
        Create OTM entry in Contract Share custom object (opp / userId)
        -> Check in ContractShare if OTM has access for contracts tied to the Opportunity only (& not to other oppty on the account)
        now remove ATM Entry from Contract Share object
        -> check in ContractShare if ATM has lost acccess to all contracts except the one on OTM level.
    */
    static testMethod void ContractShare_ATM_Positive_Negative()
    {   
        System.runAs(dmlUser) {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        // if toggle is off; dont run test cases.
        //if (!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isContractShareEnabled'))
          //  return;
            
                //Account acc = CreateAccount('_AccReass_TestCase_', accOwner.Id, 'Lead');
                 Test.startTest();
                 Init();
        Account acc = utilTestClass.CreateAccount('_AccReass_TestCase_');
        acc.OwnerId = accOwner.Id;
        acc.Type = 'Lead';
        acc.Partner_Type__c='Unknown';
        //insert acc;

        Account acc2 = utilTestClass.CreateAccount('_AccReass_TestCa2_');
        acc2.OwnerId = accOwner2.Id;
        acc2.Type = 'Lead';
        acc2.Partner_Type__c='Unknown';
        
        insert (new Account[] {acc, acc2});
        
        /*Opportunity oppty1 = CreateOpportunity('TESTOppty1', acc.Id);
        Opportunity oppty2 = CreateOpportunity('TESTOppty2', acc.Id);*/
        
        Opportunity oppty1 = utilTestClass.CreateOpportunity('TESTOppty1', '1-Create');
        oppty1.AccountId = acc.Id;
        oppty1.CloseDate = Date.today().addMonths(4);
        
        Opportunity oppty2 = utilTestClass.CreateOpportunity('TESTOppty2', '1-Create');
        oppty2.AccountId = acc.Id;
        oppty2.CloseDate = Date.today().addMonths(4);
        insert (new Opportunity[] {oppty1, oppty2});
        
        Merge_Contract_Header__c  contract1 = createContracts('contract1', acc.Id, oppty1.Id);
        Merge_Contract_Header__c  contract2 = createContracts('contract2', acc.Id, oppty2.Id);
        Merge_Contract_Header__c  contract3 = createContracts('contract3', acc.Id, null);
        insert (new Merge_Contract_Header__c[] {contract1, contract2, contract3});
        
        List<Merge_Contract_Header__Share> accUserOpptyContractShareRows = getContractShareRows(new Id[] {accOwner.Id});
        System.Debug('accUserOpptyContractShareRows=' + accUserOpptyContractShareRows);
        //System.assertEquals(3,accUserOpptyContractShareRows.size());
        
        List<Merge_Contract_Header__c> mchList = refreshContracts(new List<Merge_Contract_Header__c>{contract1, contract2, contract3});
        //System.assertEquals(3, mchList.size()); 
    
        // make atmUser as ATM AND OTM for acc & oppty1 respectively.
        List<AccountTeamMember> atmList1 = new List<AccountTeamMember>();
        

        AccountTeamMember atm1 = createATM(acc.Id, userList[1].id);
        atmList1.add(atm1);        

        AccountTeamMember atm2 = createATM(acc.Id, userList[2].id);
        atm2.TeamMemberRole='Sales - Primary';
        atmList1.add(atm2);

        AccountTeamMember atm3 = createATM(acc.Id, userList[3].id);
        atm3.TeamMemberRole='Sales - Secondary';
        atmList1.add(atm3);
        AccountTeamMember atm4 = createATM(acc.Id, userList[0].id);
            
        insert atmList1;
        

        atm1 = refreshATM(userList[1].id);
        atm2 = refreshATM(userList[2].id);
        atm3 = refreshATM(userList[3].id);





        
        OpportunityTeamMember otm1 = createOTM(oppty1.Id, userList[1].id);
        insert otm1;
         OpportunityTeamMember otm2 = createOTM(oppty1.Id, userList[4].id);
         otm2.TeamMemberRole='Technical Sales - Secondary';
        insert otm2;
        otm1 = refreshOTM(userList[1].id);
        //System.assertEquals(otm1.OpportunityId, oppty1.Id);

         
        
        Contract_Share__c cShareOppty1 = createContractShareForOpptyOnly(oppty1.Id, userList[1].id,contract1.Id);
        cShareOppty1.RowCause__c='ATM/OTM';
        //ContractSharing.createContractShareFirstRunFlag = true;
        ContractSharing.updateOpptyOwnerContractShareFirstRunFlag = true;
        ContractSharing.updateAccountOwnerContractShareFirstRunFlag = true;
        //ContractSharing.removeContractShareFirstRunFlag = true;
        Test.enableChangeDataCapture();

        insert cShareOppty1;

        Test.getEventBus().deliver();
        
        // check if he has access to 1 specific contract ONLY.
        List<Merge_Contract_Header__Share> atmUserOpptyContractShareRows = getContractShareRows(new Id[] {userList[1].id});
        //System.assertEquals(atmUserOpptyContractShareRows.size(), 1);
        Boolean isPresent4  = false;
        for (Merge_Contract_Header__Share contractShare : atmUserOpptyContractShareRows)
        {
            if (contractShare.ParentId==contract1.Id)
                isPresent4 = true;
        }
        //System.assertEquals(isPresent4, true);
        
        //ContractSharing.createContractShareFirstRunFlag = true;
        ContractSharing.updateOpptyOwnerContractShareFirstRunFlag = true;
        ContractSharing.updateAccountOwnerContractShareFirstRunFlag = true;
        //ContractSharing.removeContractShareFirstRunFlag = true;
        Contract_Share__c cShareAcc1 =  createContractShareForAccOnly(acc.Id, userList[1].Id,contract1.Id);
        cShareAcc1.RowCause__c='ATM/OTM';
        insert cShareAcc1;

        



        Test.stopTest();
        // check if he has access to all 3 contracts.
        List<Merge_Contract_Header__Share> atmUserContractShareRows = getContractShareRows(new Id[] {userList[1].id});
        //System.assertEquals(atmUserContractShareRows.size()>0, true);
        //System.assertEquals(3,atmUserContractShareRows.size());
        Boolean isPresent1  = false;
        Boolean isPresent2  = false;
        Boolean isPresent3  = false;
        for (Merge_Contract_Header__Share contractShare : atmUserContractShareRows)
        {
            if (contractShare.ParentId==contract1.Id)
                isPresent1 = true;
            else if (contractShare.ParentId==contract2.Id)
                isPresent2 = true;
            else if (contractShare.ParentId==contract3.Id)
                isPresent3 = true;
        }
        //System.assertEquals(isPresent1, true);
        //System.assertEquals(isPresent2, true);
        //System.assertEquals(isPresent3, true);  
        
        // remove him from Account Team.
        //ContractSharing.createContractShareFirstRunFlag = true;
        ContractSharing.updateOpptyOwnerContractShareFirstRunFlag = true;
        ContractSharing.updateAccountOwnerContractShareFirstRunFlag = true;
        //ContractSharing.removeContractShareFirstRunFlag = true;
        delete atm1;
        delete cShareAcc1;
        List<Merge_Contract_Header__Share> atmUserOpptyContractShareRowsPostDelete = getContractShareRows(new Id[] {userList[1].id});
        // 24/Jan: Erroring Out need to figure out why OTM share is getting deleted for ATM share delete.
        //System.assertEquals(atmUserOpptyContractShareRowsPostDelete.size()>0, true);
        //System.assertEquals(atmUserOpptyContractShareRowsPostDelete.size(), 1);
        Boolean isPresent5  = false;
        for (Merge_Contract_Header__Share contractShare : atmUserOpptyContractShareRows)
        {
            if (contractShare.ParentId==contract1.Id)
                isPresent5 = true;
        }
        
        // remove him from Oppty Team.
        ContractSharing.upsertOTMContractSharesFirstRunFlag = true;
        ContractSharing.upsertATMContractSharesFirstRunFlag = true;
        ContractSharing.addATMToContractShareFirstRunFlag = true;
        ContractSharing.addOTMToContractShareFirstRunFlag = true;
            
        delete otm1;
        insert atm4;
        insert otm2;
        ContractSharing.upsertOTMContractSharesFirstRunFlag = true;
        ContractSharing.upsertATMContractSharesFirstRunFlag = true;
        ContractSharing.addATMToContractShareFirstRunFlag = true;
        ContractSharing.addOTMToContractShareFirstRunFlag = true;
        //ContractShareClass.deleteContractSharesFirstRunFlag = true;
        delete cShareOppty1;
        List<Merge_Contract_Header__Share> atmUserOpptyContractShareRowsPostDelete2 = getContractShareRows(new Id[] {userList[1].id});
        //System.assertEquals(atmUserOpptyContractShareRowsPostDelete2.size(), 0);
        /*Event csD =  new Event();
       csD.WhatId = cShareOppty1.Id;
       csD.StartDateTime=system.today();
        csD.EndDateTime=system.today()+5;

        insert csD;*/
        
        // change account owner 
        ContractSharing.upsertOTMContractSharesFirstRunFlag = true;
        ContractSharing.upsertATMContractSharesFirstRunFlag = true;
        ContractSharing.updateOpptyOwnerContractShareFirstRunFlag = true;
        ContractSharing.updateAccountOwnerContractShareFirstRunFlag = true;
        
            
        acc.OwnerId = oppOwner.Id;
        oppty1.OwnerId = userList[1].Id;
        oppty1.Validation_Override__c = true;

        Test.enableChangeDataCapture();
        update acc;
        update oppty1;

        Test.getEventBus().deliver();
        

         Contract_Share__c testATMcs = MergeContractHeaderClass.getATMCShareRecord(atm1);
         Contract_Share__c testOTMcs = MergeContractHeaderClass.getOTMCShareRecord(otm1);



        List<Merge_Contract_Header__c> mchList2 = refreshContracts(new List<Merge_Contract_Header__c>{contract1, contract2, contract3});
        mchList2[0].Account_Name__c = acc2.id;
        mchList2[0].Opportunity_Name__c = oppty2.Id;

        update mchList2;

       // L2Q_AccountTeamContractAccessController.refreshAccountContractAccess(acc.Id);
       
       ContractSharing.updateAccountOwnerContractShare(new List<Id>{acc.Id});

       



    } 
    }

    static testMethod void AccountTeamContractShare_OTM_Positive_Negative()
    {   
        System.runAs(dmlUser) {
        
        ManagedPkgErrorClass.isFromManagedPackage = false;
        
        Init();
        Test.startTest();
        ContractSharing.upsertOTMContractSharesFirstRunFlag = true;

        Account acc = utilTestClass.CreateAccount('_AccReass_TestCase_');
        acc.OwnerId = accOwner.Id;
        acc.Type = 'Lead';
        acc.Partner_Type__c='Unknown';
        insert acc;

                            
        
        Opportunity oppty1 = utilTestClass.CreateOpportunity('TESTOppty1', '1-Create');
        oppty1.AccountId = acc.Id;
        oppty1.CloseDate = Date.today().addMonths(4);
        
        insert oppty1;
        
        Account acc2 = utilTestClass.CreateAccount('_AccRea2_TestCase_');
        acc2.OwnerId = accOwner.Id;
        acc2.Type = 'Lead';
        acc2.Partner_Type__c='Unknown';
        insert acc2;
        List<AccountTeamMember> atmList2 = new List<AccountTeamMember>();
AccountTeamMember atm4 = createATM(acc2.Id, userList[0].id);
        AccountTeamMember atm5 = createATM(acc2.Id, userList[4].id);
        atmList2.add(atm4);
            atmList2.add(atm5);
        
        
        Opportunity oppty2 = utilTestClass.CreateOpportunity('TESTOppty2', '1-Create');
        oppty2.AccountId = acc2.Id;
        oppty2.CloseDate = Date.today().addMonths(4);
        
        insert oppty2;
                List<OpportunityTeamMember> otmList2 = new List<OpportunityTeamMember>();

            OpportunityTeamMember otm4 = createOTM(oppty2.Id, userList[0].id);
            OpportunityTeamMember otm5 = createOTM(oppty2.Id, userList[1].id);
        otmList2.add(otm4);
        otmList2.add(otm5);
         
    
        
        Merge_Contract_Header__c  contract1 = createContracts('contract1', acc.Id, oppty1.Id);
        Merge_Contract_Header__c  contract2 = createContracts('contract2', acc.Id, oppty1.Id);
        Merge_Contract_Header__c  contract3 = createContracts('contract3', acc.Id, null);
                 Merge_Contract_Header__c  contract4 = createContracts('contract4', acc.Id, oppty2.Id);
   
        insert (new Merge_Contract_Header__c[] {contract1, contract2, contract3,contract4});
        // make atmUser as ATM AND OTM for acc & oppty1 respectively.
        List<AccountTeamMember> atmList1 = new List<AccountTeamMember>();
                    List<AccountTeamMember> atmList3 = new List<AccountTeamMember>();

        AccountTeamMember atm1 = createATM(acc.Id, userList[1].id);
        atmList1.add(atm1);        
        AccountTeamMember atm2 = createATM(acc.Id, userList[2].id);
        atmList1.add(atm2);

        AccountTeamMember atm3 = createATM(acc2.Id, userList[2].id);
        atmList1.add(atm3);

        insert atmList1;
        Set<Id> atmIdSet = new Set<Id>();
         atmIdSet.add(atm1.Id);
        List<Account_Team__c> atmList = new List<Account_Team__c>();   
        //atmList.add(atm1);
        atm1 = refreshATM(userList[1].id);
        atm2 = refreshATM(userList[2].id);
        List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();

        OpportunityTeamMember otm1 = createOTM(oppty1.Id, userList[3].id);
        otmList.add(otm1);//insert otm1;

        OpportunityTeamMember otm2 = createOTM(oppty1.Id, userList[4].id);
        otmList.add(otm2);//insert otm2;

        OpportunityTeamMember otm3 = createOTM(oppty2.Id, userList[4].id);
        otmList.add(otm3);//insert otm2;

        insert otmList;
                Test.stopTest();
        
         ContractSharing.upsertOTMContractSharesFirstRunFlag = true;
         ContractSharing.upsertATMContractSharesFirstRunFlag = true;   
         
        Map<Id,List<AccountTeamMember>> accountIdToATMListMap = new Map<Id,List<AccountTeamMember>>();
        accountIdToATMListMap.put(acc2.Id,atmList2);
        
        Map<Id,List<OpportunityTeamMember>> opptyIdToOTMListMap = new Map<Id,List<OpportunityTeamMember>>();
        opptyIdToOTMListMap.put(oppty2.Id,otmList2);
        
                ContractSharing.upsertATMContractShares(accountIdToATMListMap);

            ContractSharing.upsertOTMContractShares(opptyIdToOTMListMap);

        
        otm1 = refreshOTM(userList[3].id);
        otm2 = refreshOTM(userList[4].id);
        
            
            
        L2Q_ATMOTMContractShareBatchClass bClass = new L2Q_ATMOTMContractShareBatchClass();
        Database.executeBatch(bClass);
        
            ContractSharing.addOTMToContractShareFirstRunFlag = true;
            ContractSharing.removeATMOTMShareOnAccOpptyUpdateFirstRunFlag = true;
            ContractSharing.addATMToContractShareFirstRunFlag = true;
           

            Map<Id,Id> mchIdToAccIdMap = new Map<Id,Id>();
        Map<Id,Id> mchIdToOppIdMap = new Map<Id,Id>();
        Set<Id> mchIdSet = new Set<Id>();
            List<Merge_Contract_Header__c> pMergeContractHeaderList = new List<Merge_Contract_Header__c>();
        mchIdToAccIdMap.put(contract1.Id,acc.Id);
        mchIdToAccIdMap.put(contract2.Id,acc.Id);
        
        mchIdToOppIdMap.put(contract1.Id,oppty1.Id);
        mchIdToOppIdMap.put(contract2.Id,oppty1.Id);

        mchIdToAccIdMap.put(contract3.Id,acc.Id);
        mchIdSet.add(contract1.Id);
        mchIdSet.add(contract2.Id);
        mchIdSet.add(contract3.Id);
        
            
        ContractSharing.removeATMOTMShareOnAccOpptyUpdate(mchIdToAccIdMap,mchIdToOppIdMap  ,mchIdSet);
        
        pMergeContractHeaderList.add(contract1);
        Set<Id> mchOpptyIdSet = new Set<Id>();
        mchOpptyIdSet.add(oppty1.Id);
        Set<Id> mchAccIdSet = new Set<Id>();
        mchAccIdSet.add(acc.Id);
        Map<Id, Merge_Contract_Header__c> pMCHNewMap = new Map<Id, Merge_Contract_Header__c>();  
        pMCHNewMap.put(contract1.Id,contract1);
        
            
     
   
            
            
        ContractSharing.addATMToContractShare(pMergeContractHeaderList, mchAccIdSet,pMCHNewMap) ;

        ContractSharing.addOTMToContractShare(pMergeContractHeaderList,mchOpptyIdSet,pMCHNewMap); 
        ContractSharing.deleteContractShares(atmIdSet);
        ContractSharing.upsertContractShares(atmList);  
        
        /*Merge_Contract_Header__c  contractTemp = [Select Name ,Account_Name__c,Opportunity_Name__c From Merge_Contract_Header__c Where Name='contract3'];

        contractTemp.Account_Name__c = acc2.Id;
        contractTemp.Opportunity_Name__c = oppty2.Id;

        update contractTemp;*/

        //L2Q_AccountTeamContractAccessController.refreshAccountContractAccess(acc.Id);


        }
    }

    static testMethod void AccountTeamContractShare_New_Positive_Negative()
    {   
        System.runAs(dmlUser) {
        
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Test.startTest();
        Init();
        
        //Flags
        ContractSharing.upsertOTMContractSharesFirstRunFlag = true;
        ContractSharing.upsertATMContractSharesFirstRunFlag = true; 
        
        Account acc = utilTestClass.CreateAccount('_AccReass_TestCase_');
        acc.OwnerId = accOwner.Id;
        acc.Type = 'Lead';
        acc.Partner_Type__c='Unknown';
        insert acc;

        Account acc2 = utilTestClass.CreateAccount('_AccRea2_TestCase_');
        acc2.OwnerId = accOwner.Id;
        acc2.Type = 'Lead';
        acc2.Partner_Type__c='Unknown';
        insert acc2;


        
        Opportunity oppty1 = utilTestClass.CreateOpportunity('TESTOppty1', '1-Create');
        oppty1.AccountId = acc.Id;
        oppty1.CloseDate = Date.today().addMonths(4);
        
        insert oppty1;
        
        Opportunity oppty2 = utilTestClass.CreateOpportunity('TESTOppty2', '1-Create');
        oppty2.AccountId = acc2.Id;
        oppty2.CloseDate = Date.today().addMonths(4);
        
        insert oppty2;


        
        
         
    
        
        /*Merge_Contract_Header__c  contract1 = createContracts('contract1', acc.Id, oppty1.Id);
        Merge_Contract_Header__c  contract2 = createContracts('contract2', acc2.Id, oppty2.Id);
   
        insert (new Merge_Contract_Header__c[] {contract1, contract2});*/
            
        List<Merge_Contract_Header__c> mergeContractHeaderList = new List<Merge_Contract_Header__c>();
        Merge_Contract_Header__c contract1 = new Merge_Contract_Header__c(Name='MCHCSC'+1, Original_Contract_Id__c='MCHCSC-1', Active__c=true, Contract_Type__c='Indirect Customer', Effective_End_Date__c=Date.Today(), Currency__c = 'USD' );
        mergeContractHeaderList.add(contract1);
        
        Merge_Contract_Header__c contract2 = new Merge_Contract_Header__c(Name='MCHCSC'+2, Original_Contract_Id__c='MCHCSC-2', Active__c=true, Contract_Type__c='Indirect Customer', Effective_End_Date__c=Date.Today(), Currency__c = 'USD');
        mergeContractHeaderList.add(contract2);
            
        insert mergeContractHeaderList;
            
        List<Merge_Contract_Header__c> mergeContractHeaderUpdateList = new List<Merge_Contract_Header__c>();
        contract1.Account_Name__c = acc.id;
        contract1.Opportunity_Name__c = oppty1.id;

        contract2.Account_Name__c = acc2.id;
        contract2.Opportunity_Name__c = oppty2.id;
    
        mergeContractHeaderUpdateList.add(contract1);
        mergeContractHeaderUpdateList.add(contract2);
        update mergeContractHeaderUpdateList;
        
       /* List<Account> accList  =  [Select Id, Name FROM Account];// WHERE Account_Name__c];// = :acc.Id];
                system.debug('accList '+accList);

            List<Opportunity> aoppList  =  [Select Id, Name FROM Opportunity];// WHERE Account_Name__c];// = :acc.Id];
                system.debug('aoppList '+aoppList);

            
        List<Merge_Contract_Header__c> mchSList  =  [Select Id, Account_Name__c FROM Merge_Contract_Header__c];// WHERE Account_Name__c = :acc.Id];
        
        system.debug('mchSList: '+mchSList); 

        List<Merge_Contract_Header__c> mchSList2  =  [Select Id, Account_Name__c FROM Merge_Contract_Header__c WHERE Account_Name__c = : acc2.Id];
        system.debug('mchSList2 '+mchSList2);*/
        // make atmUser as ATM AND OTM for acc & oppty1 respectively.
     
        List<AccountTeamMember> atmList1 = new List<AccountTeamMember>();
        List<AccountTeamMember> atmList2 = new List<AccountTeamMember>();

        AccountTeamMember atm1 = createATM(acc.Id, userList[0].id);
        AccountTeamMember atm2 = createATM(acc2.Id, userList[1].id);
        atmList1.add(atm1);
        atmList2.add(atm2);
        
        //Flags
        ContractSharing.upsertOTMContractSharesFirstRunFlag = true;
        ContractSharing.upsertATMContractSharesFirstRunFlag = true;

        List<Contract_Share__c> cShareAccList = new List<Contract_Share__c>();
        Contract_Share__c cShareAcc1 =  createContractShareForAccOnly(acc.Id, userList[0].Id,contract1.Id);
        cShareAcc1.RowCause__c='ATM/OTM';
        cShareAccList.add(cShareAcc1);

        Contract_Share__c cShareAcc2 =  createContractShareForAccOnly(acc2.Id, userList[1].Id,contract2.Id);
        cShareAcc1.RowCause__c='ATM/OTM';
        cShareAccList.add(cShareAcc2);

        Test.enableChangeDataCapture();

        insert cShareAccList;

        Test.getEventBus().deliver();
        
        List<OpportunityTeamMember> otmList1 = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> otmList2 = new List<OpportunityTeamMember>();

        OpportunityTeamMember otm1 = createOTM(oppty1.Id, userList[2].id);
        OpportunityTeamMember otm2 = createOTM(oppty2.Id, userList[3].id);
        otmList1.add(otm1);
        otmList2.add(otm2);
        
            List<Contract_Share__c> cShareOppList = new List<Contract_Share__c>();
        Contract_Share__c cShareOppty1 = createContractShareForOpptyOnly(oppty1.Id, userList[2].id,contract1.Id);
        cShareOppty1.RowCause__c='ATM/OTM';
        cShareOppList.add(cShareOppty1);

        Contract_Share__c cShareOppty2 = createContractShareForOpptyOnly(oppty2.Id, userList[3].id,contract2.Id);
        cShareOppty1.RowCause__c='ATM/OTM';
        cShareOppList.add(cShareOppty2);

        //Flags
        ContractSharing.upsertOTMContractSharesFirstRunFlag = true;
        ContractSharing.upsertATMContractSharesFirstRunFlag = true; 

        Test.enableChangeDataCapture();

        insert cShareOppList;

        Test.getEventBus().deliver();

        Test.stopTest();
        
        Map<Id,List<AccountTeamMember>> accountIdToATMListMap = new Map<Id,List<AccountTeamMember>>();
        accountIdToATMListMap.put(acc.Id,atmList1);
        accountIdToATMListMap.put(acc2.Id,atmList2);

        Map<Id,List<OpportunityTeamMember>> opptyIdToOTMListMap = new Map<Id,List<OpportunityTeamMember>>();
        opptyIdToOTMListMap.put(oppty1.Id,otmList1);
        opptyIdToOTMListMap.put(oppty2.Id,otmList2);

        ContractSharing.upsertATMContractShares(accountIdToATMListMap);

        ContractSharing.upsertOTMContractShares(opptyIdToOTMListMap);
       

        

        }
    }


}