/*******************************************************************************************************
 Name         :   SpecialInstructionsListController
 Author       :   Vinod Kumar (Appirio Offshore)
 Created Date :   June 7,2013
 Task         :   T-149846
 Description  :   controller class for the page SpecialInstructionsList
 
 Last Modified Date : 07-Feb-2014
 Modified By        : Vijetha Vijayendran
 Modified By        : Aditya Sonam on 29-Apr-15 (Added logic for showing special instruction count)
 Modified By        : Aditya Sonam on 01-Jul-16 (CR 3333341 - BOCC: customer runbooks in Sale)
 Modified By        : Vandhana Krishnamurthy on 17-June-17 (ESESP-514 : Modify Special Instructions functionality to change "default visibility on Cases")
*******************************************************************************************************/
public with sharing class SpecialInstructionsListController {
    
    public Integer instCount{get;set;}
    public list<Special_Instructions__c> splInstrList{get{if(splInstrList == null) splInstrList = splInstrShowList; return splInstrList;}set;}    
    public List<Special_Instructions__c> splInstrShowList = new List<Special_Instructions__c>();
    public Map<Id,Case> currentCase;
    public Map<String,String> specialInstructionLogoNameMap{get;set;}
    public String logoUrl {get;set;}
    public Map<Id,Sobject> splInstrIdInstrMap{get;set;}
    public Map<Id,String> instructionsMap{get;set;}
    public boolean caseWithAccount{get;set;}
    public boolean isAMGCase{get;set;}
    
 
       
    //Constructor
    public SpecialInstructionsListController(ApexPages.StandardController controller){
        
        currentCase = new Map<Id,Case>([Select Incident__c, Id, AccountId, OwnerId, Recent_Update__c,RecordType.Name From Case c where id= :ApexPages.currentPage().getParameters().get('id') limit 1]);        
        specialInstructionLogoNameMap = new map<string,string>();
        splInstrIdInstrMap = new Map<Id,Sobject>();
        instructionsMap = new Map<Id,String>();
        caseWithAccount = True;
        instCount = 0;
        if(currentCase != Null && !currentCase.isEmpty() && currentCase.values()[0].AccountId != Null)
            splInstrShowList = GetAllInstruction(currentCase);
        else{
             caseWithAccount = False;
             instCount = 0;
        }
        
    }
    
    //Method to show all the valid special Instruction w/wo image for a record type
    public List<Special_Instructions__c> GetAllInstruction(Map<id,Case> currentCase){
        string AccountId = currentCase.values()[0].AccountId;
        string caseRecType = (currentCase.values()[0].RecordType.Name).trim();
        logoUrl =  URL.getSalesforceBaseUrl().getHost()+'/servlet/servlet.FileDownload?file=';
        isAMGCase = caseRecType =='AMG' ? true : false;
        // changes by Vandhana for ESESP-514
        // modified query based on Record Type to Exclude
        String excludeRecType = SC_SOC_SpecInstr__c.getInstance('Exclude Record Type').Record_Type_Name__c;
        string splInstrQuery;
        splInstrQuery = 'SELECT Id,Title_Formula__c,Title__c,Start_Date__c,Instructions__c,Expiration_Date__c,Name,Show_for_Record_Types__c,Account__c,Special_Instruction_Template__c,Flag_Icon__c,'+
                        ' Special_Instruction_Template__r.Instructions__c FROM Special_Instructions__c' + ' WHERE Account__c = ' +'\''+AccountId+'\'' +
                        ' and Start_Date__c <= Today and (Expiration_Date__c = null or Expiration_Date__c >= Today)'+
                        ' and ((Show_for_Record_Types__c INCLUDES('+'\''+caseRecType+'\''+')'+
                        ' or (Special_Instruction_Template__r.Show_for_Record_Types__c INCLUDES('+'\''+caseRecType+'\''+')))' ;
        if(!excludeRecType.contains(caseRecType))
        {
            splInstrQuery = splInstrQuery + ' or ((Show_for_Record_Types__c INCLUDES ('+'\''+'All except Managed Security'+'\''+')'+
                             ' or (Special_Instruction_Template__r.Show_for_Record_Types__c INCLUDES '+'(\''+ 'All except Managed Security'+'\')'+')) )';
        }
        splInstrQuery = splInstrQuery + ') order by createddate';
        System.debug('Spl Instr Query : ' + splInstrQuery);
        List<Special_Instructions__c> splInstrList = Database.query(splInstrQuery);
        System.debug('Spl Instr List : ' + splInstrList);        
        instCount = splInstrList.size();
        for(Special_Instructions__c forEach : splInstrList){
            
            if(forEach.Flag_Icon__c != Null){
                specialInstructionLogoNameMap.put(forEach.Flag_Icon__c.trim(),Null);                
            }
            
            if(forEach.Special_Instruction_Template__c != Null){

                splInstrIdInstrMap.put(forEach.Special_Instruction_Template__c,forEach);
                instructionsMap.put(forEach.Special_Instruction_Template__c,forEach.Special_Instruction_Template__r.Instructions__c);
            }
            else{
                splInstrIdInstrMap.put(forEach.Id,forEach);
                instructionsMap.put(forEach.Id,forEach.Instructions__c);

            }                
        }
        
        for(document forEachDoc : [select id,Name,DeveloperName from document where Name IN :specialInstructionLogoNameMap.keyset()]){
            
            //Map of SpecialInstrcution Id and Document Image Id
            if(specialInstructionLogoNameMap.containsKey(forEachDoc.Name.trim())) {
                specialInstructionLogoNameMap.put(forEachDoc.Name.trim(),forEachDoc.Id);
            }
        } 
        return splInstrList;
    }
       
    
    public Pagereference setRecentUpdateOnCaseTrue() {
        if(currentCase != null) {
            Case forUpdateCase = new Case();
            try {
                if(currentCase.values()[0].OwnerId == Userinfo.getUserId() && currentCase.values()[0].Recent_Update__c) {
                forUpdateCase.Recent_Update__c = false;
                forUpdateCase.Id = currentCase.values()[0].Id;
                update forUpdateCase;
                }
            } catch(Exception e) {
                //DO NOTHING
            }
        }
        return null;
    }   
}