/* 
Template: Apex Class/Trigger Template

CopyRight: Vidhya Dessai @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 17/10/2014

Base Line : Used as controller for HD_FeedbackSurveyPage

Purpose : Used as controller for HD_FeedbackSurveyPage
          
Usage :  saves the survey response into HD+Survey__c object
          
Class/Trigger Asssociated : NONE

Controller (Boolean): True

Page Used/Asssociated (default -> NONE) : HD_FeedbackSurveyPage

Other Component Used : HD_Survey__c (Custom Object)

*/ 
// Changes done for CR 2994518 - HD_FeedbackSurveyPage.page violates sharing setting by Hemant Kumar
// Added with sharing keyword to enforce sharing rules 
public with sharing class HD_FeedbackSurveyController
{
    // changes done for CR 2994518 - HD_FeedbackSurveyPage.page violates sharing setting by Hemant Kumar
    public static boolean isSubmitted{get;set;} static{ isSubmitted=false;
                                          if(ApexPages.currentPage().getParameters().get('sid')!=null && ApexPages.currentPage().getParameters().get('incident')!=null )
                                          {
                                           List< BMCServiceDesk__Incident__c > incident = [SELECT Name,BMCServiceDesk__FKClient__c,BMCServiceDesk__Client_Name__c FROM BMCServiceDesk__Incident__c  WHERE ID= :ApexPages.currentPage().getParameters().get('incident')];
                                           Integer sidnum=[SELECT count() FROM HD_Survey__c WHERE Survey_Id__c = :ApexPages.currentPage().getParameters().get('sid')];
                                           Integer num=[SELECT count() FROM HD_Survey__c WHERE Incident_name__c = :ApexPages.currentPage().getParameters().get('incident')];
                                           if(num>0 || sidnum>0 || (UserInfo.getUserId() != incident[0].BMCServiceDesk__FKClient__c))
                                              isSubmitted=true;
                                          }
                                          }
    public string message {get;set; }
    
    public List<String> fields = new List<String> {'Satisfaction_To_Resolution__c','First_Time_Issue__c','Communication_Followup__c','Satisfaction_To_Experience__c','NPS__c','Comments__c','Difficulty_of_Help__c','Discuss__c'};
   
    public List<Integer> sizeList{get;set;}
    
    public Map<string,List<SelectOption>> optionLists { get;set;}
    
    public Map<string,string> response {get;set;}
    
    public HD_FeedbackSurveyController()
    {
         
           
           optionLists=new Map<string,List<SelectOption>>();
           sizeList=new List<Integer>();
           for(Integer index=0;index<fields.size();index++){
             if(fields[index]!='Comments__c'){
               List<SelectOption> tempList=getPicklistValues('HD_Survey__c',fields[index]);
               optionLists.put(fields[index], tempList);
               sizeList.add(tempList.size()); 
             }else
               sizeList.add(0);              
          }
          //set default values
          response=new Map<string,string>();
          response.put('Satisfaction_To_Resolution__c','Yes');
          response.put('First_Time_Issue__c','Yes');
          response.put('Communication_Followup__c','5');
          response.put('Satisfaction_To_Experience__c','5');
          response.put('NPS__c','5');
          response.put('Discuss__c','Yes');
          response.put('Difficulty_of_Help__c','Yes');
          response.put('Comments__c','');
              // START changes done for CR 2994518 - HD_FeedbackSurveyPage.page violates sharing setting by Hemant Kumar
          List< BMCServiceDesk__Incident__c > incident = [SELECT Name,BMCServiceDesk__FKClient__c,BMCServiceDesk__Client_Name__c FROM BMCServiceDesk__Incident__c  WHERE ID= :ApexPages.currentPage().getParameters().get('incident')];
          if(incident.size() > 0)
          {
              if(UserInfo.getUserId() != incident[0].BMCServiceDesk__FKClient__c )
              {
              message = 'The Following Survey for Incident '+incident[0].Name+' is not valid for you !';
              }
              else
              {
              message='Thank You!! Your Feedback for Incident '+incident[0].Name+' has been submitted successfully.';  
              }//else
          }
            // END changes done for CR 2994518 - HD_FeedbackSurveyPage.page violates sharing setting by Hemant Kumar
           
    }//    public HD_FeedbackSurveyController()

    public HD_FeedbackSurveyController(ApexPages.StandardController controller)
    {
          
    }

    public static List<SelectOption> getPicklistValues(String ObjectApi_name,String Field_name){ 

           List<SelectOption> lstPickvals=new List<SelectOption>();
           Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);//From the Object Api name retrieving the SObject
           Sobject Object_name = targetType.newSObject();
           Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
           Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
           Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
           List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
           for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
           string temp=a.getLabel();
           if(a.getLabel()=='1')  temp='Less-1';
           if(a.getLabel()=='10')  temp='10-More';
           lstPickvals.add(new SelectOption(a.getValue(),temp));//add the value  to our final list
       }
       return lstPickvals;
    }

    public Boolean validate(){
    

        string incidentParam=ApexPages.currentPage().getParameters().get('incident');
        string sidParam=ApexPages.currentPage().getParameters().get('sid');
        if(incidentParam==null ||sidParam==null){
              string paramMsg='This page requires incident and survey ID parameters.To submit survey please click on the survey link sent through email.';
              ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,paramMsg));
              return false;
        } 
       
        String requiredMsg='This question requires an answer!!';
       
        if( (response.get('Satisfaction_To_Resolution__c')  ==null) || (response.get('First_Time_Issue__c')==null) || (response.get('Communication_Followup__c')==null) || (response.get('NPS__c')==null) ||(response.get('Discuss__c')==null)) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,requiredMsg));
           return false;
        }
        return true;
        
    }
    public PageReference save()
    {
        
          if(!validate())
             return null;

           HD_Survey__c surveyRecord=new HD_Survey__c();
           surveyRecord.Satisfaction_To_Resolution__c=response.get('Satisfaction_To_Resolution__c');
           surveyRecord.First_Time_Issue__c= response.get('First_Time_Issue__c');
           surveyRecord.Communication_Followup__c=response.get('Communication_Followup__c');
           surveyRecord.Satisfaction_To_Experience__c= response.get('Satisfaction_To_Experience__c');
           surveyRecord.NPS__c= response.get('NPS__c');
           surveyRecord.Discuss__c= response.get('Discuss__c');
           surveyRecord.Difficulty_of_Help__c= response.get('Difficulty_of_Help__c');
           surveyRecord.Comments__c= response.get('Comments__c');
           
           surveyRecord.Incident_Owner__c =[SELECT HD_Owner_user_queue__c FROM BMCServiceDesk__Incident__c  WHERE ID= :ApexPages.currentPage().getParameters().get('incident')].HD_Owner_user_queue__c;
           surveyRecord.Incident_name__c =ApexPages.currentPage().getParameters().get('incident');
           surveyRecord.Survey_Id__c =ApexPages.currentPage().getParameters().get('sid');
           try{
             insert surveyRecord;
            // ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Feedback Submitted Successfully.Thank you!'));
              isSubmitted=true;
           }catch(DMLException e){
            // ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Record creation failed: ' + e.getMessage()));
            message='Error Occurred while saving your Feedback Response';
          }
          
         
          return null; 
       
    }

    public PageReference closeSurvey(){
       String redirectURL='https://helpdesk.akamai.com';
       String currentURL=ApexPages.currentPage().getHeaders().get('Host');
       if(currentURL.contains('akamai--p2rdev')||currentURL.contains('akamai--p2rtest')||currentURL.contains('akamai--qa'))
          redirectURL='/apex/BMCServiceDesk__sslandingpage';
       return new PageReference(redirectURL);
    }
}