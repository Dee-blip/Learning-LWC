public class IR_CaseCustomButtonsController {

    @AuraEnabled
    public static String handleButtonClick(String pAction, String pCaseId){
        String result = '0:Unknown Error';
        Case cs = [select OwnerId from Case where id= :pCaseId limit 1];
        if(cs.OwnerId != null){
            result = IRCaseHelperClass.btnExecute(pAction, pCaseId, cs.OwnerId);
        }
        return result; 
    }
}