public class PA_Transcoding_Controller {

    public String acct_id {get; set;}
    public String op_name {get; set;}
    public String Acct_name {get; set;}
    public String opp_name {get; set;}
    public String owner {get; set;}
    public Product_Approvals__c pac{get; set;} 
    public Approval_Workflow__c awc { get; set;}
    public CP_Chatter_Pulse__c cpc{get; set;}
    public String[] SelectedApprovals = new String[]{};
    public ProductApprovalCS__c pa= ProductApprovalCS__c.getInstance('TranscodingApprovalWF');
   

    public PA_Transcoding_Controller() {
    
        pac=new Product_Approvals__c();
        cpc=new CP_Chatter_Pulse__c();
        acct_id = System.currentPagereference().getParameters().get('acct_id');
        owner = System.currentPagereference().getParameters().get('owner');
        op_name = System.currentPagereference().getParameters().get('op_name');
        
        for(Account acctdetails:[SELECT Id, Name FROM Account WHERE Id = :acct_id])
        { 
        
        Acct_name=acctdetails.Name;
        
        }
        for(Opportunity oppdetails:[SELECT Id, Name FROM Opportunity WHERE Id = :op_name])
        { 
        
        opp_name=oppdetails.Name;
        
        }
        for(AccountTeamMember atm :[select AccountId, Id, TeamMemberRole, UserId FROM AccountTeamMember where AccountId = :acct_id and TeamMemberRole= 'Technical Sales - Primary' ])
        {
            cpc.Chatter_User__c=atm.UserId;
           
        }
        init();
    }

    public void init()
    {
    
        pac.Opportunity_Owner__c=owner;
        
        pac.Account__c=acct_id;
        
        pac.Creator__c=UserInfo.getUserId();
        
        pac.Opportunity__c=op_name; 
        
        pac.isTranscoding__c=TRUE;
        
        pac.Escalation_Status__c='NEW';
        
        
        
        RecordType rt = [select Id,Name from RecordType where Name = 'Transcoding Approval' and SobjectType = 'Product_Approvals__c'];
       if(rt !=null)
       {
       
            pac.RecordTypeId = rt.Id;
        }
        Datetime cDT = System.now();          
      
    }


    public PageReference save() {
    for(Approval_Workflow__c approval : [SELECT Id, Name , Survey__c FROM Approval_Workflow__c WHERE Id= :pa.Value__c])
    {
     String PAname = approval.Name+ ' Approval for '+Acct_name;
      pac.Survey__c=approval.Survey__c;
       pac.Escalation_Status__c='NEW';
       pac.Approval_Workflow__c =approval.Id;
        if(PAname.length() > 79)
      {
         pac.name= PAname.substring(0, 79);
       }
       else
       {
       pac.name= PAname;
      }
       }
     
       
       if(cpc.Chatter_User__c!=null){
           pac.User_Technical__c=cpc.Chatter_User__c;
       } 
      else
        {
                  pac.User_Technical__c=owner; 
         }
         INSERT pac; 
         return new PageReference('/'+pac.Id);             
    }
    
     public PageReference save_survey() {  
     for(Approval_Workflow__c approval:[SELECT Id, Name , Survey__c FROM Approval_Workflow__c WHERE Id= :pa.Value__c])
     {
     String PAname = approval.Name+ ' Approval for '+Acct_name;//+cDt.day()+'-'+cDt.month()+'-'+cDt.year();
      pac.Survey__c=approval.Survey__c;  
      pac.Escalation_Status__c='NEW';    
       if(PAname.length() > 79)
      {
         pac.name= PAname.substring(0, 79);
       }
       else
       {
       pac.name= PAname;
      }
        pac.Approval_Workflow__c =approval.Id; 
     }
          pac.isUserTSP__c=TRUE; 
           if(cpc.Chatter_User__c!=null){
               pac.User_Technical__c=cpc.Chatter_User__c;
           } 
          else
            {
                  pac.User_Technical__c=owner; 
             }
          INSERT pac;
          return new PageReference('/apex/TakeSurvey?id='+pac.Survey__c+'&productApprovalId='+pac.Id);
     }
     
     public PageReference cancel() {
     
         return new PageReference('/'+acct_id);
         
     }

}