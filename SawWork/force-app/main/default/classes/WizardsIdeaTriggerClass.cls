/*
Author: janantha
Description: idea trigger class
Created Date: 29/12/2014
Modification: 
1. CR 2869635 by ssawhney -  Added logic for Idea Number Generation
2. CR 2869707 by Nagdeep  - Builing Search tag for SOSL
3. CR 2923158 by ssawhney on 15/03/2015 - Changed logic for Idea Number Generation to generate numbers based on Idea yearly cycle
4. CR 3197171 by janantha on 03/11/2015 - Added notifications for sponsor section changes.
*/

public class WizardsIdeaTriggerClass
{
    Messaging.SingleEmailMessage emailMessage;
    Messaging.SingleEmailMessage[] mailsToBeSent;
    String emailBody;
    Idea_Environment_Url__c CS = Idea_Environment_Url__c.getOrgDefaults();
    String envUrl;
    //Get the zone Id for wizards
    Id zoneId = [Select Id from Community where name = 'Wizards' limit 1].Id;
    String displayName = 'Akamai Wizards';
    String orgWideEmailId = '';
    
    public WizardsIdeaTriggerClass()
    {
        emailMessage = new Messaging.SingleEmailMessage();
        mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        emailBody = '';
        envUrl = CS.Url__c;
    }
        
    public void emailOnCatChange(Map<Id,Idea> updatedIdeas, Map<Id,Idea> oldIdeas)
    { 
        List<String> userIds = new List<String>();
        orgWideEmailId = [select Id from OrgWideEmailAddress where DisplayName = :displayName limit 1].Id;
        for(Idea idea : updatedIdeas.values())
        {
            userIds.add(idea.ActualCreator__c);
        }  
        /*get the user name value since idea.creatorname returns null*/
        Map<Id,User> userInfo = new Map<Id,User>([select Id, Name from User where Id in :userIds]);  
        
        for(Idea idea : updatedIdeas.values())
        {
            /* if category is updated */
            if(updatedIdeas.get(idea.Id).Project_Type__c != oldIdeas.get(idea.Id).Project_Type__c)
            {  
                emailMessage = new Messaging.SingleEmailMessage();
                emailBody = '';
                emailBody = '<html><body>'+'Dear '+ userInfo.get(idea.ActualCreator__c).Name+',' + '<br/><br/>';
                emailBody += 'Your idea '+'"'+idea.Title+'"'+', '+' has been moved from the '+oldIdeas.get(idea.Id).Project_Type__c+
                ' category to the '+updatedIdeas.get(idea.Id).Project_Type__c+' category by the Wizards Idea Review Team.'+'<br/><br/>'+
                ' To view or share this idea, use link - '+ envUrl+'/idea/'+ idea.Id+'.'+
                '<br/><br/>Best regards,<br/>Team Wizards<br/>akamai-wizards@akamai.com';
                
                emailMessage.setHtmlBody(emailBody);
                emailMessage.setSubject('Wizards Idea - Idea Category Change');
                emailMessage.setTargetObjectId(idea.ActualCreator__c);
                emailMessage.setSaveAsActivity(false);
                emailMessage.setOrgWideEmailAddressId(orgWideEmailId);
                mailsToBeSent.add(emailMessage);                    
            }
        }
        if(!Test.isRunningTest()){
            Messaging.sendEmail(mailsToBeSent);
        }
    }
    
