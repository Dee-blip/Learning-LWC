public with sharing class FundClaimCustomAllocationController {

    public class BudgetWrapper {
        public SFDC_Budget__c b { get; private set; }
        public Decimal tempAllocation { get; set; }
        
        public BudgetWrapper(SFDC_Budget__c b){
            this.b = b;
        }
        
        public String sAllocation {
            get {
                if (tempAllocation == null) {
                    return '0.00';
                } else {
                    String temp = tempAllocation.toPlainString();
                    Integer indexOf = temp.indexOf('.');
                    if(indexOf != -1) {
                        Integer trailingDigits = temp.length() - (indexOf+1);
                        String temp1 = temp.substring(indexOf+1, (indexOf+trailingDigits +1));
                        if (trailingDigits  > 1) {
                             temp1 =temp.substring(indexOf+1, (indexOf+3)); 
                             temp = temp.substring(0,indexOf+1)+temp1 ;
                        } else {
                             temp1 =temp.substring(indexOf+1, (indexOf+2)); 
                             temp = temp.substring(0,indexOf+1)+temp1 +'0' ;
                        }
                    }
                    return temp;
                }
                return (tempAllocation == null) ? '0.00' : tempAllocation.toPlainString();
            }
            set {
                if (value == null || value.length() == 0) {
                    tempAllocation = Decimal.valueOf('0.00');
                } else {
                    tempAllocation = Decimal.valueOf(value);
                }
            }
        }
    }
    
 
}