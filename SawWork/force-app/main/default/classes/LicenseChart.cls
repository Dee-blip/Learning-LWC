/*
Template: Apex Class

CopyRight: Amogh MP @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : Shown as Lightning Tab

Purpose : To show the License Report of Users
          
Usage : Shows the users grouped by profile, active users, inactive users, users who have not logged in from past 6 months, 
        users who have logged in but not touched any ticket, no.of users grouped according to no.of modifications and no.of tickets used.
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Components Associated : [ License_UserByProfile, License_UsageChart, License_ReportTable, License_FrequentUse]
    
Objects associated : [ User, BMCServiceDesk__incident__c, BMCServiceDesk__Incident__History]
*/

public class LicenseChart { 
    
    //This method is to get list of all the Users
    @AuraEnabled
    public static List<User> listUsers()  
    {
        List<User> UsersList = new List<User>();
        UsersList = [Select Name,Username,Profile.Name,IsActive,BMCServiceDesk__IsStaffUser__c,LastLoginDate from User where BMCServiceDesk__IsStaffUser__c = TRUE LIMIT 1000];
        return UsersList;
    }
    
    //This method is to get list of all the Users based on specific profile
    @AuraEnabled
    public static List<User> listUsers1(String profileName)  
    {
        List<User> UsersList = new List<User>();
        UsersList = [Select Name,Username,Profile.Name,IsActive,BMCServiceDesk__IsStaffUser__c,LastLoginDate from User where BMCServiceDesk__IsStaffUser__c = TRUE and Profile.Name = :profileName LIMIT 1000];
        return UsersList;
    }
    
    //This method is to get list of all the Users who are active or inactive
    @AuraEnabled
    public static List<User> listUsers2(Boolean active)  
    {
        List<User> UsersList = new List<User>();
        UsersList = [Select Name,Username,Profile.Name,IsActive,BMCServiceDesk__IsStaffUser__c,LastLoginDate from User where BMCServiceDesk__IsStaffUser__c = TRUE and IsActive = :active LIMIT 1000];
        return UsersList;
    }
    
    //This method is to get list of all the Users who have not logged in from the past no.of months passed
    @AuraEnabled
    public static List<User> listUsers3(Integer duration)  
    {
        DateTime now = DateTime.now();
        List<User> UsersList = new List<User>();
        UsersList = [Select Name,Username,Profile.Name,IsActive,BMCServiceDesk__IsStaffUser__c,LastLoginDate from User where BMCServiceDesk__IsStaffUser__c = TRUE and LastLoginDate 
                    <= :now - duration LIMIT 1000];
        return UsersList;
    }
    
    //This method is to get list of all the Users are not owners and have not touched any ticket
    @AuraEnabled
    public static List<User> listUsers4(Integer duration)  
    {
        DateTime now = DateTime.now();
        List<User> UsersList = new List<User>();
        UsersList = [Select Name,Username,Profile.Name,IsActive,BMCServiceDesk__IsStaffUser__c,LastLoginDate from User where User.Id NOT IN (SELECT BMCServiceDesk__incident__c.ownerId FROM BMCServiceDesk__incident__c where BMCServiceDesk__Status_ID__c = 'CLOSED' or BMCServiceDesk__Status_ID__c = 'RESOLVED') and User.Id NOT IN (SELECT CreatedById FROM BMCServiceDesk__Incident__History where CreatedDate >= :now - duration) and BMCServiceDesk__IsStaffUser__c = TRUE and LastLoginDate >= :now - duration LIMIT 1000];
        return UsersList;
    }
    
    //for no.of tickets and no.of modifications
    //This method is to get list of all the Users 
    @AuraEnabled
    public static List<User> bluemoont(List<String> UID)  
    {        
        List<User> UsersList = new List<User>();
        UsersList = [Select Name,Username,Profile.Name,IsActive,BMCServiceDesk__IsStaffUser__c,LastLoginDate from User where User.Id IN :UID LIMIT 1000];
        System.debug(UsersList);
        return UsersList;
    }
    
    //This method returns the mapping of profile name and no.of users
	@AuraEnabled
    public static String getUsersJSON(){   

        List<AggregateResult> lstopp = [SELECT COUNT(Id), Profile.Name FROM User where BMCServiceDesk__IsStaffUser__c = TRUE group by Profile.Name LIMIT 1000];
        Map<String,Decimal> mapLeadSource = new Map<String,Decimal>();
        
        for(AggregateResult l : lstopp)
        {
            String catGroup = (String)l.get('Name');
            mapLeadSource.put(catGroup, (Decimal)l.get('expr0')) ;
        }
        system.debug('map values--'+mapLeadSource);
        list<RadarDataWrapper> radarData = new list<RadarDataWrapper>();
 
        for(String key : mapLeadSource.keySet())
        {
           RadarDataWrapper rdw = new RadarDataWrapper();
            rdw.name=key;
            rdw.y=mapLeadSource.get(key);
            radarData.add(rdw);
        }
        system.debug('rdw---'+radarData);
        return System.json.serialize(radarData);
    }
 
