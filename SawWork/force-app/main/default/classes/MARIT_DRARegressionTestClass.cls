@isTest(seeAllData = false)
public class MARIT_DRARegressionTestClass {

	public static User dmlUser = utilTestClass.getTestRunUser();
    
    private static DRASubprocessConfig__c getDRAInstance(String vertical, String subVertical, String country, String state, Id sdr, Id projectedSDR, Boolean excludeCheck){
       
        DRASubprocessConfig__c dra = new DRASubprocessConfig__c();
        dra.Vertical__c = vertical;
        dra.Country__c = country;
        dra.Sub_Vertical__c = subVertical;
        dra.Region_or_State__c = state;
        dra.SDR_Name__c = sdr;
        dra.Projected_SDR__c = projectedSDR; 
        dra.Exclude_from_Projected_Sales_Mapping__c = excludeCheck;
        return dra;
    }
    
    private static Account_Reassignment_Rule__c getAccReassignInstance(Id userId, String name, String userRole){
       
        Account_Reassignment_Rule__c rule = new Account_Reassignment_Rule__c();
        rule.Associated_User__c = userId;
        rule.Name = name;
        rule.User_Role__c = userRole;
        return rule;
    }
    
    private static Account getAccInstance(String name, String webSite, String vertical, String subVertical, String country, String state, Id userId){
       
        Account acc = new Account();
        acc.Name = name;
        acc.Website = webSite;
        acc.Vertical__c =  vertical;
        acc.Sub_Vertical__c = subVertical;
        acc.BillingCountry = country;
        acc.BillingState = state;
        acc.OwnerId = userId;
        acc.Projected_Sales_Owner__c = null;
        acc.Projected_SDR__c = null;
        return acc;
    }
    
    private static User createUser(String pUsrAlias, Id profileId, Id roleId){
        User newUser = new User(alias = pUsrAlias,
                                email=pUsrAlias+'@akamai.com',
                                emailencodingkey='UTF-8',
                                lastname=pUsrAlias,
                                languagelocalekey='en_US',
                                localesidkey='en_US',
                                timezonesidkey='America/Los_Angeles',
                                username=pUsrAlias+'@akamai.com.tclass',
                                profileid = profileId,
                                UserRoleId = roleId );
        return newUser;
    }
	
    @testSetUp static void insertCustomSettingsAndCreateData(){
        System.runAs(dmlUser){
            //User Creation
            Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
            String roleName = GsmUtilClass.getGSMSettingValue('User_Role');
            Id roleId = [select Id from UserRole where name=:roleName][0].Id;
            List<User> userList = new List<User>();
            User usr = CreateUser('User1',salesRepProfileId,roleId);
            userList.add(usr);
            usr = CreateUser('User2',salesRepProfileId,roleId);
            userList.add(usr);
            usr = CreateUser('User3',salesRepProfileId,roleId);
            userList.add(usr);
            Id ownerId1 = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
            Id ownerId2 = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(1);
            Id ownerId3 = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(2);
    
            insert userList;
            
            //DRA Record creation
            List<DRASubprocessConfig__c> draList = new List<DRASubprocessConfig__c>();
            
            DRASubprocessConfig__c dra = getDRAInstance('Commerce', 'Manufacturing', 'India', 'Delhi', userList[0].id, userList[0].id, false);
            draList.add(dra);
            
            dra = getDRAInstance('Akamai Internal', 'Akamai Internal', 'India', 'Rajasthan', userList[1].id, userList[1].id, false);
            draList.add(dra);
            
            dra = getDRAInstance('Gambling', 'Gambling Operators', 'India', 'Goa', userList[2].id, userList[2].id, false);
            draList.add(dra);
    
            insert draList;
            
            List<Account_Reassignment_Rule__c> ruleList = new List<Account_Reassignment_Rule__c>();

            //use metadata for user role
            Account_Reassignment_Rule__c rule = getAccReassignInstance(userList[0].Id, 'TestRulePAO', '2021_Carrier APJ');
            ruleList.add(rule);
            
            rule = getAccReassignInstance(userList[1].Id, 'TestRulePAO', '2021_Carrier APJ');
            ruleList.add(rule);
            
            rule = getAccReassignInstance(userList[2].Id, 'TestRulePAO', '2021_Carrier APJ');
            ruleList.add(rule);

            insert ruleList;
            
            List<Account> accList = new List<Account>();

            Account acc = getAccInstance('DRAONAtestAcc1', 'www.testWeb1.com', 'Commerce', 'Manufacturing', 'India', 'Delhi', ownerId1);
            accList.add(acc);

            acc = getAccInstance('DRAONAtestAcc2', 'www.testWeb2.com', 'Akamai Internal', 'Akamai Internal', 'India', 'Rajasthan', ownerId2);
            accList.add(acc);

            acc = getAccInstance('DRAONAtestAcc3', 'www.testWeb3.com', 'Gambling', 'Gambling Operators', 'India', 'Goa', ownerId3);
            accList.add(acc);
            
            acc = getAccInstance('DRAUsertestAcc4', 'www.testWeb4.com', 'Commerce', 'Manufacturing', 'India', 'Delhi', userList[0].id);
            accList.add(acc);
            
            acc = getAccInstance('DRAUsertestAcc5', 'www.testWeb5.com', 'Akamai Internal', 'Akamai Internal', 'India', 'Rajasthan', userList[1].id);
            accList.add(acc);
            
            acc = getAccInstance('DRAUsertestAcc6', 'www.testWeb6.com', 'Gambling', 'Gambling Operators', 'India', 'Goa', userList[2].id);
            accList.add(acc);
    
            insert accList;
           
        }

    }    
    
