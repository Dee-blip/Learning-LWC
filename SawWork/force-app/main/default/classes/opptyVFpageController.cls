/*
Controller is created for the MarkAsOpportunityPage and OpptyValidatePage 
<Description>: Controller has logic for Automatically generating  the links for the flow present in the vIsualOppty Custom Setting to display to the 
               User in Oppty Operations and Sales Page Layout. Also It has the Visual flows functionality that is there in the page.
<Author> : Rahul Gaira (rgaira@akamai.com)
<Created date>: 20/10/2014
 -----------------------------------------------------------------------------------------------
 Ruchika Sharma    29/08/2016    SFDC-1147 - show less visual force links for new product wizard pilot user
 */             
public class opptyVFpageController{
    // flag is  used to Render and rerender the opptyLineItem Section
    public boolean Flag{get; set;}
    // Getting and Setting the Flows in Page
    public Flow.Interview.Update_Renewal_Opportunity_as_Churn updateChurnFlow{ get; set; }
    public Flow.Interview.Changing_a_System_Generated_Opportunity_from_a_Churn SysGenOppToChurn{get;set;}
   // public Flow.Interview.Customer_does_not_have_an_Auto_Renewal_Clause AutoRenewal{get;set;}
    Id newPageopptyId{get ;set;}
  // public boolean AggregatePartnerFlag{get;set;}
    //Storing the OpportunityLineItem List
    public List<OpportunityLineItem> oliList{get;set;}
    public string FlowName{get; set;}
    //Storing the Opportunity Record
    public  Opportunity oppty{get;set;}
   // public String Subcategory{get;set;}
    public String  lossReason{get;set;}
    //Boolean flag to render and Rerender the saveOli and Save Oli alonng with Oppty
    public Boolean VisualFlow6{get;set;}
    Map<String,VisualFlowOppty__c> customSetting = new Map<String,VisualFlowOppty__c>();
    List<wrapperClass> wrapperList = new List<wrapperClass>();
    public List<wrapperClass> pilotWrapperList{get;set;}
    public static String aggval{get ; set;}
  // public static String lossReasonExcep{get ;set;}
   // public boolean ConsolidationAccFlag{get;set;}
    public boolean InitialOutClauseFlag{get;set;}
    public boolean MissingFeatureFlag{get;set;}
    public Boolean UnAcceptableTermFlag{get;set;}
     //Sonali Tandon- CR 2875296-Visual Flow Monitoring - Details of launched flow 
   // public String trackerFlowName {get;set;}
   // public String trackerTimeStamp {get;set;}
    public String varCurrentUserID {get;set;}
    //public String vCurrentUserID {get;set;}
    public Id opptyId;
    public Id flowTrackerId{get;set;}
    public Boolean isPilotUser{get;set;}
   
    public  void setWrapperList(List<wrapperClass>  wrapperList) {
        wrapperList = wrapperList;
        }
    
     public List<WrapperClass> getWrapperList(){
        return WrapperList;
    }
   
   // Constructor  called  While using the  custom Controller in Page
    public opptyVFpageController() {
         newPageopptyId = Apexpages.currentpage().getparameters().get('Id'); 
         FlowName = Apexpages.currentpage().getparameters().get('Name');      
         if(newPageopptyId != null && !String.isBlank(newPageopptyId)) {
              newPageopptyId = ID.valueOf(String.escapeSingleQuotes( String.valueOf(newPageopptyId).escapeHtml4()));
         }
         if(FlowName != null && !String.isBlank(FlowName)) {
             FlowName = String.escapeSingleQuotes(FlowName.escapeHtml4());
         }


         if(flowName == Label.not_having_auto_renewal_clause) {
           VisualFlow6 = false;
         }else {
           VisualFlow6 = true;
         }
         if(newPageopptyId != null) {
         oppty = [Select Id, name , Partner_Involved__c, Opportunity_Category__c,Consolidation_Account__c, Aggregation_Partner__c ,Competitor__c ,
                 Churn_No_Paper__c, Loss_Reason__c ,(SELECT Id, PricebookEntryId, PricebookEntry.Name, MRR__c, Forecast_Group__c,
                 UnitPrice, NRR__c from OpportunityLineItems) From Opportunity Where Id =: newPageopptyId limit 1];
          }
          
          if(oppty != null  ){
           oliList= oppty.opportunityLineItems;
          }
         
          If(OLiList == null || OLiList.isEmpty()){
             Flag = true;
           }
     }
    
