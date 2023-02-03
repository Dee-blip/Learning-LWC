global class PSA_SETCURRENCY implements Schedulable {
global void execute(SchedulableContext sc) 
{
setAccountCurrency b = new setAccountCurrency(); 
database.executebatch(b);
}

}