    @isTest static void oNAAccCreateUpdateWithDRA(){
        Test.startTest();
        List<Account> accList = [Select id, name, Website, Vertical__c, Sub_Vertical__c, BillingCountry, OwnerId, Projected_Sales_Owner__c, Projected_SDR__c, adg_Projected_Account_Owner__c from Account where name like 'DRAONAtestAcc%'];
        List<DRASubprocessConfig__c> draList = [Select id, Vertical__c, Country__c, Sub_Vertical__c, Region_or_State__c, SDR_Name__c, Projected_SDR__c, Exclude_from_Projected_Sales_Mapping__c from DRASubprocessConfig__c limit 10];
        List<Account_Reassignment_Rule__c> ruleList = [Select id, Associated_User__c, User_Role__c from Account_Reassignment_Rule__c where name like 'TestRulePAO'];
        
        Map<String, DRASubprocessConfig__c> vertToDRAMap = new Map<String, DRASubprocessConfig__c>();
        for(DRASubprocessConfig__c dra: draList){
            vertToDRAMap.put(dra.Vertical__c, dra);
        }
        
        Map<String, Account_Reassignment_Rule__c> psoToAccRuleMap = new Map<String, Account_Reassignment_Rule__c>();
        for(Account_Reassignment_Rule__c rule: ruleList){
            psoToAccRuleMap.put(rule.Associated_User__c, rule);
        }
        
        for(Account acc: accList){
            if(vertToDRAMap.containsKey(acc.Vertical__c)){
                System.assert(acc.Projected_SDR__c == vertToDRAMap.get(acc.Vertical__c).Projected_SDR__c, 'Account is not inserting with correct Projected SDR when DRA exists:' +acc.Projected_SDR__c+','+vertToDRAMap.get(acc.Vertical__c).Projected_SDR__c);
        		System.assert(acc.Projected_Sales_Owner__c == vertToDRAMap.get(acc.Vertical__c).SDR_Name__c, 'Account is not inserting with correct Projected Sales Owner when DRA exists');
                if(psoToAccRuleMap.containsKey(acc.Projected_Sales_Owner__c)){
                    System.assert(acc.adg_Projected_Account_Owner__c == psoToAccRuleMap.get(acc.Projected_Sales_Owner__c).id, 'Account is not inserting with correct Projected Account Owner when DRA exists');
                }
            }
        }
        for(Account acc: accList){
            acc.Vertical__c = 'Gaming';
            acc.Sub_Vertical__c = 'Game Store';
        }
        update accList;
        
        for(Account acc: accList){
            System.assert(acc.Projected_SDR__c != null, 'Account is not inserting with correct Projected SDR when DRA exists');
            System.assert(acc.Projected_Sales_Owner__c != null, 'Account is not inserting with correct Projected Sales Owner when DRA exists');
            System.assert(acc.adg_Projected_Account_Owner__c != null, 'Account is not inserting with correct Projected Account Owner when DRA exists');
        }
        
        Test.stopTest();
    }
    