    //Wrapper class to serialize as JSON as return Value
    class RadarDataWrapper
    {
       @AuraEnabled
       public String name;
       @AuraEnabled
       public decimal y;
 
    }
    
    //This method returns the mapping of active users, inactive users, no.of users who have not logged in past 6 months and no.of users who have not touched any ticket when they loggen in the past 6 months
    @AuraEnabled
    public static String getUsageJSON(Integer months){           
 
        List<AggregateResult> usage = [SELECT COUNT(Id), IsActive FROM User where BMCServiceDesk__IsStaffUser__c = TRUE group by IsActive LIMIT 1000];
        System.debug(usage); 
        DateTime now = DateTime.now();
        
        //This is done for the last 6 months inactivity, changed boolean to string everywhere
        List<AggregateResult> sixmonth = [Select count(id) from User where BMCServiceDesk__IsStaffUser__c = TRUE and LastLoginDate <= :now - months];

        //This is done for the users who are not owners
        List<AggregateResult> uno = [Select count(id) from User where User.Id NOT IN (SELECT BMCServiceDesk__incident__c.ownerId FROM BMCServiceDesk__incident__c where BMCServiceDesk__Status_ID__c = 'CLOSED' or BMCServiceDesk__Status_ID__c = 'RESOLVED') and User.Id NOT IN (SELECT CreatedById FROM BMCServiceDesk__Incident__History where CreatedDate >= :now - months) and BMCServiceDesk__IsStaffUser__c = TRUE and LastLoginDate >= :now - months];
        
        Map<String,Decimal> mapLeadSource = new Map<String,Decimal>();
        for(AggregateResult l : usage)
        {
            Boolean catGroup = (Boolean)l.get('IsActive');
            String cat = String.valueOf(catGroup);
            mapLeadSource.put(cat, (Decimal)l.get('expr0')) ;
        }
        for(AggregateResult l : sixmonth)
        {
            mapLeadSource.put('No Login',(Decimal)l.get('expr0'));
        }
        for(AggregateResult l : uno)
        {
            mapLeadSource.put('Logged in no activity',(Decimal)l.get('expr0'));
        }    
            
        //system.debug('map values--'+mapLeadSource);
        list<RadarDataWrapper1> radarData = new list<RadarDataWrapper1>();
        for(String key : mapLeadSource.keySet())
        {
           RadarDataWrapper1 rdw = new RadarDataWrapper1();
            rdw.name=key;
            rdw.y=mapLeadSource.get(key);
            radarData.add(rdw);
        }
        //system.debug('rdw---'+radarData);
        return System.json.serialize(radarData);
    }
    
    //Wrapper class to serialize as JSON as return Value
    class RadarDataWrapper1
    {
       @AuraEnabled
       public String name;
       @AuraEnabled
       public decimal y;
 
    }
    
    //This method returns the mapping of users and no.of modifications, no.of tickets 
    @AuraEnabled
    public static String getTicketsJSON(Integer months, String now){   
        
        Date now1 = Date.valueOf(now);
 
        List<BMCServiceDesk__Incident__History> lstopp = [SELECT Id, ParentId, CreatedDate, CreatedById, NewValue, OldValue, Field FROM BMCServiceDesk__Incident__History where Field = 'owner' and CreatedDate >= :now1 - (months*15) and CreatedDate < :now1 - ((months-1)*15) LIMIT 50000];
        //List<BMCServiceDesk__Incident__History> lst = new List<BMCServiceDesk__Incident__History>();
        
        List<User> us = [Select Id from User where BMCServiceDesk__IsStaffUser__c = TRUE];
        List<String> userid = new List<String>();
        
        Set<String> mapLeadSource = new Set<String>();
        for(User u : us)
        {
            String uid = (String)u.get('Id');
            //System.debug(uid);
            userid.add(uid);
        }
        
        Decimal c1=0,c10=0,c100=0;
        for(BMCServiceDesk__Incident__History l : lstopp)
        {
            String mid = (String)l.get('Id');
            String pid = (String)l.get('ParentId');
            String nid = (String)l.get('NewValue');
            String oid = (String)l.get('OldValue');
            System.debug(nid);
            if(nid.startsWith('005') && nid != oid)
            {
                if(userid.contains(nid))
                {
                	//lst.add(l);
                	mapLeadSource.add(mid+'*'+nid+'#'+pid);
                }
            }
        }
        
        System.debug(mapLeadSource);
        list<RadarDataWrapper3> radarData = new list<RadarDataWrapper3>();
        for(String key : mapLeadSource)
        {
            RadarDataWrapper3 rdw = new RadarDataWrapper3();
            rdw.Ids=key;
            radarData.add(rdw);
        }
        //system.debug('rdw---'+radarData);
        return System.json.serialize(radarData);
    }
 
    //Wrapper class to serialize as JSON as return Value
    class RadarDataWrapper3
    {
       @AuraEnabled
       public String Ids;
    }
    
}