    //Constructor called While using the Extension Controller
    public opptyVFpageController(ApexPages.StandardController controller) {
    
        opptyId = controller.getRecord().Id;
        isPilotUser = false;
        pilotWrapperList = new List<wrapperClass>();
        customSetting = VisualFlowOppty__c.getAll();
        String visualFlowsNameToExcludeForPilot = GsmUtilClass.getGSMSettingValue('VisualFlowsNameToExcludeFor_Pilot');

        if(!CustomSetting.isEmpty()){
        String tempvalue ;
          for(VisualFlowOppty__c vw : customSetting.values()) {
             WrapperClass wr = new WrapperClass();
             if(vw.IsActive__c){
                 if(!vw.Is_it_a_Page__c) {
                     tempvalue = '/flow/'+vw.value__c+'?Id='+opptyId+'&retURL='+opptyId +'&varCurrentUserID='+System.UserInfo.getUserId();
                     }
              else{
                  tempvalue = '/apex/'+vw.value__c+'?Id='+opptyId+'&Name='+vw.Name+'&retURL='+opptyId + '&varCurrentUserID='+ System.UserInfo.getUserId();
                    }    
                 wr.name = vw.FullName__c;
                 wr.value = tempvalue;
                 wr.ListOrder = (Integer)vw.List_Order__c;
                 //SFDC-1147 - show less visual force links for new product wizard pilot user
                 //SFDC-1952 - Lesser links be shown to all users.
                 if(GsmUtilClass.getGSMSettingValue('Product_Wizard_GA_Toggle').containsIgnoreCase('true')){
                  if(!visualFlowsNameToExcludeForPilot.contains(vw.Name)){
                    isPilotUser = true;
                    pilotWrapperList.add(wr);
                  }
                 }
                 else
                  wrapperList.add(wr);
                 }
             
              }
              System.debug('pilotWrapperList: '+pilotWrapperList);
              System.debug('isPilotUser: '+isPilotUser);
         }
    }
    //Wrapper Class Storing the Details for creation of the flow
    public class wrapperClass{
       public String Value{get;set;}
        public String Name{get;set;}
        public Integer ListOrder {get;set;}
        
    }
    