    @isTest static void validAccCreateUpdateWithDRA(){
        Test.startTest();
        List<Account> accList = [Select id, name, Website, Vertical__c, Sub_Vertical__c, BillingCountry, OwnerId, Projected_Sales_Owner__c, Projected_SDR__c, adg_Projected_Account_Owner__c from Account where name like 'DRAUsertestAcc%'];
        List<DRASubprocessConfig__c> draList = [Select id, Vertical__c, Country__c, Sub_Vertical__c, Region_or_State__c, SDR_Name__c, Projected_SDR__c, Exclude_from_Projected_Sales_Mapping__c from DRASubprocessConfig__c limit 10];
        List<Account_Reassignment_Rule__c> ruleList = [Select id, Associated_User__c, User_Role__c from Account_Reassignment_Rule__c where name like 'TestRulePAO'];
        
        Map<String, DRASubprocessConfig__c> vertToDRAMap = new Map<String, DRASubprocessConfig__c>();
        for(DRASubprocessConfig__c dra: draList){
            vertToDRAMap.put(dra.Vertical__c, dra);
        }
        
        Map<String, Account_Reassignment_Rule__c> psoToAccRuleMap = new Map<String, Account_Reassignment_Rule__c>();
        for(Account_Reassignment_Rule__c rule: ruleList){
            psoToAccRuleMap.put(rule.Associated_User__c, rule);
        }
        
        for(Account acc: accList){
            if(vertToDRAMap.containsKey(acc.Vertical__c)){
                System.assert(acc.Projected_SDR__c == vertToDRAMap.get(acc.Vertical__c).Projected_SDR__c, 'Account is not inserting with correct Projected SDR when DRA exists:' +acc.Projected_SDR__c+','+vertToDRAMap.get(acc.Vertical__c).Projected_SDR__c);
        		System.assert(acc.Projected_Sales_Owner__c == vertToDRAMap.get(acc.Vertical__c).SDR_Name__c, 'Account is not inserting with correct Projected Sales Owner when DRA exists');
                if(psoToAccRuleMap.containsKey(acc.Projected_Sales_Owner__c)){
                    System.assert(acc.adg_Projected_Account_Owner__c == psoToAccRuleMap.get(acc.Projected_Sales_Owner__c).id, 'Account is not inserting with correct Projected Account Owner when DRA exists');
                }
            }
        }
        for(Account acc: accList){
            acc.Vertical__c = 'Gaming';
            acc.Sub_Vertical__c = 'Game Store';
        }
        update accList;
        
        for(Account acc: accList){
            System.assert(acc.Projected_SDR__c != null, 'Account is not inserting with correct Projected SDR when DRA exists');
            System.assert(acc.Projected_Sales_Owner__c != null, 'Account is not inserting with correct Projected Sales Owner when DRA exists');
            System.assert(acc.adg_Projected_Account_Owner__c != null, 'Account is not inserting with correct Projected Account Owner when DRA exists');
        }
        
        ONAAccCreateUpdateWithDRAAndExcludeChecked();
        
        Test.stopTest();
    }
    
    @isTest static void oNAAccCreateUpdateWithDRAAndExcludeChecked(){
        
        Map<String, DRASubprocessConfig__c> sDRToDRAMap = new Map<String, DRASubprocessConfig__c>();
        List<Account_Reassignment_Rule__c> ruleList = [Select id, Associated_User__c, User_Role__c from Account_Reassignment_Rule__c where name like 'TestRulePAO'];
        List<DRASubprocessConfig__c> draList = [Select id, Vertical__c, Country__c, Sub_Vertical__c, Region_or_State__c, SDR_Name__c, Projected_SDR__c, Exclude_from_Projected_Sales_Mapping__c from DRASubprocessConfig__c limit 10];
        
        Map<String, Account_Reassignment_Rule__c> psoToAccRuleMap = new Map<String, Account_Reassignment_Rule__c>();
        for(Account_Reassignment_Rule__c rule: ruleList){
            psoToAccRuleMap.put(rule.Associated_User__c, rule);
        }
        
        for(DRASubprocessConfig__c dra: draList){
            dra.Exclude_from_Projected_Sales_Mapping__c = true;
            sDRToDRAMap.put(dra.SDR_Name__c, dra);
        }
        update draList;
        
        List<Account> accList = [Select id, name, Website, Vertical__c, Sub_Vertical__c, BillingCountry, OwnerId, Projected_Sales_Owner__c, Projected_SDR__c, adg_Projected_Account_Owner__c from Account where name like 'DRAUsertestAcc%'];
        for(Account acc: accList){
            acc.Vertical__c = 'Gaming';
            acc.Sub_Vertical__c = 'Publishers';
        }
        update accList;
        
        for(Account acc: accList){
            if(sDRToDRAMap.containsKey(acc.OwnerId)){
                System.assert(acc.Projected_SDR__c == sDRToDRAMap.get(acc.OwnerId).Projected_SDR__c, 'Account is not inserting with correct Projected SDR when DRA exists:' +acc.Projected_SDR__c+','+sDRToDRAMap.get(acc.OwnerId).Projected_SDR__c);
        		System.assert(acc.Projected_Sales_Owner__c == sDRToDRAMap.get(acc.OwnerId).SDR_Name__c, 'Account is not inserting with correct Projected Sales Owner when DRA exists');
                if(psoToAccRuleMap.containsKey(acc.Projected_Sales_Owner__c)){
                    System.assert(acc.adg_Projected_Account_Owner__c == psoToAccRuleMap.get(acc.Projected_Sales_Owner__c).id, 'Account is not inserting with correct Projected Account Owner when DRA exists');
                }
            }
        }
    }
   
}