    //Added by janantha
    public void sponsorAssignedEmail(List<Idea> newIdeas, Map<Id,Idea> oldIdeas)
    {       
        //EmailTemplate template = new EmailTemplate();
        orgWideEmailId = [select Id from OrgWideEmailAddress where DisplayName = :displayName limit 1].Id;
        //template = [select Id from EmailTemplate where Name = 'Sponsorer Assigned'];
        List<String> userIds = new List<String>();
        String oldSponsor = '';
        String newSponsor = '';
        
        for(Idea idea : newIdeas)
        {
            if(idea.sponsor__c != null)
                userIds.add(idea.sponsor__c);
        }
        
        for(Idea idea : oldIdeas.values())
        {
            if(idea.sponsor__c != null)
                userIds.add(idea.sponsor__c);
        }  
        /*get the user name value since idea.creatorname returns null*/
        Map<Id,User> userInfo = new Map<Id,User>([select Id, Name, Email from User where id in :userIds]); 
        
        for(Idea idea1:newIdeas)
        {   
            String ideaSubmitterEmail = idea1.IdeaSubmitterEmail__c;
            if(idea1.Sponsor__c != null && oldIdeas.get(idea1.Id).Sponsor__c == null && idea1.Sponsor_Email__c == null)
            {
                emailMessage = new Messaging.SingleEmailMessage();
                emailBody = '';
                emailBody = 'Dear '+ userInfo.get(idea1.Sponsor__c).Name +',<br><br>You have been assigned as sponsor for the Idea '+idea1.Title+'.<br>To view or share this idea, use link - '+ envUrl+'/idea/'+ idea1.Id+'.'+
                                '<br/><br/>Best regards,<br/>Team Wizards<br/>akamai-wizards@akamai.com';
                emailMessage.setSubject('Wizards Idea – Sponsor Assigned');
                emailMessage.setTargetObjectId(idea1.Sponsor__c);
                emailMessage.setSaveAsActivity(false);
                emailMessage.setOrgWideEmailAddressId(orgWideEmailId);
                emailMessage.setHtmlBody(emailBody);
                emailMessage.setCcAddresses(new List<String>{ideaSubmitterEmail});
                //emailMessage.setTemplateId(template.Id);
                mailsToBeSent.add(emailMessage); 
            }

            if(oldIdeas.get(idea1.Id).Sponsor__c != idea1.Sponsor__c && oldIdeas.get(idea1.Id).Sponsor__c != null)
            {
                if(idea1.Sponsor__c != null)
                {
                    oldSponsor = oldIdeas.get(idea1.Id).Sponsor__c;
                    newSponsor = idea1.Sponsor__c;
                    
                    emailMessage = new Messaging.SingleEmailMessage();
                    emailBody = '';
                    emailBody = 'Dear '+userInfo.get(idea1.Sponsor__c).Name+',<br><br>The Sponsor for the Idea '+idea1.Title+' has changed from '+userInfo.get(oldSponsor).Name+' to '+userInfo.get(newSponsor).Name+'<br><br>To view or share this idea, use link - '+ envUrl+'/idea/'+ idea1.Id+'.'+
                                '<br/><br/>Best regards,<br/>Team Wizards<br/>akamai-wizards@akamai.com';
                    emailMessage.setSubject('Wizards Idea – Sponsor change');
                    emailMessage.setTargetObjectId(idea1.Sponsor__c);
                    
                    emailMessage.setSaveAsActivity(false);
                    emailMessage.setOrgWideEmailAddressId(orgWideEmailId);
                    emailMessage.setHtmlBody(emailBody);
                    emailMessage.setCcAddresses(new List<String>{userInfo.get(oldIdeas.get(idea1.Id).Sponsor__c).Email, ideaSubmitterEmail});
                    mailsToBeSent.add(emailMessage); 
                    
                }              
            }
            if(oldIdeas.get(idea1.Id).Sponsor_Notes__c != idea1.Sponsor_Notes__c)
            {
                if(idea1.Sponsor__c != null)
                {
                    emailMessage = new Messaging.SingleEmailMessage();
                    emailBody = '';
                    emailBody = 'Dear '+userInfo.get(idea1.Sponsor__c).Name+',<br><br>The Sponsor notes for the Idea '+idea1.Title+' has changed from '+oldIdeas.get(idea1.Id).Sponsor_Notes__c+' to '+idea1.Sponsor_Notes__c+'<br><br>To view or share this idea, use link - '+ envUrl+'/idea/'+ idea1.Id+'.'+
                                '<br/><br/>Best regards,<br/>Team Wizards<br/>akamai-wizards@akamai.com';
                    emailMessage.setSubject('Wizards Idea – Sponsor Notes change');
                    emailMessage.setTargetObjectId(idea1.Sponsor__c);
                    emailMessage.setSaveAsActivity(false);
                    emailMessage.setOrgWideEmailAddressId(orgWideEmailId);
                    emailMessage.setHtmlBody(emailBody);
                    emailMessage.setCcAddresses(new List<String>{ideaSubmitterEmail});
                    mailsToBeSent.add(emailMessage); 
                }
            }
        }
        Messaging.sendEmail(mailsToBeSent);  
    }
    
