public with sharing class SupportTeamByEmployeeController extends SupportEmployee {
 
 public User user {get;set;}
 
 public List<TS_TeamMember__c>  ts_employees {get;set;}
 public List<TS_TeamMember__c> userDetailsList{get;set;}
 public List<User> userList {get;set;}
 public Map<String,SupportEmployee>  userMap{get;set;}
 public String userId {get;set;}
 public String userName {get;set;}
 
  public SupportTeamByEmployeeController(){
   
    userList = [SELECT Id,Username, LastName, FirstName, Name, Email, Support_Department__c, Alias, Manager.Name from User where Owner_Support_Department__c='Technical Support'];
    getUserList();
     // acct = (Account) ctrl.getRecord();
  }
  
 /* public SupportTeamByEmployeeController(ApexPages.StandardSetController stdController){
    //userList = [SELECT Id,Username, LastName, FirstName, Name, Email, Support_Department__c  from User where Support_Department__c='Technical Support'];
    //getUserList();
  }*/
  
  public PageReference refresh(){
        PageReference pageRef = new PageReference(getURL());
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public String getURL() {
        String URL = ApexPages.CurrentPage().GetURL();
        return URL.substring(0,URL.indexOf('?'));
    }
  
  public void getUserList(){
     userMap = new Map<String,SupportEmployee>(); 
     List<User> userList = new List<User>();
     //userDetailsList = [SELECT Team_Member__r.Id, TS_Support_team__c, Role__c,Team_Member__r.Username,Team_Member__r.Alias,Team_Member__r.FirstName, Team_Member__r.LastName, Team_Member__r.Email, Team_Member__r.Manager.Name from TS_TeamMember__c where Team_Member__r.Support_Department__c='Technical Support' order by Team_Member__r.FirstName]; 
     userDetailsList = [SELECT Team_Member__r.Id, TS_Support_team__c, Role__c,Team_Member__r.Username,Team_Member__r.Alias,Team_Member__r.FirstName, Team_Member__r.LastName, Team_Member__r.Email, Team_Member__r.Manager.Name from TS_TeamMember__c order by Team_Member__r.FirstName]; 
      
     AggregateResult[] grpResults = [SELECT TS_Support_Team__c, COUNT(Team_Account__c) accCount from TS_TeamAccount__c group by TS_Support_Team__c];
     Map<String, integer> supportTeamAccMap = new Map<String, integer>();
      
      for(AggregateResult result : grpResults){ 
          supportTeamAccMap.put((String)result.get('TS_Support_Team__c'),(integer)result.get('accCount'));
      }
      
     for(integer i=0;i<userDetailsList.size();i++){
         String userId = userDetailsList.get(i).Team_Member__r.Id;  
         String roleType = userDetailsList.get(i).Role__c;
         String supportTeamId = userDetailsList.get(i).TS_Support_team__c;
         SupportEmployee supportEmployee = new SupportEmployee();
         integer supportPrimary = 0; integer supportSecondary = 0; integer supportOthers = 0;
         String supportPrimryId = ''; String supportScndryId=''; String supportOtherId='';
         
         if(roleType.equals('Technical Support - Primary')){
            supportPrimary = supportPrimary+1; 
            supportPrimryId = supportTeamId;
        }       
         else if(roleType.equals('Technical Support - Secondary')){
             supportSecondary = supportSecondary+1;
             supportScndryId = supportTeamId;
            
         }        
         else if(roleType.equals('Technical Support - Other')){
             supportOthers = supportOthers+1;
             supportOtherId = supportTeamId;
            
         }      
         if(userMap.get(userId)!=null){
              supportEmployee = userMap.get(userId);
              supportEmployee.setPrimarySupport(supportEmployee.getPrimarySupport()+supportPrimary);   
              supportEmployee.setSecondarySupport(supportEmployee.getSecondarySupport()+supportSecondary);   
              supportEmployee.setOtherSupport(supportEmployee.getOtherSupport()+supportOthers); 
              if(!supportPrimryId.equals('')){
                Set<String> prmrySupport = supportEmployee.getPrimarySupportIds();
                prmrySupport.add(supportPrimryId);
                supportEmployee.setPrimarySupportIds(prmrySupport);
             }  
             
              if(!supportScndryId.equals('')){
                 //System.debug('Secondary not null');
                 Set<String> secdrySupport = supportEmployee.getSecondarySupportIds();
                 secdrySupport.add(supportScndryId);
                 supportEmployee.setSecondarySupportIds(secdrySupport);
            }
             
            if(!supportOtherId.equals('')){        
                Set<String> othersSupport = supportEmployee.getOtherSupportIds();
                othersSupport.add(supportOtherId);
                supportEmployee.setOtherSupportIds(othersSupport);
             } 
             // supportEmployee.setSecondarySupportIds(supportEmployee.getSecondarySupportIds().add(supportScndryId));
             userMap.put(userId,supportEmployee);
         }
         else{
                 
                 supportEmployee = new SupportEmployee();
                 supportEmployee.setPrimarySupport(supportPrimary);   
                 supportEmployee.setSecondarySupport(supportSecondary);   
                 supportEmployee.setOtherSupport(supportOthers);   
             
                if(!supportPrimryId.equals('')){                                  
                    Set<String> prmrySupport = new Set<String>();
                    prmrySupport.add(supportPrimryId);
                    supportEmployee.setPrimarySupportIds(prmrySupport);
                }      
             
                 if(!supportScndryId.equals('')){                  
                     Set<String> secdrySupport = new Set<String>();
                     secdrySupport.add(supportScndryId);
                     supportEmployee.setSecondarySupportIds(secdrySupport);
                }
             
             
                if(!supportOtherId.equals('')){
                 //System.debug('Others not null');
                    Set<String> othersSupport = new Set<String>();
                    othersSupport.add(supportOtherId);
                    supportEmployee.setOtherSupportIds(othersSupport);
                    }
                 User user = new User();
                 user.Id = userDetailsList.get(i).Team_Member__r.Id;
                 user.Username = userDetailsList.get(i).Team_Member__r.Username;
                 user.FirstName = userDetailsList.get(i).Team_Member__r.FirstName;
                 user.LastName = userDetailsList.get(i).Team_Member__r.LastName;
                 user.Email = userDetailsList.get(i).Team_Member__r.Email;
                 user.Alias = userDetailsList.get(i).Team_Member__r.Alias;
                 user.Manager = userDetailsList.get(i).Team_Member__r.Manager;
                 supportEmployee.setUser(user);
                 
                 userMap.put(userId,supportEmployee);
        
         }
           }
      for(String id : userMap.keySet()){
          
        SupportEmployee supportEmployee = userMap.get(id);
        integer noOfAccPrimary = 0; integer noOfAccSecondary = 0; integer noOfAccOthers = 0;  
          
          if(supportEmployee.getPrimarySupportIds()!=null && supportEmployee.getPrimarySupportIds().size()>0)   {
              for(String primarySupportId : supportEmployee.getPrimarySupportIds()){
                  if(supportTeamAccMap.get(primarySupportId)!=null){                  
                    noOfAccPrimary = noOfAccPrimary+supportTeamAccMap.get(primarySupportId);
                 }
              }
          }     
          
          if(supportEmployee.getSecondarySupportIds() !=null && supportEmployee.getSecondarySupportIds().size()>0)   {
              for(String secondarySupportId : supportEmployee.getSecondarySupportIds()){
                  if(supportTeamAccMap.get(secondarySupportId)!=null){
                    noOfAccSecondary = noOfAccSecondary+supportTeamAccMap.get(secondarySupportId);
                 }
              }
          }  
          
          if(supportEmployee.getOtherSupportIds() !=null && supportEmployee.getOtherSupportIds().size()>0)   {
              for(String otherSupportId : supportEmployee.getSecondarySupportIds()){
                  if(supportTeamAccMap.get(otherSupportId)!=null){
                    noOfAccOthers = noOfAccSecondary+supportTeamAccMap.get(otherSupportId);
                 }
              }
          }  
          supportEmployee.setPrimaryAccCount(noOfAccPrimary);
          supportEmployee.setSecondaryAccCount(noOfAccSecondary);
          supportEmployee.setOtherAccCount(noOfAccOthers);
          userMap.put(id, supportEmployee);
          
      }
      userList = [SELECT Id, Username, FirstName, LastName, Email, Alias, Manager.Name from User  where Owner_Support_Department__c = 'Technical Support' and Id not in :userMap.keySet()];
      for(User user : userList){
        SupportEmployee supportEmployee = new SupportEmployee();
        supportEmployee.setPrimarySupport(0); supportEmployee.setSecondarySupport(0);
        supportEmployee.setOtherSupport(0); supportEmployee.setPrimaryAccCount(0);
        supportEmployee.setSecondaryAccCount(0); supportEmployee.setOtherAccCount(0);
        supportEmployee.setUser(user);
        userMap.put(user.Id, supportEmployee);
      }

      SupportEmployee supportEmployee = userMap.get('005A0000000MuunIAC');
     
      
  }
  public void getSupportTeams(){

    String userId = ApexPages.currentPage().getParameters().get('userId');
    ts_employees = [SELECT  Role__c, TS_Support_Team__c, Team_Member__c, TS_Support_Team__r.Team_Name__c from TS_TeamMember__c where Team_Member__c=:userId];
    List<User> userDetail = [Select Name from User where Id =: userId];
      if(userDetail != null && !userDetail.isEmpty())
      userName = userDetail[0].Name;
  }
}