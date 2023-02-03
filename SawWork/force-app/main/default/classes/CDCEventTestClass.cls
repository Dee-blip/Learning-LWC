@isTest(seeAllData=false)
public class CDCEventTestClass {
    static testmethod void insertCDCEvents() {
        Test.enableChangeDataCapture();
       	Account newAcc = utilTestClass.CreateAccount('TestAccountPrabCDCChangeEvent');
        newAcc.Vertical__c = 'Public Sector';
        newAcc.type='Lead';
        newAcc.Website = 'www.abcdcdcchangeevent.com';
        newacc.Parent_Division__c ='Web Americas_Web';
        insert newAcc;
        Test.getEventBus().deliver();

        
        
        Contact tCon = utilTestClass.CreateContact('_TestCDC', 'LASTest');
        tCon.AccountId = newAcc.Id;
        tCon.MailingCountry = 'USA';
        tCon.Network_Contact__c = false;
        tCon.Email = 'teestclasscdc@akamai.com';
        insert tCon;
        
        Test.getEventBus().deliver();

        
        AccountTeamMember atm= new AccountTeamMember();
        atm.AccountId=newAcc.id;
        atm.TeamMemberRole='Technical Sales - Primary';
        atm.UserId=UserInfo.getUserId();
        insert atm;
        
        Test.getEventBus().deliver();

        
        newAcc.Website = 'www.newabcdcdcchangeevent.com';
        update newAcc;
        
        Test.getEventBus().deliver();

        
        tCon.Email = 'teestclasscdc123@akamai.com';
        update tCon;
        
        Test.getEventBus().deliver();

        delete atm;
    }
}