    // Method to assign the reviewer in round robin manner to an idea
    public void populateProjectOwner(List<Idea> newIdeas)
    {
        String projectOwner = '';
        List<String> selectedCategoryList = new List<String>();
        List<String> selectedSubCategoryList = new List<String>();
        for(Idea idea: newIdeas){
            selectedCategoryList.add(idea.Project_Type__c);
            selectedSubCategoryList.add(idea.Idea_Sub_Category__c);
        }
        List<Idea_Reviewer__c> ideaReviewerList = [Select Category__c,Sub_Category__c,Current_Index__c,Reviewer_List__c from Idea_Reviewer__c where Reviewer_List__c != null and Category__c IN :selectedCategoryList and Sub_Category__c IN :selectedSubCategoryList];      
        for(Idea idea:newIdeas)
        {
            String selectedCategory = idea.Project_Type__c; 
            String selectedSubCategory = idea.Idea_Sub_Category__c;
           
            for(Idea_Reviewer__c reviewItem : ideaReviewerList){
                List<String> idList = reviewItem.Reviewer_List__c.split(',');
                Integer count = idList.size();
                if(reviewItem.Category__c == selectedCategory && reviewItem.Sub_Category__c == selectedSubCategory){
                    idea.Project_Owner__c = idList[reviewItem.Current_Index__c.intValue()]; 
                    reviewItem.Current_Index__c = Math.mod(reviewItem.Current_Index__c.intValue()+1,count);
                }
            }
        }
        update ideaReviewerList;
    }
    
    //Start of changes for CR 2923158 by ssawhney
    public void GenerateIdeaNumber(list<Idea> newIdeas)
    {

        Idea_Environment_Url__c IdeaSettings = [Select Current_Cycle_End_Date__c, Idea_Year__c, Incrementer__c, challenge_incrementer__c from Idea_Environment_Url__c LIMIT 1 FOR UPDATE] ;
        
        if(IdeaSettings != null && IdeaSettings.Current_Cycle_End_Date__c != null)
        {
            if(Date.Today() > IdeaSettings.Current_Cycle_End_Date__c)
            {
                IdeaSettings.Current_Cycle_Start_Date__c = IdeaSettings.Current_Cycle_End_Date__c.addDays(1);
                IdeaSettings.Current_Cycle_End_Date__c = IdeaSettings.Current_Cycle_End_Date__c.addyears(1);
                IdeaSettings.Idea_Year__c = IdeaSettings.Idea_Year__c + 1;
                IdeaSettings.Incrementer__c = 1;
            }
       
            for(Idea obj: newIdeas)
            {
                if(obj.CommunityId == zoneId && obj.Idea_Number__c == null || obj.Idea_Number__c == '')
                {   
                    if(obj.Idea_Challenge__c  != null){
                        obj.Idea_Number__c = 'WIZCHAL' + IdeaSettings.Idea_Year__c + '-' + IdeaSettings.challenge_incrementer__c;
                        IdeaSettings.challenge_incrementer__c++;
                    }
                    else{
                        obj.Idea_Number__c = 'Wiz' + IdeaSettings.Idea_Year__c + '-' + IdeaSettings.Incrementer__c; 
                        IdeaSettings.Incrementer__c++;
                    }      
                }
            }         
            update IdeaSettings;
        } 
    }
    //end of changes for CR 2923158

    //Added by Nagdeep for Seach Tag CR : 2869707
    public void SearchTagBuilder(List<Idea> updatedIdeas)
    {
        Set<Id> userIds=new Set<Id>();
        Map<Id,String> userNamemap= new Map<Id,String>();

        for (Idea rec: updatedIdeas)
        {
            userIds.add(rec.ActualCreator__c);
        }
   
        for(User u:[Select Id,Name from User where Id in :userIds]){
            userNamemap.put(u.Id,u.Name);
        }

        for(Idea obj: updatedIdeas)
        {
            obj.Search_Tag__c=userNamemap.get(obj.ActualCreator__c)+' '+obj.Title+' '+
            obj.Team_Members__c+' '+obj.Categories+' '+obj.Project_Type__c+' '+obj.Idea_Sub_Category__c+' '+obj.Idea_Number__c+' '+obj.CreatedDate; 
        }
    }
    