    //Save functionality for only updating the OLI from the page
    public void SaveOli(){
      if(OLiList != null && !OLiList.Isempty()){
        for(OpportunityLineItem oli : OliList) {
            oli.Quantity__c =0;
          if(oli.UnitPrice == null ){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please use a valid number format in the "MRR" field. (e.g. 1000, 62.50)'));
             return;
          }
       }
        try{
        
         update OLiList; 
         // flag = true;
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'MRR values are updated'));
          } catch(exception e) {
             // ApexPages.addMessages(e);
             flag= false;
           }
        }
    }
      // }
       
   
   //Save functionality for saving the page along with the flow
   public  PageReference saveOLiAndOppty(){
    PageReference ref = null;
         System.debug('in oli' +flowTrackerId);
     if (FlowName == System.Label.not_having_auto_renewal_clause) {
        if(validate()){
           if(oliList != null && !oliList.isEmpty()){
            //update OliList;
            for(OpportunityLineItem oli : OliList) {
               oli.Quantity__c =0;
               if(oli.UnitPrice == null ) {
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please use a valid number format in the "MRR" field. (e.g. 1000, 62.50)'));
                  return null;
                  }
              }
            try {  
                update OLiList; 
              } catch(exception e) {
              //China PAE expection<CR-2864811 Added the line of code>
                  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                  }
            }
              oppty.Churn_No_Paper__c = True;
              //Sonali Tandon-CR 2925624 - Update success flag on flow tracker detail on completion of flow
              Flow_Tracker_Detail__c flowTrackDetailObj = new Flow_Tracker_Detail__c();
              if(flowTrackerId!=null)
                flowTrackDetailObj= [Select Success__c from Flow_Tracker_Detail__c where Id =: flowTrackerId];
              if(flowTrackDetailObj!= null){
              flowTrackDetailObj.Success__c = true;}
              
             try{
                 update oppty;
                 if(flowTrackDetailObj!=null)
                     update flowTrackDetailObj;
                 
                 ref = new PageReference('/'+oppty.Id);
             }
             catch(exception e){
             //China PAE expection<CR-2864811 Added the Piece  of code>
                 if(e.getMessage().contains('after the Opportunity has been closed')) {
                    // lossReasonExcep ='Missing Product';
                    String errMessage = GsmUtilClass.GetCustomSettingValue('OpptyVfPageController#ClosedOppty');
                    if(errMessage != null && errMessage != ''){
                      ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errMessage);
                      ApexPages.addMessage(errMsg);
                      }
                  }   else{
                      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                  }         
              }  

          }  
       }
       
       
       return  ref;
   }
   
   // Next Button to be not used anywhere
   public void Next(){
        flag = true;
       // oliListFlag = False;
    }
    
    
    // generating the return URL for the end of the flow
    public PageReference getPageA() {
        return new PageReference('/'+newPageopptyId);
    }
    

    // Creating the subCategory Option for creating the custom PickList Option for the Oppty 
  /*  public List<SelectOption> getSubCategoriesOptions() {
        List<SelectOption> Options = new List<SelectOption>();
        Options.add(new SelectOption('--- None ---','--- None ---'));
        Options.add(new SelectOption('Aggregation through a Partner (Pick Partner)','Aggregation through a Partner (Pick Partner)'));
        Options.add(new SelectOption('Contract Consolidation with Akamai Customer','Contract Consolidation with Akamai Customer'));
        Options.add(new SelectOption('Lost Customer','Lost Customer'));
        return Options;
    } 
    */
    // Creating Dynamic PicKlist Option for creating the  Loss/Cancellation reason Picklist
     public List<SelectOption> getLossOptions() {
        List<SelectOption> options = new List<SelectOption>();
       /* if(Subcategory == 'Aggregation through a Partner (Pick Partner)')
        {       
            options.add(new SelectOption('Aggregation through a Partner (Pick Partner)','Aggregation through a Partner (Pick Partner)'));
            //AggregatePartnerFlag = true;
        }
        else if(Subcategory == 'Contract Consolidation with Akamai Customer')
        {       
            options.add(new SelectOption('Contract Consolidation with Akamai Customer','Contract Consolidation with Akamai Customer'));
           // AggregatePartnerFlag = false;
        } 
            if(Subcategory == 'Lost Customer'){ */
            List<VF_Oppty_CancellationLostReason__c> cancellationPickList  = VF_Oppty_CancellationLostReason__c.getAll().Values();
             Options.add(new SelectOption('--- None ---','--- None ---'));
             for(VF_Oppty_CancellationLostReason__c  customSett : cancellationPickList ){
                options.add(new SelectOption(customSett.value__c, customSett.value__c));
            }
      /*  }    
        else{
         options.add(new SelectOption('--- None ---','--- None ---'));
         //AggregatePartnerFlag = false;
         
         }  */    
        return options;
    }      
    
    //Creating the some validation Check for the field in the Visual Force page 
    public boolean validate() {
     Boolean  var;
        if (FlowName == System.Label.not_having_auto_renewal_clause) { 
          
         /*  If(oppty.Competitor__c == null || oppty.Competitor__c== ''){
             // Apex error 'Competitor can not be Empty for Marking it as Churn'
             ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, GsmUtilClass.GetCustomSettingValue('OpptyVFpage#error2'));
                     ApexPages.addMessage(errMsg);
             var = false;
          } */
         if(lossReason == null || lossReason =='--- None ---'){
              //Apex Error ''Category ,SubCategory can not be Empty Or --- None--- for Marking it as Churn''
              ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR,  GsmUtilClass.GetCustomSettingValue('OpptyVFpage#error3'));
              ApexPages.addMessage(errMsg);
              var = false;
          } 
          else{
           var = true;
          }
    }
    return var;
 }
 /* public void renderAggregateFlag(){
            InitialOutClauseFlag = false;
               MissingFeatureFlag = false;
               UnAcceptableTermFlag= false;
     if(Subcategory != null){
         if(Subcategory =='Aggregation through a Partner (Pick Partner)'){
             ConsolidationAccFlag = false;
             AggregatePartnerFlag = True;
            
         }
         if(Subcategory=='Contract Consolidation with Akamai Customer'){
              AggregatePartnerFlag = false;
              ConsolidationAccFlag = true;
                
         }
         if(Subcategory=='Lost Customer' ||Subcategory=='--- None ---' ){
             AggregatePartnerFlag = false;
             ConsolidationAccFlag = false;
         }
     } 
 }*/
     public void checkLossReason(){
          InitialOutClauseFlag = false;
           MissingFeatureFlag = false;
          UnAcceptableTermFlag= false;
          if(lossReason != null){

           // SFDC-3256 - Agility2.0 - Updating Loss reasons, Removing Subcategory, Unacceptable, Initial Out and Missing product feature fields     
             if(lossReason =='Competition - Features/Performance' || lossReason =='Missing Product Feature') {
                  MissingFeatureFlag = true;
               }

            // if(lossReason =='Will not accept Akamai Terms and Conditions'){
            //     UnAcceptableTermFlag= true;

            // }
            // if(lossReason =='Initial Out Clause'){
            //    InitialOutClauseFlag = true;
            //}
         }
     }
 //Sonali Tandon- CR 2875296- Visual flow monitoring
   public void FlowDetail()
   {
      //CR 2925624
      if (FlowName == System.Label.not_having_auto_renewal_clause)
      {
        //get flow name 
        String flowFullName = VisualFlowOppty__c.getValues(flowName).FullName__c;
        //get current oppty's AKAM-ID 
         Opportunity oppAkamId = [Select AKAM_Opportunity_ID__c from Opportunity where Id =:newPageopptyId];
        Flow_Tracker__c flowTrackObj = new Flow_Tracker__c();
        flowTrackObj =  [Select Id from Flow_Tracker__c where Name =: flowFullName];
          if(flowTrackObj!=null){
            Flow_Tracker_Detail__c flowTrackDetailObj = new Flow_Tracker_Detail__c(Flow_Name__c=flowTrackObj.Id, Running_User__c =System.UserInfo.getUserId(), Run_Date_Time__c= System.now(), Opportunity_Name__c=newPageopptyId,Opportunity_AKAM_ID__c=oppAkamId.AKAM_Opportunity_ID__c);
            try
            {
              insert flowTrackDetailObj;
              flowTrackerId = flowTrackDetailObj.Id;
            }
    
            catch(Exception e)
            {
                  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
         }
      }
    }


     //Sonali Tandon -CR 2841078 - Visual WF 4.2: Add Opportunity product
     public PageReference opptyProdRedirect() {
      String Prefix = '/apex/ValidateOppty?addTo=';
      PageReference validateOpptyPage = new PageReference(Prefix+oppty.Id+'&id='+oppty.Id+'&sfdc.override=1'+'&flow=yes');
          validateOpptyPage.setRedirect(true);
      return validateOpptyPage;
    }
    //Sonali Tandon -CR 2841078 - Visual WF 4.2: Add Opportunity product
}