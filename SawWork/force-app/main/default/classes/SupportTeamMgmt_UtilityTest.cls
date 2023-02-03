@isTest(SeeAllData=true)
public class SupportTeamMgmt_UtilityTest{

     testmethod static void getTeamAccMapTest()
    {

        List<TS_TeamAccount__c> teamAccsList = new List<TS_TeamAccount__c>();
        Map<String, List<String>> teamAccMap = new Map<String, List<String>>();

        TS_TeamAccount__c teamAcc = new TS_TeamAccount__c();
        teamAcc.TS_Support_Team__c = 'aHnJ00000000014KAA'; teamAcc.Team_Account__c  = '001J000001W4mEkIAJ';
        teamAccsList.add(teamAcc);

        teamAcc = new TS_TeamAccount__c();
        teamAcc.TS_Support_Team__c = 'aHnJ00000000014KAA';teamAcc.Team_Account__c  = '001J000001c27FIIAY';
        teamAccsList.add(teamAcc);

        teamAcc = new TS_TeamAccount__c();
        teamAcc.TS_Support_Team__c = 'aHnJ0000000000VKAQ';teamAcc.Team_Account__c  = '001J000001c6UejIAE';
        teamAccsList.add(teamAcc);

        teamAcc = new TS_TeamAccount__c();
        teamAcc.TS_Support_Team__c = 'aHnJ0000000000QKAQ';teamAcc.Team_Account__c  = '001J000001c6UejIAE';
        teamAccsList.add(teamAcc);

        teamAcc = new TS_TeamAccount__c();
        teamAcc.TS_Support_Team__c = 'aHnJ0000000000QKAQ';teamAcc.Team_Account__c  = '001J000001cXqybIAC';
        teamAccsList.add(teamAcc);


        List<String> accIdList = new List<String>();

        accIdList.add('001J000001W4mEkIAJ');
        accIdList.add('001J000001c27FIIAY');
        teamAccMap.put('aHnJ00000000014KAA',accIdList);

        accIdList = new List<String>();
        accIdList.add('001J000001c6UejIAE');
        teamAccMap.put('aHnJ0000000000VKAQ', accIdList);

        accIdList = new List<String>();
        accIdList.add('001J000001c6UejIAE');
        accIdList.add('001J000001cXqybIAC');
        teamAccMap.put('aHnJ0000000000QKAQ', accIdList);
        Test.startTest();

        System.assertEquals(teamAccMap, SupportTeamMgmt_Utility.getTeamAccMap(teamAccsList));
        Test.stopTest();
    }

    testmethod static void getAccTeamMapTest(){
        List<TS_TeamAccount__c> teamAccsList = new List<TS_TeamAccount__c>();
        Map<String, List<String>> teamAccMap = new Map<String, List<String>>();
        String supportTeamId = '';
    String accountId = '';
    List<String> accIds = new List<String>();
    List<String> supportTeamIds = new List<String>();

    Test.startTest();
    User user = [select id, name, Owner_support_department__c from User where Owner_support_department__c = 'Technical Support' limit 1];
    Account acc =  new Account(Name = 'account test insert', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0');
    TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = 'test support team', Team_Type__c  = 'Premium Media');
    insert acc;
    insert supportTeam;    
    TS_TeamAccount__c teamAccObj = new TS_TeamAccount__c(Team_Account__c = acc.Id, TS_Support_Team__c = supportTeam.Id );
    insert teamAccObj;

    TS_TeamMember__c supportTeamMember = new TS_TeamMember__c(Team_Member__c  = user.Id, TS_Support_Team__c = supportTeam.Id, Role__c='Technical Support - Primary');    


        List<TS_TeamMember__c> teamMemberList = [select Id, TS_Support_Team__c from TS_TeamMember__c where TS_Support_Team__c = :supportTeam.Id];


    for(TS_TeamMember__c teamMember : teamMemberList){
        supportTeamIds.add(teamMember.Id);
    }

    List<TS_TeamAccount__c> teamAccs = [SELECT Team_Account__c,TS_Support_Team__c from TS_TeamAccount__c  where TS_Support_Team__c = :supportTeamIds];
    for( TS_TeamAccount__c teamAcc : teamAccs ){
        supportTeamId = teamAcc.TS_Support_Team__c;
        accountId = teamAcc.Team_Account__c;
        if(teamAccMap.get(supportTeamId)!=null){
            accIds = teamAccMap.get(supportTeamId);
            accIds.add(accountId);
            teamAccMap.put(supportTeamId, accIds);
        }
        else{
            accIds = new List<String>();
            accIds.add(accountId);
            teamAccMap.put(supportTeamId, accIds);
        }
    }   
        System.assertEquals(teamAccMap,SupportTeamMgmt_Utility.getAccTeamMap(teamMemberList));
        Test.stopTest();

    }
    testmethod static void getAccTeamMembersDelTest(){

        List<AccountTeamMember> accTeamMembersDelete = new List<AccountTeamMember>();

        Test.startTest();

        Account account = [select id from Account where name like 'Akamai Internal' Limit 1];
        List<AccountTeamMember> accTeamMembers = [select Id, AccountId, UserId, TeamMemberRole from AccountTeamMember where AccountId = :account.Id];
        List<String> accIds = new List<String>();
    for(AccountTeamMember accTeamMember : accTeamMembers){
        accIds.add(accTeamMember.AccountId);
    }
        List<AccountTeamMember> accTeamMembersAll = [select Id, AccountId, UserId, TeamMemberRole from AccountTeamMember where AccountId in :accIds];
        
    for(AccountTeamMember accTeamMember : accTeamMembersAll){
      for(AccountTeamMember accTeamMember1 : accTeamMembers){
          if((accTeamMember.AccountId==accTeamMember1.AccountId)&&
             (accTeamMember.UserId==accTeamMember1.UserId)&&
             (accTeamMember.TeamMemberRole==accTeamMember1.TeamMemberRole)){
                 accTeamMembersDelete.add(accTeamMember);
          }
      }            
    }
    System.assertEquals(accTeamMembersDelete,SupportTeamMgmt_Utility.getAccTeamMembersDel(accTeamMembers));
    }