    //Added by Laxmi for Team Member CR : 3105771
    //Fixed by Prateek
    public List<Idea_Team_Members__c> setTeamMember(Map<String,String> userLdapIdMap,Map<String,String> userIdLdapMap,Idea idea,String operation)
    {
        List<Idea_Team_Members__c> teamMembers = new List<Idea_Team_Members__c>();
        Set<String> teamMemLdaps = new Set<String>();
        
        if(operation == 'insert'){
            string temp = userIdLdapMap.get(idea.ActualCreator__c);
            if(temp != null){
                teamMemLdaps.add(temp);
            }
        }  
        if(idea.Team_Members__c != null)
           teamMemLdaps.addAll(idea.Team_Members__c.split(',',0));
               
        for(String tm:teamMemLdaps){
                Idea_Team_Members__c teamMember = new Idea_Team_Members__c();
                teamMember.Team_Member__c = userLdapIdMap.get(tm.toUpperCase());
                if(teamMember.Team_Member__c != null){
                    teamMember.Idea__c = idea.Id;
                    teamMembers.add(teamMember);
                }
                else{
                    system.debug('tm : '+idea.Team_Members__c);
                    idea.addError('teamMember must be comma seperated LDAP');
                }   
        }   
        return teamMembers;
    }
    
    public List<Idea_Team_Members__c> getTeamMember(Map<String,Id> userLdapMap,Idea idea)
    {    
        List<String> ldaps = idea.Team_Members__c.split(',',0);
        List<Idea_Team_Members__c> resp = new List<Idea_Team_Members__c>();
        resp = [select Id from Idea_Team_Members__c where Idea__c = :idea.Id and Team_Member__r.Alias in :ldaps];
        return resp;
    }
    
    public Map<String,String> diffLdaps(String newLdap,String oldLdap)
    {
        Map<String,String> diffMap = new Map<String,String>();
        Set<String> newLdaps = new Set<String>(newLdap.split(',',0));
        Set<String> oldLdaps = new Set<String>(oldLdap.split(',',0));
        Set<String> newLdaps1 = newLdaps.clone();
            
        for(String ldap:newLdaps){
            if(oldLdaps.contains(ldap)){
                newLdaps.remove(ldap);
            }
        }
            
        for(String ldap:oldLdaps){
            if(newLdaps1.contains(ldap)){
                oldLdaps.remove(ldap);
            }
        }
            
        diffMap.put('Create',String.join(new List<String>(newLdaps),','));
        diffMap.put('Remove',String.join(new List<String>(oldLdaps),',')); 
        return diffMap;
    }

    //function to check if saved idea once submitted has the right idea number. 
    //if idea number is wiz2017-xx and current season is 2018 with idea incrementer as yy. then the number is changed to wiz2018-yy and yy is incremented
    public void validateIdeaNumber(List<Idea> newIdeas, Map<Id,Idea> oldIdeaMap){

        Idea_Environment_Url__c IdeaSettings = [Select Current_Cycle_End_Date__c, Idea_Year__c, Incrementer__c, challenge_incrementer__c from Idea_Environment_Url__c LIMIT 1 FOR UPDATE] ;
        String currentSeason = String.valueOf(IdeaSettings.Idea_Year__c);

        for(Idea idea: newIdeas){
            String ideaSeason = String.valueOf(idea.Idea_Number__c);

            if( (idea.State__c == 'Submitted' && oldIdeaMap.get(idea.Id).State__c == 'Saved') && (ideaSeason != currentSeason)){
                
                if(idea.Idea_Challenge__c == null){
                    idea.Idea_Number__c = 'Wiz' + IdeaSettings.Idea_Year__c + '-' + IdeaSettings.Incrementer__c;
                    IdeaSettings.Incrementer__c++;
                }
                else{
                    idea.Idea_Number__c = 'WIZCHAL' + IdeaSettings.Idea_Year__c + '-' + IdeaSettings.challenge_incrementer__c;
                    IdeaSettings.challenge_incrementer__c++;
                }
            }
        }

        update IdeaSettings;

    }

