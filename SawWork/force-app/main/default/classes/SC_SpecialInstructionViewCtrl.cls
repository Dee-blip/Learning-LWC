/* Author   : Vamsee
   Date     : 19th July 2016
   Purpose  : This class is to display the Special Instruction Details [CR : 3470841]
*/
public class SC_SpecialInstructionViewCtrl {
    //String to store the ID of the special instruction
    public string specialInstructionId;
    
    //Special Instruction object to display the fields
    public Special_Instructions__c specialInstructionObject{get;set;}
    
    //Instruction for support team
    public string instructions{get;set;}
    
    //record types to which special instruction is applicable
    public string recordTypes{get;set;}
    

    //Constructor
    public SC_SpecialInstructionViewCtrl(ApexPages.StandardController stdController){
        //Getting the Special instruction Id
        specialInstructionId = ApexPages.currentPage().getParameters().get('Id');
        specialInstructionObject = [select Title_Formula__c ,Show_for_Record_Types__c,Instructions__c,Start_Date__c,Expiration_Date__c,Account__c,Special_Instruction_Template__c,Special_Instruction_Template__r.Instructions__c,Special_Instruction_Template__r.Show_for_Record_Types__c, (select id, createdby.name, createddate, oldvalue, newvalue,field from histories order by createddate desc)  from Special_Instructions__c where id= :specialInstructionId limit 1];
        if(specialInstructionObject.Special_Instruction_Template__c!=null){
            //If the special instruction is of type template 
            instructions = specialInstructionObject.Special_Instruction_Template__r.Instructions__c;
            recordTypes = specialInstructionObject.Special_Instruction_Template__r.Show_for_Record_Types__c;
        }else{
            //if the special instruction is not of template type then special instruction itself contains instructions and show for record type field
            instructions = specialInstructionObject.Instructions__c;
            recordTypes = specialInstructionObject.Show_for_Record_Types__c;
        }
        
    }

}