public with sharing class ACDEmployeeController {
 
 public User user {get;set;}
 
 public List<TS_ProductMember__c>  ts_skills {get;set;}
 public String userId{get;set;}
 public List<User> userList {get;set;}
 public String userName {get; set;}
 public String toBeDelSkill {get; set;}
 
  public ACDEmployeeController(){
    
     // acct = (Account) ctrl.getRecord();
  }
  
   public ACDEmployeeController(ApexPages.StandardSetController stdController){

     userList = [SELECT Id,Username, LastName, FirstName, Name, Email, Support_Department__c, ACD_Agent_ID__c, Alias, Manager.Name, Shift__c, Team__c, Office_Location__c  from User where Owner_Support_Department__c='Technical Support' order by LastModifiedDate DESC];   
  }
  
  public PageReference refresh(){
        PageReference pageRef = new PageReference(getURL());
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public String getURL() {
        String URL = ApexPages.CurrentPage().GetURL();
        return URL.substring(0,URL.indexOf('?'));
    }
    
  public void getUserSkills(){
      
     userId = ApexPages.currentPage().getParameters().get('userId');
    //System.debug('User Id '+userId);
    
    ts_skills = [SELECT  Id,TS_Product_Skill__r.Id, TS_Product_Skill__r.Product_Skill_Name__c, Skill_Level__c, TS_Product_Skill__c from TS_ProductMember__c where ProductMember__c=:userId];
    List<User> userDetail = [Select Name from User where Id =: userId];
    if(userDetail != null && !userDetail.isEmpty())
        userName = userDetail[0].Name; 
    
    //System.debug('User Skills  '+ts_skills);
   
  }
  
  public void getUserSkillsPoll(){
      if(userId==null){
          return;
      }
      ts_skills = [SELECT  Id,TS_Product_Skill__r.Id, TS_Product_Skill__r.Product_Skill_Name__c, Skill_Level__c from TS_ProductMember__c where ProductMember__c=:userId];
      List<User> userDetail = [Select Name from User where Id =: userId];
      if(userDetail != null && !userDetail.isEmpty())
      userName = userDetail[0].Name;
  }
  
  public void deleteSkill(){
        List<TS_ProductMember__c> tempUserList;
        tempUserList = [Select id,Name from TS_ProductMember__c where id =: toBeDelSkill];
        if(tempUserList.size() > 0 || tempUserList[0].Id != '')
        {
            delete tempUserList;
        }
        getUserSkills();
   }
  
}