    //insert vote automatically when a new idea is created
    //public void createVoteAfterInsert(List<Idea> newIdeas){
    //    List<Vote__c> votesToBeInserted = new List<Vote__c>();
    //    for(Idea idea:newIdeas){
    //        Vote__c vote = new Vote__c();
    //        vote.ActualCreator__c = idea.ActualCreator__c;
    //        vote.ParentId__c = idea.Id;
    //        vote.Type__c = 'Up';
    //        votesToBeInserted.add(vote);
    //    }
    //    if(votesToBeInserted.size() > 0){
    //        insert votesToBeInserted;
    //    }
    //}
    
    public void createRemoveMembers(list<Idea> newIdeas, Map<Id,Idea> oldIdeaMap){
        
        Map<String,String> userLdapIdMap = new Map<String,String>();
        Map<String,String> userIdLdapMap = new Map<String,String>();
        List<String> aliasesList = new List<String>();
        List<Idea_Team_Members__c> createTeamMembers = new List<Idea_Team_Members__c>();
        List<Idea_Team_Members__c> removeTeamMembers = new List<Idea_Team_Members__c>();
        
        //if (Test.isRunningTest()){
        //    userLdapIdMap.put('TESTALIAS', UserInfo.getUserId());
        //    userIdLdapMap.put(UserInfo.getUserId(), 'TESTALIAS');
        //}

        //generate map of id to alias
        List<String> ideaCreatorIds = new List<String>();
        for(Idea idea: newIdeas){
            ideaCreatorIds.add(idea.ActualCreator__c);
        }
        Map<String, String> idToAlias = new Map<String,String>();
        for(User user: [select Id, Alias from User where Id in :ideaCreatorIds]){
            idToAlias.put(user.Id, user.Alias);
        }

        for(Idea idea:newIdeas){

            aliasesList.add(idToAlias.get(idea.ActualCreator__c));

            if(idea.Team_Members__c != null){
                String[] members = idea.Team_Members__c.split(',');
                for(string alias:members){
                    aliasesList.add(alias);
                }
            }
        }

        for(User u:[Select Id,Alias from User where IsActive = true and Alias in :aliasesList order by Name]){
            userLdapIdMap.put(u.Alias,u.Id);
            userIdLdapMap.put(u.Id,u.Alias);
        }
        
        for(Idea idea:newIdeas){
            //if idea is created 
            if(oldIdeaMap == null){
              createTeamMembers.addAll(setTeamMember(userLdapIdMap,userIdLdapMap,idea,'insert'));  
            }
            //if idea is updated
            else if(idea.Team_Members__c != oldIdeaMap.get(idea.Id).Team_Members__c){ //if oldIdeaMap is null then its an insert else update
                //All team members are added after idea is submited
                if(idea.Team_Members__c != null && oldIdeaMap.get(idea.Id).Team_Members__c == null){ 
                    createTeamMembers.addAll(setTeamMember(userLdapIdMap,userIdLdapMap,idea,'update'));
                }
                //if all team members are removed after idea is submited
                else if(idea.Team_Members__c == null && oldIdeaMap.get(idea.Id).Team_Members__c != null){ 
                    removeTeamMembers.addAll(getTeamMember(userLdapIdMap,oldIdeaMap.get(idea.Id)));
                }
                //if team members are added or removed
                else{ 
                    Map<String,String> diffMap = diffLdaps(idea.Team_Members__c,oldIdeaMap.get(idea.Id).Team_Members__c);
                    String newTeam = idea.Team_Members__c; 
                    if(diffMap.get('Create') != ''){
                        idea.Team_Members__c = diffMap.get('Create');
                        createTeamMembers.addAll(setTeamMember(userLdapIdMap,userIdLdapMap,idea,'update'));
                    }
                    if(diffMap.get('Remove') != ''){
                        idea.Team_Members__c = diffMap.get('Remove');
                        removeTeamMembers.addAll(getTeamMember(userLdapIdMap,idea));
                    }  
                    idea.Team_Members__c = newTeam;
                } 
            }
        } 
       
        if(createTeamMembers.size() > 0){
            insert createTeamMembers;
        } 
        if(removeTeamMembers.size() > 0){
            delete removeTeamMembers;
        }  
           
    }
}