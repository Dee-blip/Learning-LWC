public class RSSCloneController {

     public boolean displayPopup {get; set;} 
     String RSSFormId;     
    
    public void closePopup() {        
        displayPopup = false;    
    }     
    public void showPopup() {        
        displayPopup = true;    
    }
    
 public PageReference CloneRSSForm() {
        
        List<String> TempList = new List<STring>();
        
        if(chosenList.size() <1)
         {
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select atleast one Product from the avaliable list'));
             return NUll;
         }
         
        for(SelectOption so:chosenList)
        {
            TempList.add(so.getValue());
        }
        RSS_Form__c newForm = new RSS_Form__c();
       
        newForm.Name = RSSForm.Name;
        newForm.UniqueName__c = GuidUtil.NewGuid();
        newForm.Published__c = false;
        newForm.Locked__c = false;
        newForm.AEName__c = RSSForm.AEName__c;
        newForm.DigitalProperty__c = RSSForm.DigitalProperty__c;
        newForm.Account__c = RSSForm.Account__c;
        insert newForm;

        RSSUtility.cloneRSSFromWithResponse(TempList,newForm.Id,RSSFormId);
        return new PageReference('/apex/RSSForm?id='+newForm.Id);
       
    }

public RSS_Form__c RSSForm {get; set;}  
public List<selectOption> availableList 
{
    get;
    set;
}
public List<selectOption> chosenList 
{
    get
    {
        if(chosenList ==null)
        {
            chosenList = new List<selectOption>();
            /*availableList.add(new selectOption('DSA','DSA');
            availableList.add(new selectOption('Aqua Ion','Aqua Ion');
            availableList.add(new selectOption('Product 1','Product 1');
            availableList.add(new selectOption('Product 2','Product 2');        */
        }
        return chosenList;
    }
    set;
} 
public RSSCloneController()
{

 RSSFormId =  Apexpages.currentPage().getParameters().get('id');
 
 for(RSS_Form__c rf:[select id, Name, AEName__c,Version__c, DigitalProperty__c,Account__c from RSS_Form__c where id=:RSSFormId limit 1])
 {
     RSSForm = rf;
 }
 
 RSSForm.Name = '';
 RSSForm.Account__c = NULL;
 List<SurveyTaker__c> forms = [select id,Survey__r.Name,Survey__c from SurveyTaker__c where RSS_Form__c = :RSSFormId  order by Survey__r.Name];
    Map<String,String> chosenListFormNames = new Map<String,String>();
    chosenList = new List<SelectOption>();
    availableList = new List<SelectOption>();
    for(SurveyTaker__c st:forms)
    {
        chosenList.add(new SelectOption(st.Survey__c,st.Survey__r.Name));
        chosenListFormNames.put(st.Survey__r.Name,st.Survey__r.Name);
        
    }
    for(Survey__c s:[select name,Id,Owner.Name,Version__c,UniqueName__c from Survey__c where id!=null and recordType.Name = 'RSS Template'and RSS_Published__c = true Order by Name Desc NULLS LAST limit 5000 ])
    {
        if(chosenListFormNames.get(s.Name)==null)
        availableList.add(new selectOption(s.Id,s.Name));                 
    }
}
}