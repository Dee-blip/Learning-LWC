public class TSProductMemberExtension {

    ApexPages.StandardController sController;
    public TS_ProductMember__c pmember {get; set;}
    public TS_Product_Skill__c parentSkill {get; set;}
    public String skillId {get; set;}
    public String userId {get; set;}
    public Boolean success {get;set;}
    public String selectedSkill {get;set;}
    public String action;
    
    
    public TSProductMemberExtension(ApexPages.StandardController controller) {
        sController = controller;
        //sController.addFields(new List<String>{'TS_Product_Skill__c'});
        this.pmember = (TS_ProductMember__c) sController.getRecord();
        skillId = ApexPages.currentPage().getParameters().get('skillid');
        userId = ApexPages.currentPage().getParameters().get('userid');
        action = ApexPages.currentPage().getParameters().get('act');
        if(userId != null && userId != '')
        {
            pmember.ProductMember__c = userId;
        }
       if(pmember.TS_Product_Skill__c != null)
        {
            selectedSkill = pmember.TS_Product_Skill__c;
        }
              
        else
        {
            pmember.TS_Product_Skill__c = skillId;
        }         
        success = null;
    }
    
    public List<SelectOption> getAllSkills()
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('-None-','-None-'));
        TS_Product_Skill__c[] skills = [Select Name, Id, Product_Skill_Name__c from TS_Product_Skill__c order by Product_Skill_Name__c];
        if(skills.size() > 0)
        {
           for(TS_Product_Skill__c s : skills)  
            {
                options.add(new SelectOption(s.Id, s.Product_Skill_Name__c));                
            }  
        }
        return options;
    }
    
    public PageReference save()
    {
        try
        {
            if(ApexPages.currentPage().getURL().contains('/apex/TSACDSkillMemberCreate')) //this check is for the UI where users add skill for a member
            {
                pmember.TS_Product_Skill__c = selectedSkill;
                skillId = selectedSkill;
                if(selectedSkill == null || selectedSkill == '' || selectedSkill == '-None-')
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter the skill value'));
                    return null;
                } 
            }
            String thisUser = pmember.ProductMember__c;
            if(action == null || !action.equals('Edit'))
            {
                List<TS_ProductMember__c> userList = [SELECT ProductMember__c, ProductMember__r.id, ProductMember__r.Name from TS_ProductMember__c where TS_Product_Skill__r.Id =: skillId];
                for(TS_ProductMember__c itrUser:userList){
                    if(itrUser.ProductMember__c.equals(thisUser)){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The user is already added to this skill'));
                        return null;
                    }   
                }
            }
            //List<TS_ProductMember__c> productMemberList = [SELECT Id, ProductMember__c  from TS_ProductMember__c where TS_Product_Skill__c = :skillId and ProductMember__c = :userId];
            
            PageReference ref = sController.save();
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'A new ACD skill member has been successfully created'));
            success = true;           
            return null;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
}