/* Author   : Vamsee
   Date     : 19th July 2016
   Purpose  : This class is to create the Special Instruction[CR : 3470841]
*/
public class SC_SpecialInstructionTemplateCtrl {
    //variable to store the Account Id
    public string accountId;
    
    //This is to store the Special Instruction ID which is required for Edit section
    public string specialInstructionId;
    
    //This is used in VF page to get the value of selected template
    public string templateTitle{get;set;}
    
    //This is to Display Title of the template on VF page 
    public string titleOutputText{get;set;}
    
    //This is to Display Show for Record types of the template on VF page
    public string recordTypesOutputText{get;set;}
    
    //This is to Display Instructions of the template on VF page
    public string instructionsOutputText{get;set;}
    
    //This is to Display Flag Icon of the template on VF page
    public string flagIconOutputText{get;set;}
    
    //This will store the path for the logo
    public String logoUrl {get;set;}
    
    //This flag is used to render the image
    public boolean flagIconRender{get;set;}
    
    //If this true then Template panel will be visible
    public boolean templateFlag{get;set;}
    
    //This list will store the templates title available for Special Instruction creation
    public List<SelectOption> templateTitles{get;set;} 
    
    //This map will store the name and ID pair of Logos which are stored in documents
    public Map<String,String> specialInstructionLogoNameMap{get;set;}
    
    //Special Instruction Object to access UI Elements
    public Special_Instructions__c specialInstructionsObject{get;set;}
    
    //This map will stores title object pair because our get method is based on title of the template
    public Map<String, Special_Instruction_Template__C> SITemplateMap;
    
    //Constructor
    public SC_SpecialInstructionTemplateCtrl(ApexPages.StandardController stdController){
        //Getting the Account ID and Special Instructions ID 
        accountId = ApexPages.currentPage().getParameters().get('accountId');
        specialInstructionId = ApexPages.currentPage().getParameters().get('Id');
        specialInstructionsObject = new Special_Instructions__c();
        specialInstructionsObject.Account__c = accountId;
        
        //templatesList = [select Id, title__c,Instructions__c ,Show_for_Record_Types__c, Flag_Icon__c  from Special_Instruction_Template__C];
        SITemplateMap = new Map<string, Special_Instruction_Template__C>();
        
        //URl to documents folder
        logoUrl =  URL.getSalesforceBaseUrl().getHost()+'/servlet/servlet.FileDownload?file=';
        specialInstructionLogoNameMap = new map<string,string>();
        flagIconOutputText ='';
        //Initially no template is selected hence image should not be rendered
        flagIconRender = false;
        
        templateTitles = new List<SelectOption>();
        templateTitles.add(new SelectOption('---None---','---None---'));
        //Adding the template titles to the list which is populated as picklist values
        for(Special_Instruction_Template__C template : [select Id, title__c,Instructions__c ,Show_for_Record_Types__c, Flag_Icon__c  from Special_Instruction_Template__C]) {
                templateTitles.add(new SelectOption(template.title__c,template.title__c));
                SITemplateMap.put(template.title__c, template);
                if(template.Flag_Icon__c != Null){
                    //Load all the Flag icon name where ids are required.
                    specialInstructionLogoNameMap.put(template.Flag_Icon__c.trim(),Null);
                }
        }
        for(document forEachDoc : [select id,Name,DeveloperName from document where Name IN :specialInstructionLogoNameMap.keyset()]){
            //Map of SpecialInstrcution Id and Document Image Id
            if(specialInstructionLogoNameMap.containsKey(forEachDoc.Name.trim())) {
                specialInstructionLogoNameMap.put(forEachDoc.Name.trim(),forEachDoc.Id);
            }
        } 
        //This condition will be true when users clicks on edit button
        if(specialInstructionId!=null){
            specialInstructionsObject = [select id,Title_Formula__c,Title__c,Show_for_Record_Types__c,Instructions__c,Start_Date__c,Expiration_Date__c,Account__c,Special_Instruction_Template__c  from Special_Instructions__c where id= :specialInstructionId limit 1];
            //Edit page will be displayed based on the type of special instruction
            if(specialInstructionsObject.Special_Instruction_Template__c!= null){
                templateFlag = true;
                templateTitle = specialInstructionsObject.Title_Formula__c;
                //This function will called from UI only when user change the picklist values 
                //here we are calling this function to load the preview section
                loadPreview();
            }
         }
        //Following conditions is for Special Instruction Creation. 
        //in the URL if template is true then special instruction is of type template.
        else if(ApexPages.currentPage().getParameters().get('template')=='true'){
            templateFlag = true;
        } 
        else{
            templateFlag =false ;
         }
    }
    
    /* This fuction has 2 use cases
     * 1. create the special instruction from Template(copy the template id to lookup field)
     * 2. Create the special Instruction without template
     */
    public pagereference createSpecialInstruction(){
        Boolean isTemplate = apexpages.currentpage().getParameters().get('isTemplate').equals('true');
        if(isValidSpecialInstruction(isTemplate)){
            if(isTemplate){
                specialInstructionsObject.Special_Instruction_Template__c = SITemplateMap.get(templateTitle).Id;
             }
            try{
                upsert specialInstructionsObject;
                //returning to the detail page of newly created or updated Special Instruction
                pagereference pr = new pagereference('/' + specialInstructionsObject.id);
                return pr;
            }
            catch(exception e){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
                    ApexPages.addMessage(myMsg);
                    return null;
            }
         }
        else
            return null;
    }
    
    // This function is to validate the data before creating the special instruction from template
    Public boolean isValidSpecialInstruction(boolean isTemplate){
        if(isTemplate && specialInstructionsObject.Start_Date__c == null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Start Date: You must enter a value');
            ApexPages.addMessage(myMsg);
            return false;
            }
        if(isTemplate && templateTitle == '---None---'){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Select Template: You must enter a value');
            ApexPages.addMessage(myMsg);
            return false;
            }
        if(specialInstructionsObject.Start_Date__c > specialInstructionsObject.Expiration_Date__c){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Expiration Date should be greater than Start Date');
            ApexPages.addMessage(myMsg);
            return false;
        }
        return true;
    }
    
    // This funcion is to load the preview section. This function will be called whenever new picklist value is selected
    public void loadPreview(){
        if(templateTitle!= '---None---'){
            titleOutputText = SITemplateMap.get(templateTitle).Title__c;
            recordTypesOutputText = SITemplateMap.get(templateTitle).Show_for_Record_Types__c;
            instructionsOutputText = SITemplateMap.get(templateTitle).Instructions__c;
            flagIconOutputText = SITemplateMap.get(templateTitle).Flag_Icon__c;
            //Since flag icon is mandatory we are checking for null values
            if(flagIconOutputText!=null)
                flagIconRender = true;
            else
                flagIconRender = false;
        }
        else{
            titleOutputText = '';
            recordTypesOutputText = '';
            instructionsOutputText= '';
            flagIconOutputText = '';
            flagIconRender = false;
         }
    }
 }