public class PA_LegacyStreamingController{
    
    public String inputValue {get; set;}
    public String q1 {get; set;}
    public String q2 {get; set;}
    public String q3 {get; set;}
    public String q4 {get; set;}
    public String pa_id {get; set;}
    public Boolean iserr {get; set;}
    String country = null;
    

    
    public PA_LegacyStreamingController() {
    pa_id = System.currentPagereference().getParameters().get('id');
        for(Product_Approvals__c pa:[SELECT Id,Status__c,Workflow_ID__c From Product_Approvals__c Where ID=:pa_id]){
            if(pa.Status__c!='PENDING-TECHNICAL' || pa.Workflow_ID__c!='F-PAR-0100'){
                iserr=TRUE;
            }
        }
        
        
    }
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Yes','Yes')); 
        options.add(new SelectOption('No','No')); 
        return options; 
    }
    
    
    public PageReference processApproval(){
        System.debug('Q1'+q1);
        for(Product_Approvals__c pac:[select Id, Status__c,Approval_Workflow__c,Survey__c,Skip_Approval__c,Leagcy_Streaming_ans__c from Product_Approvals__c Where Id=:pa_id]){                
            //pac.Leagcy_Streaming_ans__c='What prevents the customer from moving to HD?'+'\r\n'+q1+'\r\n\r\n'+'When will the customer move to HD?'+'\r\n'+q2+'\r\n\r\n'+'Are additional Legacy Streaming formats being added?'+'\r\n'+q3+'\r\n\r\n'+'Is the customer going to grow capacity more than 10%?'+'\r\n'+q4+'\r\n\r\n\r\n';
            pac.Leagcy_Streaming_ans__c='What prevents the customer from moving to HD?'+'\r\n'+q1+'\r\n\r\n'+'When will the customer move to HD?'+'\r\n'+q2+'\r\n\r\n'+'Is the customer going to grow capacity more than 10%?'+'\r\n'+q3+'\r\n\r\n\r\n';
            if(q3=='No' ){
                pac.Status__c='APPROVED';
                pac.Skip_Approval__c=true;
                //pac.Leagcy_Streaming_ans__c='What prevents the customer from moving to HD?'+'\r\n'+q1+'\r\n\r\n'+'When will the customer move to HD?'+'\r\n'+q2+'\r\n\r\n'+'Are additional Legacy Streaming formats being added?'+'\r\n'+q3+'\r\n\r\n'+'Is the customer going to grow capacity more than 10%?'+'\r\n'+q4+'\r\n\r\n\r\n';
                pac.Leagcy_Streaming_ans__c='What prevents the customer from moving to HD?'+'\r\n'+q1+'\r\n\r\n'+'When will the customer move to HD?'+'\r\n'+q2+'\r\n\r\n'+'Is the customer going to grow capacity more than 10%?'+'\r\n'+q3+'\r\n\r\n\r\n';
                update pac;
                return new PageReference('/'+pac.Id);
            } 
            update pac;
            return new PageReference('/apex/TakeSurvey?id='+pac.Survey__c+'&productApprovalId='+pac.Id);
        }
        return null;
    }
        
}