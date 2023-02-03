/* ========================================================================
    Author: Sonia Sawhney
    Description: Test Class for WizardsIdeaTrigger
    Created Date : 10/04/2014
    Modification History:
    1. sswhney on 16/12/2014 CR 2869635
    ======================================================================== */
@isTest
public class WizardsIdeaTriggerTest
{    
    public static Idea objIdea;
    
    public static testMethod void testIdeaCreation() {
        /*Start of changes by janantha for CR 2869698*/
        objIdea = WizardsInitData.createIdea(); 
        /*End of changes by janantha for CR 2869698*/       
        Idea tmpIdea = [Select Idea_Number__c, Feedback__c  from Idea where Id = :objIdea.Id];
        System.assert(tmpIdea.Idea_Number__c != null);

        objIdea.Idea_Number__c = '';
        update objIdea;
        
        tmpIdea.Feedback__c = 'f1';
        update tmpIdea;
        System.assert(tmpIdea.Feedback__c == 'f1');
        
        tmpIdea = [Select Idea_Number__c  from Idea where Id = :objIdea.Id];
        System.assert(tmpIdea.Idea_Number__c != null);
    }

    public static testMethod void testIdeaVote() {

        //creating idea for test
        objIdea = WizardsInitData.createIdea();
        Idea tmpIdea = [select Id, Idea_Number__c from Idea where Id = :objIdea.Id];
        System.assert(tmpIdea.Idea_Number__c != null);

        //up voting idea
        Vote__c ideaUpVote = new Vote__c();
        ideaUpVote.Type__c = 'Up';
        ideaUpVote.ActualCreator__c = [select Id from User where alias = 'ssanji' limit 1].Id;
        ideaUpVote.ParentId__c = tmpIdea.Id;
        insert ideaUpVote;
        System.assert(ideaUpVote.Id != null);

        //same user down vote idea
        Vote__c ideaDownVote = new Vote__c();
        ideaDownVote.Type__c = 'Up';
        ideaDownVote.ActualCreator__c = [select Id from User where alias = 'ssanji' limit 1].Id;
        ideaDownVote.ParentId__c = tmpIdea.Id;
        insert ideaDownVote;
        System.assert(ideaDownVote.Id != null);

    }

    public static testMethod void testMail() {
        //creating and fetching Idea
        objIdea = WizardsInitData.createIdea();
        Idea tmpIdea = [Select Idea_Number__c, Feedback__c  from Idea where Id = :objIdea.Id];
        System.assert(tmpIdea.Id != null);

        //changing project type
        tmpIdea.Project_Type__c = 'pr1';
        update tmpIdea;
        System.assert(tmpIdea.Project_Type__c == 'pr1');

        //changing Sponsor 
        tmpIdea.Sponsor__c = UserInfo.getUserId();
        update tmpIdea;
        System.assert(tmpIdea.Sponsor__c == UserInfo.getUserId());

        //changing sponosor notes
        tmpIdea.Sponsor_Notes__c = 'test notes';
        update tmpIdea;
        System.assert(tmpIdea.Sponsor_Notes__c == 'test notes');

    }
   
  public static testMethod void testPopulateOwner(){
      objIdea = WizardsInitData.createIdea();
      Idea tmpIdea = [Select Idea_Number__c, Project_Type__c,Idea_Sub_Category__c  from Idea where Id = :objIdea.Id];
      System.assert(tmpIdea.Id != null);

      tmpIdea.Project_Type__c = 'Sales';
      tmpIdea.Idea_Sub_Category__c = 'Sales';
      update tmpIdea; 
       
      List<Idea_Reviewer__c> tmpIdeaReviewerList = new List<Idea_Reviewer__c>();
       
      Idea_Reviewer__c tmpData1 = new Idea_Reviewer__c();
      tmpData1.name = 'Sales/Sales';
      tmpData1.Category__c = 'Sales';
      tmpData1.Sub_Category__c = 'Sales';
      tmpData1.Current_Index__c = 0;
      tmpData1.Reviewer_List__c = '005A0000000Mvf9IAC,005A0000000MuuuIAC';
      tmpIdeaReviewerList.add(tmpData1);
       
      Idea_Reviewer__c tmpData2 = new Idea_Reviewer__c();
      tmpData2.name = 'ETG/EPQM';
      tmpData2.Category__c = 'Edge Technology Group';
      tmpData2.Sub_Category__c = 'Edge Performance and Quality Management';
      tmpData2.Current_Index__c = 0;
      tmpData2.Reviewer_List__c = '005G0000003DIDvIAO,005A0000000MuuuIAC';
      tmpIdeaReviewerList.add(tmpData2);
       
      insert tmpIdeaReviewerList;
      for(Idea_Reviewer__c reviewItem : tmpIdeaReviewerList){
          List<String> idList = reviewItem.Reviewer_List__c.split(',');
          Integer count = idList.size();
          if(reviewItem.Category__c == 'Edge Technology Group' && reviewItem.Sub_Category__c == 'Edge Performance and Quality Management'){
              tmpIdea.Project_Owner__c = idList[reviewItem.Current_Index__c.intValue()]; 
              reviewItem.Current_Index__c = Math.mod(reviewItem.Current_Index__c.intValue()+1,count);
          }
       }
      update tmpIdea;
      System.assert(tmpIdea.Project_Owner__c != null);
    }

    public static testMethod void diffLdapTest() {
        //testing non webservice functions
        WizardsIdeaTriggerClass obj = new WizardsIdeaTriggerClass();
        Map<String,String> test = obj.diffLdaps('JK,GH,IL', 'JK,GH,UY');

        objIdea = WizardsInitData.createIdea();
        obj.SearchTagBuilder(new List<Idea>{objIdea});

        Map<String,Id> testMap = new Map<String,Id>();
        testMap.put('test', UserInfo.getUserId());

        objIdea.Team_Members__c = 'MPADAKAN,VT';
        obj.getTeamMember(testMap, objIdea);

    }

    public static testMethod void sponsorChangeTest(){

        objIdea = WizardsInitData.createIdea();
        objIdea.Sponsor__c = UserInfo.getUserId();
        update objIdea;

        String alias = 'nakodand';
        String nakodandId = [select Id from User where alias =: alias limit 1].Id;
        objIdea.Sponsor__c = nakodandId;
        update objIdea;

    }

}