  testmethod static void getAccTeamMembersTest(){
      List<String> accIdList = new List<String>();
        Map<String, List<String>> teamAccMap = new Map<String, List<String>>();
      List<TS_TeamMember__c> teamMemberList = new List<TS_TeamMember__c>();
      List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();

      accIdList = new List<String>();
      accIdList.add('001J000001c6UejIAE');
      teamAccMap.put('aHnJ0000000000VKAQ', accIdList);
      TS_TeamMember__c teamMember = new TS_TeamMember__c(TS_Support_Team__c = 'aHnJ0000000000VKAQ', Team_Member__c = '005J0000003RxxiIAC',
                                                        Role__c = 'Technical Support - Primary');
      teamMemberList.add(teamMember);
      
      AccountTeamMember accTeamMember = new AccountTeamMember(AccountId = '001J000001c6UejIAE' ,UserId = '005J0000003RxxiIAC', TeamMemberRole = 'Technical Support - Primary');

      accTeamMembers.add(accTeamMember);
      
      Test.startTest();
     System.assertEquals(accTeamMembers,SupportTeamMgmt_Utility.getAccTeamMembers(teamAccMap,teamMemberList));     
  }
    
    testmethod static void getAccTeamMembersTest1(){
      List<String> accIdList = new List<String>();
        Map<String, List<String>> teamAccMap = new Map<String, List<String>>();
      List<TS_TeamMember__c> teamMemberList = new List<TS_TeamMember__c>();
      List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();

      User user = [select id, name, Owner_support_department__c from User where Owner_support_department__c = 'Technical Support' limit 1];
      Account acc =  new Account(Name = 'account test insert', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0');
      TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = 'test support team', Team_Type__c  = 'Premium Media');
      insert acc;
      insert supportTeam;    
      TS_TeamAccount__c teamAccObj = new TS_TeamAccount__c(Team_Account__c = acc.Id, TS_Support_Team__c = supportTeam.Id );
      insert teamAccObj;

      TS_TeamMember__c supportTeamMember = new TS_TeamMember__c(Team_Member__c  = user.Id, TS_Support_Team__c = supportTeam.Id, Role__c='Technical Support - Primary');  

        accIdList = new List<String>();
        accIdList.add(acc.Id);
        teamAccMap.put(supportTeam.Id, accIdList);
        
      Test.startTest();    
      teamMemberList = [SELECT Id, Role__c, Team_Member__c,TS_Support_Team__c from TS_TeamMember__c where TS_Support_Team__c = :supportTeam.Id];

        for(TS_TeamMember__c teamMember : teamMemberList){
              
          for(String accId : teamAccMap.get(teamMember.TS_Support_Team__c)){
              AccountTeamMember accTeamMember = new AccountTeamMember();
              accTeamMember.AccountId = accId;
              accTeamMember.UserId = teamMember.Team_Member__c;
              accTeamMember.TeamMemberRole = teamMember.Role__c;
              accTeamMembers.add(accTeamMember);
          }
      }
              
       System.assertEquals(accTeamMembers,SupportTeamMgmt_Utility.getAccTeamMembers(teamAccMap)); 
       Test.stopTest();
    }
    testmethod static void getERCNumericTest(){
      Test.startTest();
      String AKERCValue = 'ADG1';
      String ERCNumericValue = '2341';
      System.assertEquals(SupportTeamMgmt_Utility.getERCNumeric(AKERCValue),ERCNumericValue);
      Test.stopTest();


    }
 

}