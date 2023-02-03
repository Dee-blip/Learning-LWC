public class TSProductSkillListExtension {

    public String skillId {get; set;}
    public TS_Product_Skill__c skillObj;
    public List<TS_ProductMember__c> userList {get; set;}
    public String toBeDelMember {get; set;}
    public Boolean isRendered=false;
    public String userLabel = System.Label.Team_Skill_Super_Users;
    public User loggedInUser{get;set;}
    public String skillName {get; set;}
    public List<TS_Product_Skill__c> skills {get; set;}
    
    public TSProductSkillListExtension(ApexPages.StandardSetController controller) {
        controller.setPageSize(controller.getResultSize());
        skills = [select Id, IsDeleted, Name, Description__c, OwnerId, Product_Skill_Name__c from TS_Product_Skill__c order by LastModifiedDate DESC];              
    }
    
    public TSProductSkillListExtension(ApexPages.StandardController controller) {
                     
    }
    
    public Boolean getIsRendered()
    {
         loggedInUser=new User();
         loggedInUser=[Select Id,Name,Email,Alias from User where Id=:userinfo.getuserId()];   
         String[] userids = userLabel.split(',');
         Set<String> userIdSet = new Set<String>();
         userIdSet.addAll(userids);
         If(userIdSet.contains(loggedInUser.Alias))
         {
            isRendered=true;
         }
         return isRendered;
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
    
    public PageReference newSkill()
    {
        PageReference ref = new PageReference('/apex/TSProductSkillCreate');
        return ref;
    }
    
    public void getSkillMembers() {
        skillId = ApexPages.currentPage().getParameters().get('skillId');
        userList = [SELECT Id, ProductMember__c, Skill_Level__c, ProductMember__r.alias, ProductMember__r.FirstName, ProductMember__r.LastName, ProductMember__r.Email, ProductMember__r.Division, ProductMember__r.ACD_Agent_ID__c, ProductMember__r.Manager.Name, ProductMember__r.Shift__c, ProductMember__r.Team__c, ProductMember__r.Office_Location__c from TS_ProductMember__c where TS_Product_Skill__r.Id =: skillId];   
        List<TS_Product_Skill__c> SkillDetail = [Select Product_Skill_Name__c from TS_Product_Skill__c where Id =: skillId];
        if(SkillDetail != null && !SkillDetail.isEmpty())
            skillName = SkillDetail[0].Product_Skill_Name__c;      
    }
    
    public void getSkillMembersPoll() {
        if(skillId==null){
            return;
        }
        userList = [SELECT Id, ProductMember__c, Skill_Level__c, ProductMember__r.alias, ProductMember__r.FirstName, ProductMember__r.LastName, ProductMember__r.Email, ProductMember__r.Division, ProductMember__r.ACD_Agent_ID__c, ProductMember__r.Manager.Name, ProductMember__r.Shift__c, ProductMember__r.Team__c, ProductMember__r.Office_Location__c from TS_ProductMember__c where TS_Product_Skill__r.Id =: skillId];   
        List<TS_Product_Skill__c> SkillDetail = [Select Product_Skill_Name__c from TS_Product_Skill__c where Id =: skillId];
        if(SkillDetail != null && !SkillDetail.isEmpty())
            skillName = SkillDetail[0].Product_Skill_Name__c;      
    }
    
    public TS_Product_Skill__c getSkill() {
        skillObj = [SELECT Name from TS_Product_Skill__c where Id =:skillId];
        return skillObj;
    }
    
    public PageReference newMember()
    {
        TS_Product_Skill__c obj = getSkill();         
        PageReference ref = new PageReference('/apex/TSProductMemberCreate');
        ref.getParameters().put('skillid', skillId);
        return ref;
    }
    
    public void deleteMember(){
        List<TS_ProductMember__c> tempUserList;
        tempUserList = [Select id,Name from TS_ProductMember__c where id =: toBeDelMember];
        if(tempUserList.size() > 0 || tempUserList[0].Id != '')
        {
            delete tempUserList;
        }
        userList = [SELECT Id, ProductMember__c, Skill_Level__c, ProductMember__r.alias, ProductMember__r.FirstName, ProductMember__r.LastName, ProductMember__r.Email, ProductMember__r.Division, ProductMember__r.ACD_Agent_ID__c, ProductMember__r.Manager.Name, ProductMember__r.Shift__c, ProductMember__r.Team__c, ProductMember__r.Office_Location__c from TS_ProductMember__c where TS_Product_Skill__r.Id =: skillId];   
        List<TS_Product_Skill__c> SkillDetail = [Select Product_Skill_Name__c from TS_Product_Skill__c where Id =: skillId];
        if(SkillDetail != null && !SkillDetail.isEmpty())
            skillName = SkillDetail[0].Product_Skill_Name__c; 
   }
    
}