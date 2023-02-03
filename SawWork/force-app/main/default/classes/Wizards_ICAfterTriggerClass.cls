/*
    Author : Jayalakshmi
    Description: Trigger class for sending out emails to idea owner and users who commented previously on the idea.
    Created Date: 16/12/2014
    Modified by Prateek Bhuwania on 10/08/2018 for wizards migration to appbattery
*/

public class Wizards_ICAfterTriggerClass
{
    public void sendNotification(List<IdeaComment__c> comments, Map<Id,IdeaComment__c> newICMap)
    {
        
        List<String> ideaIds = new List<String>();        
        Messaging.SingleEmailMessage emailMessage;
        List<IdeaComment__c> currentComment = new List<IdeaComment__c>();
        Set<Id> targetObjectIds = new Set<Id>();
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        String emailBody = '';
        Idea_Environment_Url__c CS = Idea_Environment_Url__c.getOrgDefaults();
    
        String envUrl = CS.Url__c;
        String reviewerEmail = '';
        /*Set org wide email id for display name and email id*/
        String displayName = 'Akamai Wizards';
        String orgWideEmailId = '';
        
        /*Idea and comment Ids for the current comment*/       
        for(IdeaComment__c comment:comments)
        {
            ideaIds.add(comment.IdeaId__c);
        }
        
        //--------------------------------------------------------------------------------------
        //Updating the Number Of Comments field in Idea Object.
        //--------------------------------------------------------------------------------------
        Map<Id,Integer> ideasmap = new Map<Id,Integer>();        
        List<Idea> ideasToUpdate = [select Id, NumComments__c from Idea where id in :ideaIds];

        for(IdeaComment__c comment:comments){
            if(!ideasmap.containsKey(comment.IdeaId__c)){
                ideasmap.put(comment.IdeaId__c, 1);
            }
            else{
                ideasmap.put(comment.IdeaId__c, ideasmap.get(comment.IdeaId__c) + 1);
            }
        }

        for(Idea idea:ideasToUpdate)
        {
            if(idea.NumComments__c == null){
                idea.NumComments__c = 0;
            }
            idea.NumComments__c = idea.NumComments__c + ideasmap.get(idea.Id);
        }
        
        update ideasToUpdate;      
        //--------------------------------------------------------------------------------------
        //WizardsUtilClass.initializeMaps();
        
        currentComment = [select Id, CreatorName__c, ActualCreator__r.Name, IdeaId__r.Creator_Name__c, IdeaId__c, IdeaId__r.Project_Owner__c, IdeaId__r.Project_Owner__r.Name, IdeaId__r.Project_Owner__r.Email, IdeaId__r.CreatorName, IdeaId__r.ActualCreator__c, IdeaId__r.Title, CommentBody__c, ActualCreator__c, IdeaId__r.Idea_Sub_Category__c, IdeaId__r.Project_Type__c,IsDataLoad__c from IdeaComment__c where Id in :newICMap.keySet()];                      
        targetObjectIds = new Set<Id>();
        
        orgWideEmailId = [select Id from OrgWideEmailAddress where DisplayName = :displayName limit 1].Id;
        
        /*Send an email to the idea creator about the comment created if the owner of the idea has not commented*/
        for(IdeaComment__c curComment:currentComment)
        {
            /*If idea creator is not the commentor*/
            if(curComment.ActualCreator__c != curComment.IdeaId__r.ActualCreator__c && !curComment.IsDataLoad__c)
            {
                targetObjectIds.add(curComment.IdeaId__r.ActualCreator__c);
                emailMessage = new Messaging.SingleEmailMessage();
                emailBody = '<html><body>'+'Dear '+ curComment.IdeaId__r.Creator_Name__c +','+ '<br/><br/>';
                emailBody += 'There is a new comment for the idea '+'"'+curComment.IdeaId__r.Title+'"'+', '+'submitted by '+curComment.ActualCreator__r.Name+'<br/>';
                emailBody += '<br/>'+curComment.CommentBody__c+'<br/><br/>'+'To view the comment, use link - '+envUrl+'/idea/'+curComment.IdeaId__c+'<br/><br/>Best regards,<br/>Team Wizards<br/>akamai-wizards@akamai.com'+'</body></html>';
                emailMessage.setHtmlBody(emailBody);
                emailMessage.setSubject('Wizards Idea - New Comment');
                emailMessage.setTargetObjectId(curComment.IdeaId__r.ActualCreator__c);
                emailMessage.setSaveAsActivity(false);
                emailMessage.setOrgWideEmailAddressId(orgWideEmailId);
                //emailMessage.setSenderDisplayName(displayName);
                mailsToBeSent.add(emailMessage);
            }
            
            /*Send an email to the idea reviewer */
            if(curComment.IdeaId__r.Project_Owner__c != null && curComment.ActualCreator__c != curComment.IdeaId__r.Project_Owner__c && !curComment.IsDataLoad__c)
            {
                //WizardsUtilClass.initializeMaps();
                emailMessage = new Messaging.SingleEmailMessage();
                //reviewerEmail = WizardsUtilClass.userNameEmailId.get(curComment.Idea.Project_Owner__c);
                reviewerEmail = curComment.IdeaId__r.Project_Owner__r.Email;
                emailBody = '<html><body>'+'Dear '+curComment.IdeaId__r.Project_Owner__r.Name +','+ '<br/><br/>';
                emailBody += 'There is a new comment for the idea '+'"'+curComment.IdeaId__r.Title+'"'+', '+'submitted by '+curComment.ActualCreator__r.Name+'<br/>';
                emailBody += '<br/>'+curComment.CommentBody__c+'<br/><br/>'+'To view the comment, use link - '+envUrl+'/idea/'+curComment.IdeaId__c+'<br/><br/>Best regards,<br/>Team Wizards<br/>akamai-wizards@akamai.com'+'</body></html>';
                emailMessage.setHtmlBody(emailBody);
                emailMessage.setSubject('Wizards Idea - New Comment');
                
                System.debug('Reviewer email*** '+reviewerEmail);
                emailMessage.setToAddresses(new String[]{reviewerEmail});
                emailMessage.setOrgWideEmailAddressId(orgWideEmailId);
                //emailMessage.setSenderDisplayName(displayName);
                emailMessage.setSaveAsActivity(false);
                mailsToBeSent.add(emailMessage);
            }
        }
        System.debug('--** '+mailsToBeSent);
        /* ---- */
        
        emailBody = '';
        emailMessage = new Messaging.SingleEmailMessage();        

        /*Send an email to all the previous commentors */
        for(IdeaComment__c comment:[select Id, CommentBody__c, IdeaId__c, IdeaId__r.CreatorName, IdeaId__r.Project_Owner__c, IdeaId__r.ActualCreator__c, IdeaId__r.Title, ActualCreator__c, CreatorName__c from IdeaComment__c where IdeaId__c in :ideaIds and Id not in :newICMap.keySet()])
        {
            /*If the same person is commenting again or if previous commentor and reviewer are same do not send an email again */
            if(!targetObjectIds.contains(comment.ActualCreator__c) && comment.ActualCreator__c != currentComment[0].ActualCreator__c && comment.ActualCreator__c != comment.IdeaId__r.Project_Owner__c && !currentComment[0].IsDataLoad__c)
            {
                emailMessage = new Messaging.SingleEmailMessage();       
                targetObjectIds.add(comment.ActualCreator__c);                               
                emailBody = '<html><body>'+'Dear '+comment.CreatorName__c+','+ '<br/><br/>';
                emailBody += 'There is a new comment for the idea '+'"'+comment.IdeaId__r.Title+'"'+', '+'submitted by '+currentComment[0].ActualCreator__r.Name+'<br/>';
                emailBody += '<br/>'+currentComment[0].CommentBody__c+'<br/><br/>'+'To view the comment, use link - '+envUrl+'/idea/'+comment.IdeaId__c+'<br/><br/>Best regards,<br/>Team Wizards<br/>akamai-wizards@akamai.com'+'</body></html>';
                emailMessage.setHtmlBody(emailBody);
                emailMessage.setSubject('Wizards Idea - New Comment');
                emailMessage.setTargetObjectId(comment.ActualCreator__c);
                emailMessage.setSaveAsActivity(false);
                emailMessage.setOrgWideEmailAddressId(orgWideEmailId);
                //emailMessage.setSenderDisplayName(displayName);
                mailsToBeSent.add(emailMessage);
            }
        }
                               
        system.debug('***'+targetObjectIds);
        Messaging.sendEmail(mailsToBeSent);       
    }
}